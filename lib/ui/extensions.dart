import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

extension WidgetListExtensions on List<Widget> {
  List<Widget> spaced(double space, Axis direction) {
    return expandIndexed(
      (i, e) => [
        if (i != 0)
          SizedBox(
            width: direction == Axis.horizontal ? space : null,
            height: direction == Axis.vertical ? space : null,
          ),
        e,
      ],
    ).toList();
  }
}
