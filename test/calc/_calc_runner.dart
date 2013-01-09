library vote_test_calc;

import 'package:bot/bot.dart';
import 'package:unittest/unittest.dart';
import 'package:vote/calc.dart';
import 'package:vote/map.dart';
import 'package:vote/vote.dart';

part 'test_calc_engine.dart';

void runCalcTests() {
  group('calc', () {
    TestCalcEngine.run();
  });
}
