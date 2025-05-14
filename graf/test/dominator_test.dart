// ignore_for_file: lines_longer_than_80_chars

import 'package:graf/graf.dart';
import 'package:test/test.dart';

void main() {
  group('DominatorFinder', () {
    test(
      'computes dominators and immediate dominators correctly for a simple CFG',
      () {
        const entryNode = 'Entry';

        final cfg = GraphData(<String, Set<String>>{
          entryNode: {'A'},
          'A': {'B', 'C'},
          'B': {'D'},
          'C': {'D'},
          'D': {'Exit'},
          'Exit': {},
        });

        // 2. Act: Compute dominators
        final dominatorFinder = DominatorFinder.compute(cfg, entryNode);

        // 3. Assert: Verify dominator sets
        expect(dominatorFinder.getDominators('Entry'), {
          'Entry',
        }, reason: 'Dominators of Entry');
        expect(dominatorFinder.getDominators('A'), {
          'Entry',
          'A',
        }, reason: 'Dominators of A');
        expect(dominatorFinder.getDominators('B'), {
          'Entry',
          'A',
          'B',
        }, reason: 'Dominators of B');
        expect(dominatorFinder.getDominators('C'), {
          'Entry',
          'A',
          'C',
        }, reason: 'Dominators of C');
        expect(
          dominatorFinder.getDominators('D'),
          // D is dominated by Entry and A because all paths to D go through them.
          // It's also dominated by itself.
          {'Entry', 'A', 'D'},
          reason: 'Dominators of D',
        );
        expect(
          dominatorFinder.getDominators('Exit'),
          // Exit is dominated by Entry, A, D because all paths go through them.
          // It's also dominated by itself.
          {'Entry', 'A', 'D', 'Exit'},
          reason: 'Dominators of Exit',
        );

        // 4. Assert: Verify immediate dominators
        expect(
          dominatorFinder.getImmediateDominator('Entry'),
          isNull,
          reason: 'IDom of Entry',
        );
        expect(
          dominatorFinder.getImmediateDominator('A'),
          'Entry',
          reason: 'IDom of A',
        );
        expect(
          dominatorFinder.getImmediateDominator('B'),
          'A',
          reason: 'IDom of B',
        );
        expect(
          dominatorFinder.getImmediateDominator('C'),
          'A',
          reason: 'IDom of C',
        );
        expect(
          dominatorFinder.getImmediateDominator('D'),
          'A', // A immediately dominates D because B and C are siblings under A
          reason: 'IDom of D',
        );
        expect(
          dominatorFinder.getImmediateDominator('Exit'),
          'D',
          reason: 'IDom of Exit',
        );
      },
    );

    // Add more test cases here for different graph structures (cycles, multiple entries - though typically one entry, unreachable nodes etc.)
  });
}
