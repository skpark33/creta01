// ignore: implementation_imports
// ignore_for_file: prefer_final_fields

//import 'dart:math';
import 'package:creta01/constants/constants.dart';
import 'package:provider/provider.dart';
//import 'package:text_scroll/text_scroll.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:creta01/book_manager.dart';
import 'package:creta01/common/notifiers/notifiers.dart';
import 'package:creta01/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:creta01/model/contents.dart';
import 'package:creta01/model/model_enums.dart';
import 'package:creta01/acc/acc.dart';
import 'package:creta01/player/abs_player.dart';

//import '../../common/util/my_utils.dart';
import '../../constants/styles.dart';

// ignore: must_be_immutable

class TextPlayerProgress extends StatefulWidget {
  final double width;
  final double height;
  final GlobalKey<TextPlayerProgressState> controllerKey;

  const TextPlayerProgress({required this.controllerKey, required this.width, required this.height})
      : super(key: controllerKey);

  @override
  State<TextPlayerProgress> createState() => TextPlayerProgressState();
}

class TextPlayerProgressState extends State<TextPlayerProgress> {
  void invalidate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressNotifier>(builder: (context, notifier, child) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: LinearProgressIndicator(
          value: notifier.progress,
          valueColor: const AlwaysStoppedAnimation<Color>(MyColors.playedColor),
          backgroundColor: notifier.progress == 0 ? MyColors.pgBackgroundColor : Colors.transparent,
        ),
      );
    });
  }
}

// ignore: must_be_immutable
class TextPlayerWidget extends AbsPlayWidget {
  TextPlayerWidget({
    required GlobalObjectKey<TextPlayerWidgetState> key,
    required ContentsModel model,
    required ACC acc,
    void Function()? onAfterEvent,
    bool autoStart = true,
  }) : super(key: key, onAfterEvent: onAfterEvent, acc: acc, model: model, autoStart: autoStart) {
    globalKey = key;
  }

  GlobalObjectKey<TextPlayerWidgetState>? globalKey;
  TextEditingController controller = TextEditingController();

  @override
  Future<void> play({bool byManual = false}) async {
    logHolder.log('image play');
    model!.setPlayState(PlayState.start);
    if (byManual) {
      model!.setManualState(PlayState.start);
    }
  }

  @override
  Future<void> pause({bool byManual = false}) async {
    model!.setPlayState(PlayState.pause);
  }

  @override
  Future<void> close() async {
    logHolder.log('Image close', level: 6);

    model!.setPlayState(PlayState.none);
  }

  @override
  void invalidate() {
    if (globalKey != null && globalKey!.currentState != null) {
      globalKey!.currentState!.invalidate();
    }
  }

  @override
  bool isInit() {
    return true;
  }

  @override
  ContentsModel getModel() {
    return model!;
  }

  @override
  TextPlayerWidgetState createState() => TextPlayerWidgetState();
}

class TextPlayerWidgetState extends State<TextPlayerWidget> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void invalidate() {
    setState(() {});
  }

//Future<Image> _getImageInfo(String url) async {

  Future<void> afterBuild() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.afterBuild();
    });
  }

  @override
  void initState() {
    super.initState();
    afterBuild();
  }

  @override
  Widget build(BuildContext context) {
    if (bookManagerHolder!.isAutoPlay()) {
      widget.model!.setPlayState(PlayState.start);
    } else {
      widget.model!.setPlayState(PlayState.pause);
    }
    Size realSize = widget.acc.getRealSize();
    //Size outSize = widget.getOuterSize(widget.model!.aspectRatio.value);

    // double topLeft = widget.acc.accModel.radiusTopLeft.value;
    // double topRight = widget.acc.accModel.radiusTopRight.value;
    // double bottomLeft = widget.acc.accModel.radiusBottomLeft.value;
    // double bottomRight = widget.acc.accModel.radiusBottomRight.value;

    String uri = widget.getURI(widget.model!);
    double fontSize = widget.model!.fontSize.value;

    if (widget.model!.isAutoSize.value == true) {
      fontSize = maxFontSize;
      //   int textSize = getStringSize(uri); // 텍스트 길이
      //   double entireWidth = fontSize * textSize; // 한줄로 했을때, 필요한 width
      //   int lineCount =
      //       (entireWidth / (0.9 * realSize.width)).ceil(); //  현재 폰트사이즈에서 현재 width 상황에서 필요한 라인수
      //   double idealWidth = fontSize * (textSize.toDouble() / lineCount.toDouble()); //
      //   double idealHeight = (lineCount + 1) * fontSize;

      //   // 이상적인 사이즈가 현재 사이즈보다 크다면, 폰트가 줄어들어야 하고,
      //   // 현재 사이즈보다 작다면,  폰트가 커져야 한다.
      //   double fontRatio = sqrt(realSize.width * realSize.height) / sqrt(idealWidth * idealHeight);
      //   fontSize = fontSize * fontRatio;

      //   //logHolder.log("font = ${widget.model!.font.value}, fontRatio=$fontRatio, fontSize=$fontSize",
      //   //    level: 6);
    }

    TextStyle style = DefaultTextStyle.of(context).style.copyWith(
        fontFamily: widget.model!.font.value,
        color: widget.model!.fontColor.value.withOpacity(widget.model!.opacity.value),
        fontSize: fontSize,
        decoration: getTextDecoration(widget.model!.line.value),
        fontWeight: widget.model!.isBold.value ? FontWeight.bold : FontWeight.normal,
        fontStyle: widget.model!.isItalic.value ? FontStyle.italic : FontStyle.normal);

    //shadow case

    // //outline case
    // if (widget.model!.outLineWidth.value > 0) {
    //   style.copyWith(
    //     foreground: Paint()
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = widget.model!.outLineWidth.value
    //       ..color = widget.model!.outLineColor.value,
    //   );
    // }
    if (widget.model!.isAutoSize.value == false) {
      style.copyWith(
        fontSize: fontSize,
      );
    }
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(realSize.width * 0.05, realSize.height * 0.05,
            realSize.width * 0.05, realSize.height * 0.05),
        alignment: AlignmentDirectional.center,
        width: realSize.width,
        height: realSize.height,
        color: Colors.transparent,
        child: outLineText(uri, style, fontSize),
        // child: widget.model!.shadowBlur.value > 0
        // ? shadowText(uri, style, widget.model!.shadowColor.value,
        //     widget.model!.shadowBlur.value, widget.model!.shadowIntensity.value)
        // : outLineText(uri, style, fontSize),
      ),
    );

    // AutoSize 인 경우
  }

  Widget outLineText(String text, TextStyle style, double fontSize) {
    logHolder.log('outLineText ${widget.model!.outLineWidth.value} ${widget.model!.aniType.value}',
        level: 6);

    // 새도우의 경우.
    TextStyle? shadowStyle;
    if (widget.model!.shadowBlur.value > 0) {
      logHolder.log('widget.model!.shadowBlur.value=${widget.model!.shadowBlur.value}', level: 6);
      shadowStyle = style.copyWith(shadows: [
        Shadow(
            color: widget.model!.shadowColor.value.withOpacity(widget.model!.shadowIntensity.value),
            offset: Offset(
                widget.model!.shadowBlur.value * 0.75, widget.model!.shadowBlur.value * 0.75),
            blurRadius: widget.model!.shadowBlur.value),
      ]);
    }

    if (widget.model!.aniType.value != TextAniType.none) {
      return animationText(text, shadowStyle ?? style);
    }

    //aninationText 는 아웃라인을 적용하지 못한다.
    // 아웃라인의 경우.
    if (widget.model!.outLineWidth.value > 0) {
      TextStyle outlineStyle = style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = widget.model!.outLineWidth.value
          ..color = widget.model!.outLineColor.value,
      );

      return Stack(
        alignment: AlignmentDirectional.center,
        children: [
          widget.model!.isAutoSize.value
              ? AutoSizeText(text, textAlign: widget.model!.align.value, style: outlineStyle)
              : Text(text, textAlign: widget.model!.align.value, style: outlineStyle),
          widget.model!.isAutoSize.value
              ? AutoSizeText(text,
                  textAlign: widget.model!.align.value, style: shadowStyle ?? style)
              : Text(text, textAlign: widget.model!.align.value, style: shadowStyle ?? style),
        ],
      );
    }

    // 아웃라인도 아니고, 애니매이션도 아닌 경우.
    return widget.model!.isAutoSize.value
        ? AutoSizeText(text, textAlign: widget.model!.align.value, style: shadowStyle ?? style)
        : Text(text, textAlign: widget.model!.align.value, style: shadowStyle ?? style);
  }

  // Widget shadowText(
  //     String text, TextStyle style, Color shadowColor, double blur, double intensity) {
  //   logHolder.log('shadowText $blur', level: 6);
  //   if (widget.model!.isAutoSize.value == true) {
  //     return AutoSizeText(
  //       text,
  //       textAlign: widget.model!.align.value,
  //       style: style.copyWith(shadows: [
  //         Shadow(
  //             color: shadowColor.withOpacity(intensity),
  //             offset: Offset(blur * 0.75, blur * 0.75),
  //             blurRadius: blur),
  //       ]),
  //     );
  //   }
  //   return Text(
  //     text,
  //     textAlign: widget.model!.align.value,
  //     style: style.copyWith(shadows: [
  //       Shadow(
  //           color: shadowColor.withOpacity(intensity),
  //           offset: Offset(blur * 0.75, blur * 0.75),
  //           blurRadius: blur),
  //     ]),
  //   );
  // }

  Widget animationText(String text, TextStyle style) {
    switch (widget.model!.aniType.value) {
      case TextAniType.tickerSide:
        {
          return TextScroll(
            text,
            style: style,
            textAlign: TextAlign.left,
            mode: TextScrollMode.endless,
            velocity: Velocity(pixelsPerSecond: Offset(widget.model!.anyDuration.value * 2, 0)),
          );
        }
      default:
        return Container();
    }
  }
}
