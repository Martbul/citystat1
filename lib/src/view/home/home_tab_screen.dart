import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citystat1/src/model/account/account_repository.dart';
import 'package:citystat1/src/model/account/home_preferences.dart';
import 'package:citystat1/src/model/account/home_widgets.dart';
import 'package:citystat1/src/model/account/ongoing_game.dart';
import 'package:citystat1/src/model/auth/auth_controller.dart';
import 'package:citystat1/src/model/auth/auth_session.dart';
import 'package:citystat1/src/model/challenge/challenges.dart';
import 'package:citystat1/src/model/correspondence/correspondence_game_storage.dart';
import 'package:citystat1/src/model/correspondence/offline_correspondence_game.dart';
import 'package:citystat1/src/model/game/exported_game.dart';
import 'package:citystat1/src/model/game/game_history.dart';
import 'package:citystat1/src/model/tournament/tournament.dart';
import 'package:citystat1/src/model/tournament/tournament_providers.dart';
import 'package:citystat1/src/network/connectivity.dart';
import 'package:citystat1/src/styles/lichess_icons.dart';
import 'package:citystat1/src/styles/styles.dart';
import 'package:citystat1/src/tab_scaffold.dart';
import 'package:citystat1/src/utils/focus_detector.dart';
import 'package:citystat1/src/utils/l10n.dart';
import 'package:citystat1/src/utils/l10n_context.dart';
import 'package:citystat1/src/utils/navigation.dart';
import 'package:citystat1/src/utils/screen.dart';
import 'package:citystat1/src/view/account/account_screen.dart';
import 'package:citystat1/src/view/account/profile_screen.dart';
import 'package:citystat1/src/view/correspondence/offline_correspondence_game_screen.dart';
import 'package:citystat1/src/view/game/game_screen.dart';
import 'package:citystat1/src/view/game/offline_correspondence_games_screen.dart';
import 'package:citystat1/src/view/home/games_carousel.dart';
import 'package:citystat1/src/view/play/ongoing_games_screen.dart';
import 'package:citystat1/src/view/play/play_bottom_sheet.dart';
import 'package:citystat1/src/view/play/play_menu.dart';
import 'package:citystat1/src/view/play/quick_game_matrix.dart';
import 'package:citystat1/src/view/tournament/tournament_list_screen.dart';
import 'package:citystat1/src/view/user/challenge_requests_screen.dart';
import 'package:citystat1/src/view/user/player_screen.dart';
import 'package:citystat1/src/view/user/recent_games.dart';
import 'package:citystat1/src/widgets/buttons.dart';
import 'package:citystat1/src/widgets/feedback.dart';
import 'package:citystat1/src/widgets/list.dart';
import 'package:citystat1/src/widgets/misc.dart';
import 'package:citystat1/src/widgets/platform.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key, this.editModeEnabled = false});

  final bool editModeEnabled;

  static Route<dynamic> buildRoute(BuildContext context, {bool editModeEnabled = false}) {
    return buildScreenRoute(context, screen: HomeTabScreen(editModeEnabled: editModeEnabled));
  }

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeScreenState();
}

class _IsEditingHome extends InheritedWidget {
  const _IsEditingHome({required super.child, required this.isEditingWidgets});

  final bool isEditingWidgets;

  @override
  bool updateShouldNotify(_IsEditingHome oldWidget) {
    return isEditingWidgets != oldWidget.isEditingWidgets;
  }

  static _IsEditingHome? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_IsEditingHome>();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isEditingWidgets', isEditingWidgets));
  }
}

class _HomeScreenState extends ConsumerState<HomeTabScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime? _focusLostAt;

  bool wasOnline = true;
  bool hasRefreshed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityChangesProvider, (_, connectivity) {
      // Refresh the data only once if it was offline and is now online
      if (!connectivity.isRefreshing && connectivity.hasValue) {
        final isNowOnline = connectivity.value!.isOnline;

        if (!hasRefreshed && !wasOnline && isNowOnline) {
          hasRefreshed = true;
          _refreshData(isOnline: isNowOnline);
        }

        wasOnline = isNowOnline;
      }
    });

    final connectivity = ref.watch(connectivityChangesProvider);

    return connectivity.when(
      skipLoadingOnReload: true,
      data: (status) {
        final session = ref.watch(authSessionProvider);
        final ongoingGames = ref.watch(ongoingGamesProvider);
        final offlineCorresGames = ref.watch(offlineOngoingCorrespondenceGamesProvider);
        final recentGames = ref.watch(myRecentGamesProvider);
        final nbOfGames = ref.watch(userNumberOfGamesProvider(null)).valueOrNull ?? 0;
        final isTablet = isTabletOrLarger(context);
        final featuredTournaments = status.isOnline
            ? ref.watch(featuredTournamentsProvider)
            : const AsyncValue.data(IListConst<LightTournament>([]));

        // Show the welcome screen if not logged in and there are no recent games and no stored games
        // (i.e. first installation, or the user has never played a game)
        final shouldShowWelcomeScreen =
            session == null &&
            recentGames.maybeWhen(data: (data) => data.isEmpty, orElse: () => false);

        final widgets = shouldShowWelcomeScreen
            ? _welcomeScreenWidgets(
                session: session,
                status: status,
                featuredTournaments: featuredTournaments,
                isTablet: isTablet,
              )
            : isTablet
            ? _tabletWidgets(
                session: session,
                status: status,
                ongoingGames: ongoingGames,
                offlineCorresGames: offlineCorresGames,
                recentGames: recentGames,
                featuredTournaments: featuredTournaments,
                nbOfGames: nbOfGames,
              )
            : _handsetWidgets(
                session: session,
                status: status,
                ongoingGames: ongoingGames,
                offlineCorresGames: offlineCorresGames,
                recentGames: recentGames,
                featuredTournaments: featuredTournaments,
                nbOfGames: nbOfGames,
              );

        final content = ListView(controller: homeScrollController, children: widgets);

        return FocusDetector(
          onFocusLost: () {
            _focusLostAt = DateTime.now();
          },
          onFocusRegained: () {
            if (context.mounted && _focusLostAt != null) {
              final duration = DateTime.now().difference(_focusLostAt!);
              if (duration.inSeconds < 60) {
                return;
              }
              _refreshData(isOnline: status.isOnline);
            }
          },
          child: _IsEditingHome(
            isEditingWidgets: widget.editModeEnabled,
            child: PlatformScaffold(
              appBar: widget.editModeEnabled
                  ? PlatformAppBar(title: const Text('Home widgets'))
                  : PlatformAppBar(
                      title: const Text('Lichess.org'),
                      leading: const AccountIconButton(),
                      actions: const [_ChallengeScreenButton(), _PlayerScreenButton()],
                    ),
              body: widget.editModeEnabled
                  ? content
                  : RefreshIndicator.adaptive(
                      edgeOffset: Theme.of(context).platform == TargetPlatform.iOS
                          ? MediaQuery.paddingOf(context).top + kToolbarHeight
                          : 0.0,
                      key: _refreshKey,
                      onRefresh: () => _refreshData(isOnline: status.isOnline),
                      child: content,
                    ),
              bottomNavigationBar: widget.editModeEnabled
                  ? BottomAppBar(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    )
                  : null,
              floatingActionButton: widget.editModeEnabled || isTablet
                  ? null
                  : const FloatingPlayButton(),
              bottomSheet: widget.editModeEnabled ? null : const OfflineBanner(),
            ),
          ),
        );
      },
      error: (_, _) => const CenterLoadingIndicator(),
      loading: () => const CenterLoadingIndicator(),
    );
  }

  List<Widget> _handsetWidgets({
    required AuthSessionState? session,
    required ConnectivityStatus status,
    required AsyncValue<IList<OngoingGame>> ongoingGames,
    required AsyncValue<IList<(DateTime, OfflineCorrespondenceGame)>> offlineCorresGames,
    required AsyncValue<IList<LightExportedGameWithPov>> recentGames,
    required AsyncValue<IList<LightTournament>> featuredTournaments,
    required int nbOfGames,
  }) {
    final hasOngoingGames =
        (status.isOnline &&
            ongoingGames.maybeWhen(data: (data) => data.isNotEmpty, orElse: () => false)) ||
        (!status.isOnline &&
            offlineCorresGames.maybeWhen(data: (data) => data.isNotEmpty, orElse: () => false));
    final list = [
      const _EditableWidget(
        widget: HomeEditableWidget.hello,
        shouldShow: true,
        child: _HelloWidget(),
      ),
      _EditableWidget(
        widget: HomeEditableWidget.perfCards,
        shouldShow: session != null && status.isOnline,
        child: AccountPerfCards(
          padding: Styles.horizontalBodyPadding.add(Styles.sectionBottomPadding),
        ),
      ),
      _EditableWidget(
        widget: HomeEditableWidget.quickPairing,
        shouldShow: status.isOnline,
        child: const Padding(padding: Styles.bodySectionPadding, child: QuickGameMatrix()),
      ),
      _EditableWidget(
        widget: HomeEditableWidget.ongoingGames,
        shouldShow: hasOngoingGames,
        child: status.isOnline
            ? _OngoingGamesCarousel(ongoingGames, maxGamesToShow: 20)
            : _OfflineCorrespondenceCarousel(offlineCorresGames, maxGamesToShow: 20),
      ),
      _EditableWidget(
        widget: HomeEditableWidget.featuredTournaments,
        shouldShow: status.isOnline,
        child: FeaturedTournamentsWidget(featured: featuredTournaments),
      ),
      _EditableWidget(
        widget: HomeEditableWidget.recentGames,
        shouldShow: true,
        child: RecentGamesWidget(recentGames: recentGames, nbOfGames: nbOfGames, user: null),
      ),
    ];
    return list;
  }

  List<Widget> _welcomeScreenWidgets({
    required AuthSessionState? session,
    required ConnectivityStatus status,
    required AsyncValue<IList<LightTournament>> featuredTournaments,
    required bool isTablet,
  }) {
    final welcomeWidgets = [
      const _HelloWidget(),
      Padding(
        padding: Styles.bodySectionPadding,
        child: LichessMessage(style: TextTheme.of(context).bodyLarge),
      ),
      const SizedBox(height: 8.0),
      if (session == null) ...[const Center(child: _SignInWidget()), const SizedBox(height: 16.0)],
      if (Theme.of(context).platform != TargetPlatform.iOS &&
          (session == null || session.user.isPatron != true)) ...[
        Center(
          child: FilledButton.tonal(
            onPressed: () {
              launchUrl(Uri.parse('https://Lichess.org/patron'));
            },
            child: Text(context.l10n.patronDonate),
          ),
        ),
        const SizedBox(height: 16.0),
      ],
      Center(
        child: FilledButton.tonal(
          onPressed: () {
            launchUrl(Uri.parse('https://Lichess.org/about'));
          },
          child: Text(context.l10n.aboutX('Lichess...')),
        ),
      ),
    ];

    return [
      if (isTablet)
        Row(
          children: [
            const Expanded(child: _TabletCreateAGameSection()),
            Expanded(
              child: Column(
                children: [
                  ...welcomeWidgets,
                  FeaturedTournamentsWidget(featured: featuredTournaments),
                ],
              ),
            ),
          ],
        )
      else ...[
        ...welcomeWidgets,
        if (status.isOnline)
          const _EditableWidget(
            widget: HomeEditableWidget.quickPairing,
            shouldShow: true,
            child: Padding(padding: Styles.bodySectionPadding, child: QuickGameMatrix()),
          ),
        if (status.isOnline)
          _EditableWidget(
            widget: HomeEditableWidget.featuredTournaments,
            shouldShow: true,
            child: FeaturedTournamentsWidget(featured: featuredTournaments),
          ),
      ],
    ];
  }

  List<Widget> _tabletWidgets({
    required AuthSessionState? session,
    required ConnectivityStatus status,
    required AsyncValue<IList<OngoingGame>> ongoingGames,
    required AsyncValue<IList<(DateTime, OfflineCorrespondenceGame)>> offlineCorresGames,
    required AsyncValue<IList<LightExportedGameWithPov>> recentGames,
    required AsyncValue<IList<LightTournament>> featuredTournaments,
    required int nbOfGames,
  }) {
    return [
      const _EditableWidget(
        widget: HomeEditableWidget.hello,
        shouldShow: true,
        child: _HelloWidget(),
      ),
      if (status.isOnline)
        _EditableWidget(
          widget: HomeEditableWidget.perfCards,
          shouldShow: session != null,
          child: const AccountPerfCards(padding: Styles.bodySectionPadding),
        ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              children: [
                const SizedBox(height: 8.0),
                const _TabletCreateAGameSection(),
                if (status.isOnline)
                  _OngoingGamesPreview(ongoingGames, maxGamesToShow: 5)
                else
                  _OfflineCorrespondencePreview(offlineCorresGames, maxGamesToShow: 5),
              ],
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 8.0),
                FeaturedTournamentsWidget(featured: featuredTournaments),
                RecentGamesWidget(recentGames: recentGames, nbOfGames: nbOfGames, user: null),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _refreshData({required bool isOnline}) {
    return Future.wait([
      ref.refresh(myRecentGamesProvider.future),
      if (isOnline) ref.refresh(accountProvider.future),
      if (isOnline) ref.refresh(ongoingGamesProvider.future),
      if (isOnline) ref.refresh(featuredTournamentsProvider.future),
    ]);
  }
}

class _SignInWidget extends ConsumerWidget {
  const _SignInWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);

    return FilledButton(
      onPressed: authController.isLoading
          ? null
          : () => ref.read(authControllerProvider.notifier).signIn(),
      child: Text(context.l10n.signIn),
    );
  }
}

/// A widget that can be enabled or disabled by the user.
///
/// This widget is used to show or hide certain sections of the home screen.
///
/// The [homePreferencesProvider] provides a list of enabled widgets.
///
/// * The [widget] parameter is the widget that can be enabled or disabled.
///
/// * The [shouldShow] parameter is useful when the widget should be shown only
///   when certain conditions are met. For example, we only want to show the quick
///   pairing matrix when the user is online.
///   This parameter is only active when the user is not in edit mode, as we
///   always want to display the widget in edit mode.
class _EditableWidget extends ConsumerWidget {
  const _EditableWidget({required this.child, required this.widget, required this.shouldShow});

  final Widget child;
  final HomeEditableWidget widget;
  final bool shouldShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabledWidgets = ref.watch(homePreferencesProvider).disabledWidgets;
    final isEditing = _IsEditingHome.maybeOf(context)?.isEditingWidgets ?? false;
    final isEnabled = !disabledWidgets.contains(widget);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return isEditing
        ? Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox.adaptive(
                      value: isEnabled,
                      onChanged: widget.alwaysEnabled
                          ? null
                          : (_) {
                              ref.read(homePreferencesProvider.notifier).toggleWidget(widget);
                            },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IgnorePointer(ignoring: isEditing, child: child),
              ),
            ],
          )
        : widget.alwaysEnabled || isEnabled
        ? child
        : const SizedBox.shrink();
  }
}

class _HelloWidget extends ConsumerWidget {
  const _HelloWidget();

  /// Returns the string representing the current time of day
  /// Used in the greeting widget to provide visual time indicator
  String getTimeOfDayIcon() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18 ? '☀️' : '🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final style = TextTheme.of(context).bodyLarge;

    const iconSize = 24.0;

    final user = session?.user;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: Styles.bodyPadding,
        child: GestureDetector(
          onTap: () {
            ref.invalidate(accountProvider);
            Navigator.of(context).push(ProfileScreen.buildRoute(context));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getTimeOfDayIcon(), style: const TextStyle(fontSize: iconSize, height: 1.0)),
              const SizedBox(width: 5.0),
              if (user != null)
                Flexible(
                  child: l10nWithWidget(
                    context.l10n.mobileGreeting,
                    Text(user.name, style: style),
                    textStyle: style,
                  ),
                )
              else
                Flexible(child: Text(context.l10n.mobileGreetingWithoutName, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletCreateAGameSection extends StatelessWidget {
  const _TabletCreateAGameSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _EditableWidget(
          widget: HomeEditableWidget.quickPairing,
          shouldShow: true,
          child: Padding(padding: Styles.bodySectionPadding, child: QuickGameMatrix()),
        ),
        PlayMenu(),
      ],
    );
  }
}

class _OngoingGamesCarousel extends ConsumerWidget {
  const _OngoingGamesCarousel(this.games, {required this.maxGamesToShow});

  final AsyncValue<IList<OngoingGame>> games;

  final int maxGamesToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (games) {
      case AsyncData(:final value):
        if (value.isEmpty) {
          return const SizedBox.shrink();
        }
        final realTime = value.where((game) => game.isRealTime);
        final correspondence = value.where((game) => !game.isRealTime);
        final list = [...realTime, ...correspondence].lock;
        return GamesCarousel<OngoingGame>(
          list: list,
          onTap: (index) {
            final game = list[index];
            Navigator.of(context, rootNavigator: true).push(
              GameScreen.buildRoute(
                context,
                initialGameId: game.fullId,
                loadingFen: game.fen,
                loadingOrientation: game.orientation,
                loadingLastMove: game.lastMove,
              ),
            );
          },
          builder: (game) => OngoingGameCarouselItem(game: game),
          moreScreenRouteBuilder: OngoingGamesScreen.buildRoute,
          maxGamesToShow: maxGamesToShow,
        );
      case _:
        return const SizedBox.shrink();
    }
  }
}

class _OfflineCorrespondenceCarousel extends ConsumerWidget {
  const _OfflineCorrespondenceCarousel(this.offlineCorresGames, {required this.maxGamesToShow});

  final int maxGamesToShow;

  final AsyncValue<IList<(DateTime, OfflineCorrespondenceGame)>> offlineCorresGames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return offlineCorresGames.maybeWhen(
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }
        return GamesCarousel(
          list: data,
          onTap: (index) {
            final el = data[index];
            Navigator.of(context, rootNavigator: true).push(
              OfflineCorrespondenceGameScreen.buildRoute(context, initialGame: (el.$1, el.$2)),
            );
          },
          builder: (el) => OngoingGameCarouselItem(
            game: OngoingGame(
              id: el.$2.id,
              fullId: el.$2.fullId,
              orientation: el.$2.orientation,
              fen: el.$2.lastPosition.fen,
              perf: el.$2.perf,
              speed: el.$2.speed,
              variant: el.$2.variant,
              opponent: el.$2.opponent!.user,
              isMyTurn: el.$2.isMyTurn,
              opponentRating: el.$2.opponent!.rating,
              opponentAiLevel: el.$2.opponent!.aiLevel,
              lastMove: el.$2.lastMove,
              secondsLeft: el.$2.myTimeLeft(el.$1)?.inSeconds,
            ),
          ),
          moreScreenRouteBuilder: OfflineCorrespondenceGamesScreen.buildRoute,
          maxGamesToShow: maxGamesToShow,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _OngoingGamesPreview extends ConsumerWidget {
  const _OngoingGamesPreview(this.games, {required this.maxGamesToShow});

  final AsyncValue<IList<OngoingGame>> games;
  final int maxGamesToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (games) {
      case AsyncData(:final value):
        if (value.isEmpty) {
          return const SizedBox.shrink();
        }
        final realTime = value.where((game) => game.isRealTime);
        final correspondence = value.where((game) => !game.isRealTime);
        final list = [...realTime, ...correspondence].lock;

        return PreviewGameList(
          list: list,
          maxGamesToShow: maxGamesToShow,
          builder: (el) =>
              OngoingGamePreview(game: el, padding: const EdgeInsets.symmetric(vertical: 8.0)),
          moreScreenRouteBuilder: OngoingGamesScreen.buildRoute,
        );
      case _:
        return const SizedBox.shrink();
    }
  }
}

class _OfflineCorrespondencePreview extends ConsumerWidget {
  const _OfflineCorrespondencePreview(this.offlineCorresGames, {required this.maxGamesToShow});

  final int maxGamesToShow;

  final AsyncValue<IList<(DateTime, OfflineCorrespondenceGame)>> offlineCorresGames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return offlineCorresGames.maybeWhen(
      data: (data) {
        return PreviewGameList(
          list: data,
          maxGamesToShow: maxGamesToShow,
          builder: (el) => OfflineCorrespondenceGamePreview(game: el.$2, lastModified: el.$1),
          moreScreenRouteBuilder: OfflineCorrespondenceGamesScreen.buildRoute,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class PreviewGameList<T> extends StatelessWidget {
  const PreviewGameList({
    required this.list,
    required this.builder,
    required this.moreScreenRouteBuilder,
    required this.maxGamesToShow,
  });
  final IList<T> list;
  final Widget Function(T data) builder;
  final Route<dynamic> Function(BuildContext) moreScreenRouteBuilder;
  final int maxGamesToShow;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: Styles.horizontalBodyPadding.add(Styles.sectionTopPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListSectionHeader(
            title: Text(context.l10n.nbGamesInPlay(list.length)),
            onTap: list.length > maxGamesToShow
                ? () {
                    Navigator.of(context).push(moreScreenRouteBuilder(context));
                  }
                : null,
          ),
          for (final data in list.take(maxGamesToShow)) builder(data),
        ],
      ),
    );
  }
}

class _PlayerScreenButton extends ConsumerWidget {
  const _PlayerScreenButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityChangesProvider);

    return connectivity.maybeWhen(
      data: (connectivity) => SemanticIconButton(
        icon: const Icon(Icons.group_outlined),
        semanticsLabel: context.l10n.players,
        onPressed: !connectivity.isOnline
            ? null
            : () {
                Navigator.of(context).push(PlayerScreen.buildRoute(context));
              },
      ),
      orElse: () => SemanticIconButton(
        icon: const Icon(Icons.group_outlined),
        semanticsLabel: context.l10n.players,
        onPressed: null,
      ),
    );
  }
}

class _ChallengeScreenButton extends ConsumerWidget {
  const _ChallengeScreenButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final connectivity = ref.watch(connectivityChangesProvider);
    final challenges = ref.watch(challengesProvider);

    final inwardCount = challenges.valueOrNull?.inward.length ?? 0;
    final outwardCount = challenges.valueOrNull?.outward.length ?? 0;

    if (inwardCount == 0 && outwardCount == 0) {
      return const SizedBox.shrink();
    }

    return switch (connectivity) {
      AsyncData(:final value) => SemanticIconButton(
        icon: Badge.count(
          count: inwardCount,
          isLabelVisible: inwardCount > 0,
          child: const Icon(LichessIcons.crossed_swords, size: 18.0),
        ),
        semanticsLabel: context.l10n.preferencesNotifyChallenge,
        onPressed: !value.isOnline
            ? null
            : () {
                ref.invalidate(challengesProvider);
                Navigator.of(context).push(ChallengeRequestsScreen.buildRoute(context));
              },
      ),
      _ => SemanticIconButton(
        icon: const Icon(LichessIcons.crossed_swords, size: 18.0),
        semanticsLabel: context.l10n.preferencesNotifyChallenge,
        onPressed: null,
      ),
    };
  }
}
