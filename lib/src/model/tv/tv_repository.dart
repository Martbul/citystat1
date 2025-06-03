import 'package:deep_pick/deep_pick.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:http/http.dart' as http;
import 'package:citystat1/src/model/common/chess.dart';
import 'package:citystat1/src/model/common/id.dart';
import 'package:citystat1/src/model/tv/tv_channel.dart';
import 'package:citystat1/src/model/tv/tv_game.dart';
import 'package:citystat1/src/model/user/user.dart';
import 'package:citystat1/src/network/http.dart';

typedef TvChannels = IMap<TvChannel, TvGame>;

class TvRepository {
  const TvRepository(this.client);

  final http.Client client;

  Future<TvChannels> channels() {
    return client.readJson(Uri(path: '/api/tv/channels'), mapper: _tvGamesFromJson);
  }
}

TvChannels _tvGamesFromJson(Map<String, dynamic> json) {
  final map = pick(json).asMapOrEmpty<String, Map<String, dynamic>>();
  return IMap({
    for (final entry in map.entries)
      if (TvChannel.nameMap.containsKey(entry.key))
        TvChannel.nameMap[entry.key]!: _tvGameFromJson(entry.value),
  });
}

TvGame _tvGameFromJson(Map<String, dynamic> json) => _tvGameFromPick(pick(json).required());

TvGame _tvGameFromPick(RequiredPick pick) => TvGame(
  user: pick('user').asLightUserOrThrow(),
  rating: pick('rating').asIntOrNull(),
  id: pick('gameId').asGameIdOrThrow(),
  side: pick('color').asSideOrNull(),
);
