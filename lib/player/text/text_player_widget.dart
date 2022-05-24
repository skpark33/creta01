// ignore: implementation_imports
// ignore_for_file: prefer_final_fields

import 'dart:math';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
//import 'package:text_scroll/text_scroll.dart';

import 'package:creta01/book_manager.dart';
import 'package:creta01/common/notifiers/notifiers.dart';
import 'package:creta01/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:creta01/model/contents.dart';
import 'package:creta01/model/model_enums.dart';
import 'package:creta01/acc/acc.dart';
import 'package:creta01/player/abs_player.dart';

import '../../common/util/my_utils.dart';
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
      int textSize = getStringSize(uri); // 텍스트 길이
      double entireWidth = fontSize * textSize; // 한줄로 했을때, 필요한 width
      int lineCount =
          (entireWidth / (0.9 * realSize.width)).ceil(); //  현재 폰트사이즈에서 현재 width 상황에서 필요한 라인수
      double idealWidth = fontSize * (textSize.toDouble() / lineCount.toDouble()); //
      double idealHeight = (lineCount + 1) * fontSize;

      // 이상적인 사이즈가 현재 사이즈보다 크다면, 폰트가 줄어들어야 하고,
      // 현재 사이즈보다 작다면,  폰트가 커져야 한다.
      double fontRatio = sqrt(realSize.width * realSize.height) / sqrt(idealWidth * idealHeight);
      fontSize = fontSize * fontRatio;

      //logHolder.log("font = ${widget.model!.font.value}, fontRatio=$fontRatio, fontSize=$fontSize",
      //    level: 6);
    }

    TextStyle style = DefaultTextStyle.of(context).style.copyWith(
        fontFamily: widget.model!.font.value,
        color: widget.model!.fontColor.value.withOpacity(widget.model!.opacity.value),
        fontSize: fontSize,
        decoration: getTextDecoration(widget.model!.line.value),
        fontWeight: widget.model!.isBold.value ? FontWeight.bold : FontWeight.normal,
        fontStyle: widget.model!.isItalic.value ? FontStyle.italic : FontStyle.normal);

    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(realSize.width * 0.05, realSize.height * 0.05,
            realSize.width * 0.05, realSize.height * 0.05),
        alignment: AlignmentDirectional.center,
        width: realSize.width,
        height: realSize.height,
        color: Colors.transparent,
        child: widget.model!.shadowBlur.value > 0
            ? shadowText(
                outLineText(uri, style, fontSize),
                uri,
                style,
                widget.model!.shadowColor.value,
                widget.model!.shadowBlur.value,
                widget.model!.shadowIntensity.value)
            : outLineText(uri, style, fontSize),
      ),
    );
  }

  Widget outLineText(String text, TextStyle style, double fontSize) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        widget.model!.aniType.value != AnimeType.none
            ? animationText(text, style)
            : widget.model!.outLineWidth.value > 0
                ? Text(
                    text,
                    textAlign: widget.model!.align.value,
                    style: style.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = widget.model!.outLineWidth.value
                        ..color = widget.model!.outLineColor.value,
                    ),
                    // DefaultTextStyle.of(context).style.copyWith(
                    //       fontFamily: widget.model!.font.value,
                    //       fontSize: fontSize,
                    //       foreground: Paint()
                    //         ..style = PaintingStyle.stroke
                    //         ..strokeWidth = widget.model!.outLineWidth.value
                    //         ..color = widget.model!.outLineColor.value,
                    //     ),
                  )
                // style: style.copyWith(
                //   foreground: Paint()
                //     ..style = PaintingStyle.stroke
                //     ..strokeWidth = widget.model!.outLineWidth.value
                //     ..color = widget.model!.outLineColor.value,
                // ),
                //)
                : Container(),
        Text(text, textAlign: widget.model!.align.value, style: style),
      ],
    );
  }

  Widget shadowText(Widget child, String text, TextStyle style, Color shadowColor, double blur,
      double intensity) {
    logHolder.log('shadowText $blur', level: 6);
    return ClipRect(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          //Positioned(
          //top: blur,
          //left: blur,
          //child:
          Text(
            text,
            textAlign: widget.model!.align.value,
            style: style.copyWith(color: shadowColor.withOpacity(intensity)),
          ),
          //),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget animationText(String text, TextStyle style) {
    switch (widget.model!.aniType.value) {
      case TextAniType.marquee:
        {
          return Container();
          // return TextScroll(
          //   text,
          //   mode: TextScrollMode.bouncing,
          //   numberOfReps: 200,
          //   delayBefore: const Duration(milliseconds: 2000),
          //   pauseBetween: const Duration(milliseconds: 1000),
          //   velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
          //   style: style,
          //   textAlign: TextAlign.right,
          //   selectable: true,
          // );
        }
      default:
        return Container();
    }
  }
}
