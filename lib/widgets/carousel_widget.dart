// ignore_for_file: prefer_final_fields
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_state.dart';
import 'package:creta01/player/abs_player.dart';
import 'package:creta01/common/util/logger.dart';
import 'package:flutter/gestures.dart';

import 'package:carousel_slider/utils.dart';

// export 'carousel_controller.dart';
// export 'carousel_options.dart';

MyCarouselSlider carouselWidget(
    BuildContext context,
    double height,
    List<AbsPlayWidget> widgetList,
    dynamic Function(int, CarouselPageChangedReason)? onPageChanged,
    Future<int> Function()? pageChanger,
    int playSec, // millisec
    int indexNo) {
  return MyCarouselSlider(
    pageChanger: pageChanger,
    options: CarouselOptions(
        height: height * 0.8,
        initialPage: indexNo,
        enlargeCenterPage: true,
        autoPlay: true,
        //autoPlay: bookManagerHolder!.isAutoPlay(),
        reverse: true,
        enableInfiniteScroll: true,
        autoPlayInterval:
            const Duration(milliseconds: 100), // contents play complete check timer interval 임
        autoPlayAnimationDuration: const Duration(milliseconds: 400),
        autoPlayCurve: Curves.slowMiddle,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index, reason) {
          logHolder.log('Carousel onPageChanged(index=$index)');
          if (onPageChanged != null) {
            onPageChanged.call(index, reason);
          }
          //setState(() {});
        }),
    //arouselController: carouselController,
    items: widgetList,
  );
}

typedef MyExtendedIndexedWidgetBuilder = Widget Function(
    BuildContext context, int index, int realIndex);

class MyCarouselSlider extends StatefulWidget {
  /// [CarouselOptions] to create a [CarouselState] with
  final CarouselOptions options;

  /// The widgets to be shown in the carousel of default constructor
  final List<Widget>? items;

  /// The widget item builder that will be used to build item on demand
  /// The third argument is the PageView's real index, can be used to cooperate
  /// with Hero.
  final MyExtendedIndexedWidgetBuilder? itemBuilder;

  /// A [MapController], used to control the map.
  final CarouselControllerImpl _carouselController;

  final int? itemCount;

  final Future<int> Function()? pageChanger; //skpark add

  MyCarouselSlider(
      {required this.items,
      required this.options,
      carouselController,
      this.pageChanger, //skpark add
      Key? key})
      : itemBuilder = null,
        itemCount = items != null ? items.length : 0,
        _carouselController = carouselController ?? CarouselController() as CarouselControllerImpl,
        super(key: key);

  /// The on demand item builder constructor
  MyCarouselSlider.builder(
      {required this.itemCount,
      required this.itemBuilder,
      required this.options,
      carouselController,
      this.pageChanger, //skpark add
      Key? key})
      : items = null,
        _carouselController = carouselController ?? CarouselController() as CarouselControllerImpl,
        super(key: key);

  @override
  MyCarouselSliderState createState() =>
      // ignore: no_logic_in_create_state
      MyCarouselSliderState(_carouselController);
}

class MyCarouselSliderState extends State<MyCarouselSlider> with TickerProviderStateMixin {
  final CarouselControllerImpl carouselController;
  Timer? timer;

  CarouselOptions get options => widget.options;

  CarouselState? carouselState;

  PageController? pageController;

  /// mode is related to why the page is being changed
  CarouselPageChangedReason mode = CarouselPageChangedReason.controller;

  MyCarouselSliderState(this.carouselController);

  void changeMode(CarouselPageChangedReason mode) {
    mode = mode;
  }

  @override
  void didUpdateWidget(MyCarouselSlider oldWidget) {
    carouselState!.options = options;
    carouselState!.itemCount = widget.itemCount;

    // pageController needs to be re-initialized to respond to state changes
    pageController = PageController(
      viewportFraction: options.viewportFraction,
      initialPage: carouselState!.realPage,
    );
    carouselState!.pageController = pageController;

    // handle autoplay when state changes
    handleAutoPlay();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    carouselState = CarouselState(options, clearTimer, resumeTimer, changeMode);

    carouselState!.itemCount = widget.itemCount;
    carouselController.state = carouselState;
    carouselState!.initialPage = widget.options.initialPage;
    carouselState!.realPage = options.enableInfiniteScroll
        ? carouselState!.realPage + carouselState!.initialPage
        : carouselState!.initialPage;
    handleAutoPlay();

    pageController = PageController(
      viewportFraction: options.viewportFraction,
      initialPage: carouselState!.realPage,
    );

    carouselState!.pageController = pageController;
  }

  Timer? getTimer() {
    // skpark add
    if (widget.options.autoPlay && widget.pageChanger != null) {
      return Timer.periodic(widget.options.autoPlayInterval, (timer) async {
        int currentIndex = await widget.pageChanger!();
        if (currentIndex >= 0) {
          await carouselController.animateToPage(currentIndex);
          //timerExpired(timer);
        }
      });
    }
    // skpark add end

    return widget.options.autoPlay
        ? Timer.periodic(widget.options.autoPlayInterval, timerExpired)
        : null;
  }

// skpark add
  void timerExpired(Timer timer) {
    final route = ModalRoute.of(context);
    if (route?.isCurrent == false) {
      return;
    }

    CarouselPageChangedReason previousReason = mode;
    changeMode(CarouselPageChangedReason.timed);
    int nextPage = carouselState!.pageController!.page!.floor() + 1;
    int itemCount = widget.itemCount ?? widget.items!.length;

    if (nextPage >= itemCount && widget.options.enableInfiniteScroll == false) {
      if (widget.options.pauseAutoPlayInFiniteScroll) {
        clearTimer();
        return;
      }
      nextPage = 0;
    }

    carouselState!.pageController!
        .animateToPage(nextPage,
            duration: widget.options.autoPlayAnimationDuration, curve: widget.options.autoPlayCurve)
        .then((_) => changeMode(previousReason));
  }
// skpark add end

  void clearTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }
  }

  void resumeTimer() {
    timer ??= getTimer();
  }

  void handleAutoPlay() {
    bool autoPlayEnabled = widget.options.autoPlay;

    if (autoPlayEnabled && timer != null) return;

    clearTimer();
    if (autoPlayEnabled) {
      resumeTimer();
    }
  }

  Widget getGestureWrapper(Widget child) {
    Widget wrapper;
    if (widget.options.height != null) {
      wrapper = SizedBox(height: widget.options.height, child: child);
    } else {
      wrapper = AspectRatio(aspectRatio: widget.options.aspectRatio, child: child);
    }

    return RawGestureDetector(
      gestures: {
        _MultipleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_MultipleGestureRecognizer>(
                () => _MultipleGestureRecognizer(), (_MultipleGestureRecognizer instance) {
          instance.onStart = (_) {
            onStart();
          };
          instance.onDown = (_) {
            onPanDown();
          };
          instance.onEnd = (_) {
            onPanUp();
          };
          instance.onCancel = () {
            onPanUp();
          };
        }),
      },
      child: NotificationListener(
        onNotification: (dynamic notification) {
          if (widget.options.onScrolled != null && notification is ScrollUpdateNotification) {
            widget.options.onScrolled!(carouselState!.pageController!.page);
          }
          return false;
        },
        child: wrapper,
      ),
    );
  }

  Widget getCenterWrapper(Widget child) {
    if (widget.options.disableCenter) {
      return Container(
        child: child,
      );
    }
    return Center(child: child);
  }

  Widget getEnlargeWrapper(Widget? child, {double? width, double? height, double? scale}) {
    if (widget.options.enlargeStrategy == CenterPageEnlargeStrategy.height) {
      return SizedBox(width: width, height: height, child: child);
    }
    return Transform.scale(
        scale: scale!, child: SizedBox(width: width, height: height, child: child));
  }

  void onStart() {
    changeMode(CarouselPageChangedReason.manual);
  }

  void onPanDown() {
    if (widget.options.pauseAutoPlayOnTouch) {
      clearTimer();
    }

    changeMode(CarouselPageChangedReason.manual);
  }

  void onPanUp() {
    if (widget.options.pauseAutoPlayOnTouch) {
      resumeTimer();
    }
  }

  @override
  void dispose() {
    super.dispose();
    clearTimer();
  }

  @override
  Widget build(BuildContext context) {
    return getGestureWrapper(PageView.builder(
      physics: widget.options.scrollPhysics,
      scrollDirection: widget.options.scrollDirection,
      pageSnapping: widget.options.pageSnapping,
      controller: carouselState!.pageController,
      reverse: widget.options.reverse,
      itemCount: widget.options.enableInfiniteScroll ? null : widget.itemCount,
      key: widget.options.pageViewKey,
      onPageChanged: (int index) {
        int currentPage = getRealIndex(
            index + carouselState!.initialPage, carouselState!.realPage, widget.itemCount);
        if (widget.options.onPageChanged != null) {
          widget.options.onPageChanged!(currentPage, mode);
        }
      },
      itemBuilder: (BuildContext context, int idx) {
        final int index = getRealIndex(
            idx + carouselState!.initialPage, carouselState!.realPage, widget.itemCount);

        return AnimatedBuilder(
          animation: carouselState!.pageController!,
          child: (widget.items != null)
              ? (widget.items!.isNotEmpty ? widget.items![index] : Container())
              : widget.itemBuilder!(context, index, idx),
          builder: (BuildContext context, child) {
            double distortionValue = 1.0;
            // if `enlargeCenterPage` is true, we must calculate the carousel item's height
            // to display the visual effect
            if (widget.options.enlargeCenterPage != null &&
                widget.options.enlargeCenterPage == true) {
              double itemOffset;
              // pageController.page can only be accessed after the first build,
              // so in the first build we calculate the itemoffset manually
              try {
                itemOffset = carouselState!.pageController!.page! - idx;
              } catch (e) {
                BuildContext storageContext =
                    carouselState!.pageController!.position.context.storageContext;
                final double? previousSavedPosition =
                    PageStorage.of(storageContext)?.readState(storageContext) as double?;
                if (previousSavedPosition != null) {
                  itemOffset = previousSavedPosition - idx.toDouble();
                } else {
                  itemOffset = carouselState!.realPage.toDouble() - idx.toDouble();
                }
              }
              final num distortionRatio = (1 - (itemOffset.abs() * 0.3)).clamp(0.0, 1.0);
              distortionValue = Curves.easeOut.transform(distortionRatio as double);
            }

            final double height = widget.options.height ??
                MediaQuery.of(context).size.width * (1 / widget.options.aspectRatio);

            if (widget.options.scrollDirection == Axis.horizontal) {
              return getCenterWrapper(getEnlargeWrapper(child,
                  height: distortionValue * height, scale: distortionValue));
            } else {
              return getCenterWrapper(getEnlargeWrapper(child,
                  width: distortionValue * MediaQuery.of(context).size.width,
                  scale: distortionValue));
            }
          },
        );
      },
    ));
  }
}

class _MultipleGestureRecognizer extends PanGestureRecognizer {}
