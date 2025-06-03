import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citystat1/src/constants.dart';
import 'package:citystat1/src/model/broadcast/broadcast_providers.dart';
import 'package:citystat1/src/styles/styles.dart';
import 'package:citystat1/src/utils/l10n_context.dart';
import 'package:citystat1/src/utils/navigation.dart';
import 'package:citystat1/src/view/broadcast/broadcast_list_tile.dart';
import 'package:citystat1/src/widgets/list.dart';
import 'package:citystat1/src/widgets/platform_search_bar.dart';
import 'package:citystat1/src/widgets/shimmer.dart';

class BroadcastSearchScreen extends StatefulWidget {
  const BroadcastSearchScreen();

  static Route<dynamic> buildRoute(BuildContext context) {
    return buildScreenRoute(context, screen: const BroadcastSearchScreen(), fullscreenDialog: true);
  }

  @override
  State<BroadcastSearchScreen> createState() => _BroadcastSearchScreenState();
}

class _BroadcastSearchScreenState extends State<BroadcastSearchScreen> {
  String? searchTerm;

  void onSubmitted(String term) {
    setState(() {
      searchTerm = term.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = PlatformSearchBar(
      hintText: context.l10n.searchSearch,
      autoFocus: true,
      onSubmitted: onSubmitted,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, // Custom height to fit the search bar
        title: searchBar,
      ),
      body: (searchTerm != null)
          ? (searchTerm!.isNotEmpty)
                ? _Body(searchTerm!)
                : const Center(
                    child: Text(
                      'Search is empty', // TODO: translate
                      style: Styles.noResultTextStyle,
                    ),
                  )
          : kEmptyWidget,
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body(this.searchTerm);

  final String searchTerm;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final provider = broadcastsSearchPaginatorProvider(widget.searchTerm);
      final broadcastList = ref.read(provider);

      if (!broadcastList.isLoading) {
        ref.read(provider.notifier).next();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastList = ref.watch(broadcastsSearchPaginatorProvider(widget.searchTerm));

    return SafeArea(
      child: broadcastList.when(
        skipLoadingOnReload: true,
        data: (value) {
          final broadcasts = value.broadcasts;

          return (broadcasts.isNotEmpty)
              ? ListView.separated(
                  controller: _scrollController,
                  separatorBuilder: (context, index) => PlatformDivider(
                    height: 1,
                    indent: BroadcastListTile.thumbnailSize(context) + 16.0 + 10.0,
                  ),
                  itemCount: broadcasts.length,
                  itemBuilder: (context, index) =>
                      (broadcastList.isLoading && index >= broadcasts.length - 1)
                      ? const Shimmer(
                          child: ShimmerLoading(
                            isLoading: true,
                            child: BroadcastListTile.loading(),
                          ),
                        )
                      : BroadcastListTile(broadcast: broadcasts[index]),
                )
              : Center(
                  child: Text(context.l10n.mobileNoSearchResults, style: Styles.noResultTextStyle),
                );
        },
        error: (_, _) => const Center(child: Text('Could not load round data')),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}
