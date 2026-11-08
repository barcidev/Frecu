import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

void main() {
  group('FrExpandOrigin', () {
    tearDown(FrExpandOrigin.take);

    test('entrega una sola vez el rectángulo anotado', () {
      const rect = Rect.fromLTWH(8, 400, 374, 436);
      FrExpandOrigin.record(rect);

      expect(FrExpandOrigin.take(), rect);
      expect(FrExpandOrigin.take(), isNull);
    });

    test('ignora rectángulos vacíos o no finitos', () {
      FrExpandOrigin.record(Rect.zero);
      expect(FrExpandOrigin.take(), isNull);

      FrExpandOrigin.record(const Rect.fromLTWH(0, 0, double.infinity, 10));
      expect(FrExpandOrigin.take(), isNull);
    });

    testWidgets('anota la caja global de un widget ya dispuesto', (
      tester,
    ) async {
      late BuildContext box;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 300,
                width: 200,
                height: 120,
                child: Builder(
                  builder: (context) {
                    box = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      FrExpandOrigin.recordFrom(box);

      expect(FrExpandOrigin.take(), const Rect.fromLTWH(10, 300, 200, 120));
    });
  });
}
