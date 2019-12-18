// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' as math;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec, Image;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';


const double _kTencentLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 36.0;
const int _kIndeterminateLinearDuration = 1800;

// TODO(hansmuller): implement the support for buffer indicator

/// A base class for material design progress indicators.
///
/// This widget cannot be instantiated directly. For a linear progress
/// indicator, see [TencentLinearProgressIndicator]. For a circular progress indicator,
/// see [CircularProgressIndicator].
///
/// See also:
///
///  * <https://material.io/design/components/progress-indicators.html>
abstract class ProgressIndicator extends StatefulWidget {
  /// Creates a progress indicator.
  ///
  /// {@template flutter.material.progressIndicator.parameters}
  /// The [value] argument can either be null for an indeterminate
  /// progress indicator, or non-null for a determinate progress
  /// indicator.
  ///
  /// ## Accessibility
  ///
  /// The [semanticsLabel] can be used to identify the purpose of this progress
  /// bar for screen reading software. The [semanticsValue] property may be used
  /// for determinate progress indicators to indicate how much progress has been made.
  /// {@endtemplate}
  const ProgressIndicator({
    Key key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  }) : super(key: key);

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double value;

  /// The progress indicator's background color.
  ///
  /// The current theme's [ThemeData.backgroundColor] by default.
  final Color backgroundColor;

  /// The progress indicator's color as an animated value.
  ///
  /// To specify a constant color use: `AlwaysStoppedAnimation<Color>(color)`.
  ///
  /// If null, the progress indicator is rendered with the current theme's
  /// [ThemeData.accentColor].
  final Animation<Color> valueColor;

  /// {@template flutter.material.progressIndicator.semanticsLabel}
  /// The [Semantics.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
  /// {@endtemplate}
  final String semanticsLabel;

  /// {@template flutter.material.progressIndicator.semanticsValue}
  /// The [Semantics.value] for this progress indicator.
  ///
  /// This will be used in conjunction with the [semanticsLabel] by
  /// screen reading software to identify the widget, and is primarily
  /// intended for use with determinate progress indicators to announce
  /// how far along they are.
  ///
  /// For determinate progress indicators, this will be defaulted to [value]
  /// expressed as a percentage, i.e. `0.1` will become '10%'.
  /// {@endtemplate}
  final String semanticsValue;

  Color _getBackgroundColor(BuildContext context) => backgroundColor ?? Theme.of(context).backgroundColor;
  Color _getValueColor(BuildContext context) => valueColor?.value ?? Theme.of(context).accentColor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value, showName: false, ifNull: '<indeterminate>'));
  }

  Widget _buildSemanticsWrapper({
    @required BuildContext context,
    @required Widget child,
  }) {
    String expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(value * 100).round()}%';
    }
    return Semantics(
      label: semanticsLabel,
      value: expandedSemanticsValue,
      child: child,
    );
  }
}

class _TencentLinearProgressIndicatorPainter extends CustomPainter {
  const _TencentLinearProgressIndicatorPainter({
    this.image,
    this.backgroundColor,
    this.valueColor,
    this.value,
    this.animationValue,
    @required this.textDirection,
  }) : assert(textDirection != null);

  final Color backgroundColor;
  final ui.Image image;
  final Color valueColor;
  final double value;
  final double animationValue;
  final TextDirection textDirection;

  // The indeterminate progress animation displays two lines whose leading (head)
  // and trailing (tail) endpoints are defined by the following four curves.
  static const Curve line1Head = Interval(
    0.0,
    750.0 / _kIndeterminateLinearDuration,
    curve: Cubic(0.2, 0.0, 0.8, 1.0),
  );
  static const Curve line1Tail = Interval(
    333.0 / _kIndeterminateLinearDuration,
    (333.0 + 750.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static const Curve line2Head = Interval(
    1000.0 / _kIndeterminateLinearDuration,
    (1000.0 + 567.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.0, 0.0, 0.65, 1.0),
  );
  static const Curve line2Tail = Interval(
    1267.0 / _kIndeterminateLinearDuration,
    (1267.0 + 533.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.10, 0.0, 0.45, 1.0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = valueColor;

    void drawBar(double x, double width) {
      if (width <= 0.0)
        return;

      double left;
      switch (textDirection) {
        case TextDirection.rtl:
          left = size.width - width - x;
          break;
        case TextDirection.ltr:
          left = x;
          break;
      }
      canvas.drawRect(Offset(left, 0.0) & Size(width, size.height), paint);
    }

    if (value != null) {
      drawBar(0.0, value.clamp(0.0, 1.0) * size.width);
      if (image != null) {
        canvas.drawImageRect(image, Offset(0.0, 0.0) & Size(image.width.toDouble(), image.height.toDouble()), Offset(value.clamp(0.0, 1.0) * size.width, -8.0) & Size(20, 20), paint);
      }
    } else {
      final double x1 = size.width * line1Tail.transform(animationValue);
      final double width1 = size.width * line1Head.transform(animationValue) - x1;

      final double x2 = size.width * line2Tail.transform(animationValue);
      final double width2 = size.width * line2Head.transform(animationValue) - x2;

      drawBar(x1, width1);
      drawBar(x2, width2);
    }
  }

  @override
  bool shouldRepaint(_TencentLinearProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor
        || oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.animationValue != animationValue
        || oldPainter.textDirection != textDirection;
  }
}

/// A material design linear progress indicator, also known as a progress bar.
///
/// A widget that shows progress along a line. There are two kinds of linear
/// progress indicators:
///
///  * _Determinate_. Determinate progress indicators have a specific value at
///    each point in time, and the value should increase monotonically from 0.0
///    to 1.0, at which time the indicator is complete. To create a determinate
///    progress indicator, use a non-null [value] between 0.0 and 1.0.
///  * _Indeterminate_. Indeterminate progress indicators do not have a specific
///    value at each point in time and instead indicate that progress is being
///    made without indicating how much progress remains. To create an
///    indeterminate progress indicator, use a null [value].
///
/// The indicator line is displayed with [valueColor], an animated value. To
/// specify a constant color value use: `AlwaysStoppedAnimation<Color>(color)`.
///
/// See also:
///
///  * [CircularProgressIndicator], which shows progress along a circular arc.
///  * [RefreshIndicator], which automatically displays a [CircularProgressIndicator]
///    when the underlying vertical scrollable is overscrolled.
///  * <https://material.io/design/components/progress-indicators.html#linear-progress-indicators>
class TencentLinearProgressIndicator extends ProgressIndicator {
  /// Creates a linear progress indicator.
  ///
  /// {@macro flutter.material.progressIndicator.parameters}
  const TencentLinearProgressIndicator({
    Key key,
    double value,
    Color backgroundColor,
    Animation<Color> valueColor,
    String semanticsLabel,
    String semanticsValue,
  }) : super(
    key: key,
    value: value,
    backgroundColor: backgroundColor,
    valueColor: valueColor,
    semanticsLabel: semanticsLabel,
    semanticsValue: semanticsValue,
  );

  @override
  _TencentLinearProgressIndicatorState createState() => _TencentLinearProgressIndicatorState();
}

class _TencentLinearProgressIndicatorState extends State<TencentLinearProgressIndicator> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateLinearDuration),
      vsync: this,
    );
    if (widget.value == null)
      _controller.repeat();


    initImage().then((val) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TencentLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating)
      _controller.repeat();
    else if (widget.value != null && _controller.isAnimating)
      _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, double animationValue, TextDirection textDirection) {
    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: _kTencentLinearProgressIndicatorHeight,
        ),
        child: CustomPaint(
          painter: _TencentLinearProgressIndicatorPainter(
            image: image,
            backgroundColor: widget._getBackgroundColor(context),
            valueColor: widget._getValueColor(context),
            value: widget.value, // may be null
            animationValue: animationValue, // ignored if widget.value is not null
            textDirection: textDirection,
          ),
        ),
      ),
    );
  }


  ui.Image image;

  Future<VoidCallback> initImage() async {
    image = await _loadImage('static/player_progress_img.png');
    return null;
  }


  /**
   * 通过assets路径，获取资源图片
   */
  Future<ui.Image> _loadImage(String assets) async {
    final ByteData data = await rootBundle.load(assets);
    if (data == null) throw 'Unable to read data';
    Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget.value != null)
      return _buildIndicator(context, _controller.value, textDirection);

    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget child) {
        return _buildIndicator(context, _controller.value, textDirection);
      },
    );
  }
}

