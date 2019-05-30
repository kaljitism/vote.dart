import 'package:collection/collection.dart';

import 'irv_elimination.dart';
import 'plurality_election_place.dart';
import 'ranked_ballot.dart';
import 'vote_util.dart';

class IrvRound<TVoter, TCandidate extends Comparable> {
  final List<PluralityElectionPlace<TCandidate>> places;

  final List<IrvElimination<TVoter, TCandidate>> eliminations;

  bool get isFinal => eliminations.isEmpty;

  Iterable<TCandidate> get eliminatedCandidates =>
      eliminations.map((ie) => ie.candidate);

  Iterable<TCandidate> get candidates => places.expand((p) => p);

  IrvRound._internal(this.places, this.eliminations);

  factory IrvRound(
    List<RankedBallot<TVoter, TCandidate>> ballots,
    List<TCandidate> eliminatedCandidates,
  ) {
    final cleanedBallots = ballots.map((b) {
      final pruned = List<TCandidate>.unmodifiable(
          b.rank.toList()..removeWhere(eliminatedCandidates.contains));
      final winner = pruned.isEmpty ? null : pruned[0];
      return _Tuple3<TVoter, TCandidate>(b, pruned, winner);
    });

    final candidateAllocations =
        groupBy<_Tuple3<TVoter, TCandidate>, TCandidate>(
            cleanedBallots.where((t) => t.winner != null),
            (tuple) => tuple.winner);

    final voteGroups = groupBy<TCandidate, int>(candidateAllocations.keys, (c) {
      return candidateAllocations[c].length;
    });

    final placeVotes = voteGroups.keys.toList()
      // reverse sorting -> most votes first
      ..sort((a, b) => b.compareTo(a));

    var placeNumber = 1;
    final places = List<PluralityElectionPlace<TCandidate>>.unmodifiable(
        placeVotes.map((pv) {
      final vg = voteGroups[pv];
      final currentPlaceNumber = placeNumber;
      placeNumber += vg.length;
      return PluralityElectionPlace<TCandidate>(currentPlaceNumber, vg, pv);
    }));

    final newlyEliminatedCandidates =
        _getEliminatedCandidates<TCandidate>(places);

    final eliminations = List<IrvElimination<TVoter, TCandidate>>.unmodifiable(
        newlyEliminatedCandidates.map((TCandidate c) {
      final xfers = <TCandidate, List<RankedBallot<TVoter, TCandidate>>>{};

      final exhausted = <RankedBallot<TVoter, TCandidate>>[];

      for (var b in cleanedBallots.where((t) => t.winner == c)) {
        final rb = b.ballot;
        final pruned = b.remaining.toList()
          ..removeWhere(newlyEliminatedCandidates.contains);
        if (pruned.isEmpty) {
          // we're exhausted
          exhausted.add(rb);
        } else {
          // #2 gets the transfer
          final runnerUp = pruned.first;
          xfers.putIfAbsent(runnerUp, () => []).add(rb);
        }
      }

      return IrvElimination<TVoter, TCandidate>(
          c, xfers, List.unmodifiable(exhausted));
    }));

    return IrvRound<TVoter, TCandidate>._internal(places, eliminations);
  }

  IrvElimination<TVoter, TCandidate> eliminationForCandidate(
          TCandidate candidate) =>
      eliminations.singleWhere((e) => e.candidate == candidate);

  static List<TCandidate>
      _getEliminatedCandidates<TCandidate extends Comparable>(
          List<PluralityElectionPlace<TCandidate>> places) {
    assert(places != null);
    assert(places.isNotEmpty);

    if (places.length == 1) {
      // it's a tie for first
      return [];
    }

    // duh, I know. Being paranoid.
    assert(places.length >= 2);

    final totalVotes = places.map((p) {
      return p.voteCount * p.length;
    }).fold<int>(0, (a, b) => a + b);

    final majorityCount = majorityThreshold(totalVotes);

    //
    // eliminations
    //
    // 2 or more 'places'
    // unless
    // a) first place is single candiadate
    // b) first place votes > (0.5 * total + 1)
    if (places[0].length == 1 && places[0].voteCount >= majorityCount) {
      return [];
    }

    return places.last.map((p) => p).toList();
  }
}

class _Tuple3<TVoter, TCandidate> {
  final RankedBallot<TVoter, TCandidate> ballot;
  final List<TCandidate> remaining;
  final TCandidate winner;

  _Tuple3(this.ballot, this.remaining, this.winner);
}
