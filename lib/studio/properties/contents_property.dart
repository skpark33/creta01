//import 'package:flutter/cupertino.dart';
//mport 'package:creta01/acc/acc_manager.dart';
// ignore_for_file: prefer_const_constructors

import 'package:creta01/acc/acc_manager.dart';
import 'package:creta01/studio/properties/widget_property.dart';
import 'package:provider/provider.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';

//import 'package:creta01/model/contents.dart';
//import 'package:creta01/common/util/logger.dart';
import 'package:creta01/common/util/textfileds.dart';
import 'package:creta01/model/contents.dart';
import 'package:creta01/model/model_enums.dart';
import 'package:creta01/player/play_manager.dart';
import 'package:creta01/model/pages.dart';
import 'package:creta01/studio/properties/property_selector.dart';

import 'package:creta01/studio/properties/properties_frame.dart';
import 'package:creta01/common/util/my_utils.dart';
import 'package:creta01/constants/strings.dart';
import 'package:creta01/constants/styles.dart';
import 'package:creta01/constants/constants.dart';

import '../../common/colorPicker/color_row.dart';
import '../../common/util/logger.dart';
import '../../model/users.dart';
//import 'package:creta01/common/util/my_utils.dart';

// ignore: must_be_immutable
class ContentsProperty extends PropertySelector {
  ContentsProperty(
    Key? key,
    PageModel? pselectedPage,
    bool pisNarrow,
    bool pisLandscape,
    PropertiesFrameState parent,
  ) : super(
          key: key,
          selectedPage: pselectedPage,
          isNarrow: pisNarrow,
          isLandscape: pisLandscape,
          parent: parent,
        );
  @override
  State<ContentsProperty> createState() => ContentsPropertyState();
}

class ContentsPropertyState extends State<ContentsProperty> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0.0);

  TextEditingController secCon = TextEditingController();
  TextEditingController minCon = TextEditingController();
  TextEditingController hourCon = TextEditingController();
  TextEditingController textCon = TextEditingController();

  TextEditingController colorCon = TextEditingController();
  TextEditingController outlineCon = TextEditingController();

  final List<ExapandableModel> _modelList = [];

  ExapandableModel fontColorModel = ExapandableModel(
    //title: '${MyStrings.bgColor}/${MyStrings.glass}/${MyStrings.opacity}',
    title: '${MyStrings.fontColor}/${MyStrings.opacity}',
    height: 480,
    width: 240,
  );

  ExapandableModel outlineModel = ExapandableModel(
    //title: '${MyStrings.bgColor}/${MyStrings.glass}/${MyStrings.opacity}',
    title: MyStrings.outline,
    height: 480,
    width: 240,
  );

  void unexpendAll(String expandModelName) {
    for (ExapandableModel model in _modelList) {
      if (expandModelName != model.title) {
        model.isSelected = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _modelList.add(fontColorModel);
    _modelList.add(outlineModel);
  }

  Future<ContentsModel> waitContents(SelectedModel selectedModel) async {
    ContentsModel? retval;

    while (retval == null) {
      retval = await selectedModel.getModel();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return retval;
  }

  void invalidateContents() {
    if (accManagerHolder != null && accManagerHolder!.getCurrentACC() != null) {
      accManagerHolder!.getCurrentACC()!.accChild.playManager.invalidate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thickness: 8.0,
      scrollbarOrientation: ScrollbarOrientation.left,
      thumbVisibility: true,
      controller: _scrollController,
      child: Consumer<SelectedModel>(builder: (context, selectedModel, child) {
        return FutureBuilder(
            future: waitContents(selectedModel),
            builder: (BuildContext context, AsyncSnapshot<ContentsModel> snapshot) {
              if (snapshot.hasData == false) {
                //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
                return showWaitSign();
              }
              if (snapshot.hasError) {
                //error가 발생하게 될 경우 반환하게 되는 부분
                return errMsgWidget(snapshot);
              }

              ContentsModel model = snapshot.data!;

              double millisec = model.playTime.value;
              if (model.isVideo()) {
                millisec = model.videoPlayTime.value;
              }
              double sec = (millisec / 1000);

              int textSize = 0;
              if (model.remoteUrl != null) {
                textSize = getStringSize(model.remoteUrl!);
              }

              List<Widget> textPropList = [];
              if (model.contentsType == ContentsType.text) {
                // Text Row
                textPropList.add(textRow(model, textSize));
                // Text Font Row
                textPropList.add(fontRow(model));
                // Text AutoSize
                textPropList.add(Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: myCheckBox(MyStrings.isAutoSize, model.isAutoSize.value, () {
                    setState(() {
                      model.isAutoSize.set(!model.isAutoSize.value);
                      invalidateContents();
                    });
                  }, 8, 2, 0, 2),
                ));
                // Text Font Size
                textPropList.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                    child: doubleSlider(
                      title: MyStrings.fontSize,
                      value: model.fontSize.value,
                      onChanged: (val) {
                        setState(() {
                          model.fontSize.set(val);
                          invalidateContents();
                        });
                      },
                      onChangeStart: (val) {},
                      min: 4,
                      max: 300,
                    ),
                  ),
                );
                // Text Font Color
                textPropList.add(divider());
                textPropList.add(fontColorExpander(model));
                textPropList.add(divider());
                textPropList.add(outlineExpander(model));
                textPropList.add(divider());
              }

              return ListView(controller: _scrollController, children: [
                _basicInfo(model, millisec, sec),
                SizedBox(height: 22),
                ...textPropList,
              ]);
            });

        //return ListView(controller: _scrollController, children: [
      }),
    );
    //);
  }

  Widget _basicInfo(ContentsModel model, double millisec, double sec) {
    if (model.contentsType == ContentsType.text) return Container();

    return Padding(
        padding: const EdgeInsets.fromLTRB(25, 25, 5, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.name,
              style: MyTextStyles.h6.copyWith(color: MyColors.primaryText),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            smallDivider(height: 8, indent: 0, endIndent: 20),
            Text(
              '${model.contentsType}',
              style: MyTextStyles.subtitle1,
            ),
            Text(
              model.size,
              style: MyTextStyles.subtitle1,
            ),
            Text(
              'width/height.${(model.aspectRatio.value * 100).round() / 100}',
              style: MyTextStyles.subtitle2,
            ),
            model.contentsType == ContentsType.image
                // ||
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      smallDivider(height: 8, indent: 0, endIndent: 20),
                      Row(
                        children: [
                          Text(
                            MyStrings.playTime,
                            style: MyTextStyles.subtitle1,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          myCheckBox(MyStrings.forever, (millisec == playTimeForever), () {
                            if (millisec != playTimeForever) {
                              model.reservPlayTime();
                              model.playTime.set(playTimeForever);
                            } else {
                              model.resetPlayTime();
                            }
                            setState(() {});
                          }, 8, 2, 0, 2),
                        ],
                      ),
                      Visibility(
                        visible: millisec != playTimeForever,
                        child: Row(
                          children: [
                            myNumberTextField2(
                                width: 50,
                                height: 84,
                                maxValue: 59,
                                defaultValue: (sec % 60),
                                controller: secCon,
                                onEditingComplete: () {
                                  _updateTime(model);
                                }),
                            SizedBox(width: 4),
                            Text(
                              MyStrings.seconds,
                              style: MyTextStyles.subtitle2,
                            ),
                            SizedBox(width: 10),
                            myNumberTextField2(
                                width: 50,
                                height: 84,
                                maxValue: 59,
                                defaultValue: (sec % (60 * 60) / 60).floorToDouble(),
                                controller: minCon,
                                onEditingComplete: () {
                                  _updateTime(model);
                                }),
                            SizedBox(width: 4),
                            Text(
                              MyStrings.minutes,
                              style: MyTextStyles.subtitle2,
                            ),
                            SizedBox(width: 10),
                            myNumberTextField2(
                                width: 50,
                                height: 84,
                                maxValue: 23,
                                defaultValue: (sec / (60 * 60)).floorToDouble(),
                                controller: hourCon,
                                onEditingComplete: () {
                                  _updateTime(model);
                                }),
                            SizedBox(width: 4),
                            Text(
                              MyStrings.hours,
                              style: MyTextStyles.subtitle2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Text(
                    _toTimeString(sec),
                    style: MyTextStyles.subtitle1,
                  ),
            // Text(
            //   'sound.${model.volume}',
            // ),
          ],
        ));
  }

  void _updateTime(ContentsModel model) {
    setState(() {
      int sec = int.parse(secCon.text);
      int min = int.parse(minCon.text);
      int hour = int.parse(hourCon.text);
      model.playTime.set((hour * 60 * 60 + min * 60 + sec) * 1000);
    });
  }

  String _toTimeString(double sec) {
    return '${(sec / (60 * 60)).floor()} hour ${(sec % (60 * 60) / 60).floor()} min ${(sec % 60).floor()} sec';
  }

  Widget titleRow(double left, double top, double right, double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(left, top, right, bottom),
      child: Text(
        MyStrings.contentsPropTitle,
        style: MyTextStyles.body1,
      ),
    );
  }

  Widget textRow(ContentsModel model, int textSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 10, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.zero,
            width: layoutPropertiesWidth * 0.75,
            child: myTextField(
              model.remoteUrl!,
              maxLines: textSize > 4 * 24 ? 4 : null, //한줄에 24자 정도 들어감
              limit: 4096,
              textAlign: TextAlign.start,
              labelText: MyStrings.text,
              controller: textCon,
              hasBorder: true,
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
              onEditingComplete: () {
                logHolder.log("textval = ${textCon.text}");
                model.remoteUrl = textCon.text;
                model.save();
                invalidateContents();
              },
            ),
          ),
          writeButton(
            onPressed: () {
              logHolder.log("textval = ${textCon.text}");
              model.remoteUrl = textCon.text;
              model.save();
              invalidateContents();
            },
          ),
        ],
      ),
    );
  }

  Widget fontRow(ContentsModel model) {
    return Padding(
      // 폰트
      padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text(MyStrings.font),
        const SizedBox(
          width: 15,
        ),
        DropdownButton<String>(
          value: getFontName(model.font.value),
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          //style: const TextStyle(color: Colors.deepPurple),
          underline: Container(height: 2, color: MyColors.primaryColor),
          onChanged: (String? newValue) {
            setState(() {
              String font = getFontFamily(newValue!);
              logHolder.log("fontFamily=$font", level: 6);
              model.font.set(font);
              invalidateContents();
            });
          },
          items: <String>[
            MyStrings.fontPretendard,
            MyStrings.fontNoto_Sans_KR,
            MyStrings.fontNanum_Myeongjo,
            MyStrings.fontNanum_Gothic,
            MyStrings.fontNanum_Pen_Script,
            MyStrings.fontJua,
            MyStrings.fontMacondo,
          ].map<DropdownMenuItem<String>>((String e) {
            String font = getFontFamily(e);
            logHolder.log("fontFamily====$font", level: 6);
            return DropdownMenuItem<String>(
                value: e, child: Text(e, style: TextStyle(fontFamily: font)));
          }).toList(),
        ),
      ]),
    );
  }

  Widget fontColorExpander(ContentsModel model) {
    return fontColorModel.expandArea(
        child: fontColorRow(context, model),
        setStateFunction: () {
          setState(() {
            unexpendAll(fontColorModel.title);
            fontColorModel.toggleSelected();
          });
        },
        titleSize: 150,
        titleLineWidget: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            glassIcon(
              false, //model.glassFill.value > 0,
              model.fontColor.value,
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              '${((1 - model.opacity.value) * 100).toInt()}%',
            ),
          ],
        ));
  }

  Widget fontColorRow(BuildContext context, ContentsModel model) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 22,
      ),
      child: myColorPicker(
        context,
        model.fontColor.value,
        opacity: model.opacity.value,
        controller: colorCon,
        //glassFill: model.glassFill.value,
        favorateColorPick: (value) {
          setState(() {
            model.fontColor.set(value);
          });
          invalidateContents();
        },
        onColorChangedEnd: (value) {
          setState(() {
            model.fontColor.set(value);
          });
          invalidateContents();
          currentUser.setUserColorList(value);
        },
        onEditComplete: (value) {
          setState(() {
            model.fontColor.set(value);
          });
          invalidateContents();
        },
        onGlassChanged: (value) {},
        onOpacityChanged: (value) {
          setState(() {
            model.opacity.set(value);
          });
          invalidateContents();
        },
        onOutLineChanged: (value) {},
      ),
    );
  }

  Widget outlineExpander(ContentsModel model) {
    return outlineModel.expandArea(
        child: outlineRow(context, model),
        setStateFunction: () {
          setState(() {
            unexpendAll(outlineModel.title);
            outlineModel.toggleSelected();
          });
        },
        titleSize: 150,
        titleLineWidget: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            glassIcon(
              false, //model.glassFill.value > 0,
              model.outLineColor.value,
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              '${model.outLineWidth.value.round()}',
            ),
            SizedBox(
              width: 28,
            ),
          ],
        ));
  }

  Widget outlineRow(BuildContext context, ContentsModel model) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 22,
      ),
      child: myColorPicker(
        context,
        model.outLineColor.value,
        outLineWidth: model.outLineWidth.value,
        controller: outlineCon,
        //glassFill: model.glassFill.value,
        favorateColorPick: (value) {
          setState(() {
            model.outLineColor.set(value);
          });
          invalidateContents();
        },
        onColorChangedEnd: (value) {
          setState(() {
            model.outLineColor.set(value);
          });
          invalidateContents();
          currentUser.setUserColorList(value);
        },
        onEditComplete: (value) {
          setState(() {
            model.outLineColor.set(value);
          });
          invalidateContents();
        },
        onGlassChanged: (value) {},
        onOpacityChanged: (value) {},
        onOutLineChanged: (value) {
          setState(() {
            model.outLineWidth.set(value);
          });
          invalidateContents();
        },
      ),
    );
  }
}
