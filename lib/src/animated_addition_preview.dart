import 'package:flutter/cupertino.dart';
import 'animated_addition_observe.dart';
import 'dart:async';

///animated addition preview controller
class AnimatedAdditionPreviewController<T> extends ChangeNotifier {
  //offset preview global key
  final GlobalKey _offsetPreviewKey = GlobalKey();

  //_data list
  final List<T> _dataList = [];

  //offset preview completer
  Completer<double> _offsetPreviewCompleter = Completer();

  //preview items height
  Future<double> previewItemsHeight(List<T> dataList) {
    _offsetPreviewCompleter = Completer();
    _dataList.clear();
    _dataList.addAll(dataList);
    notifyListeners();
    return _offsetPreviewCompleter.future;
  }
}

///animated addition preview
class AnimatedAdditionPreview<T> extends StatefulWidget {
  //controller
  final AnimatedAdditionPreviewController<T> controller;

  //item builder
  final AnimatedItemBuilder itemBuilder;

  //padding
  final EdgeInsetsGeometry? padding;

  //margin
  final EdgeInsetsGeometry? margin;

  const AnimatedAdditionPreview({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.padding,
    this.margin,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnimatedAdditionPreviewState();
  }
}

///animated addition preview state
class _AnimatedAdditionPreviewState extends State<AnimatedAdditionPreview>
    with SingleTickerProviderStateMixin {
  //listener
  late VoidCallback _listener;

  late AnimationController _controller;
  late Animation<double> _animation;

  //init animation
  void _initAnimation() {
    //create controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    //create animation
    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _listener = () {
      setState(() {});
    };
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(AnimatedAdditionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_listener);
      widget.controller.addListener(_listener);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_listener);
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.controller._offsetPreviewKey,
      width: double.infinity,
      margin: widget.margin,
      padding: widget.padding,
      height: 0.001,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: 65535,
        child: ObserveHeightWidget(
          listener: (Size size) {
            if (!widget.controller._offsetPreviewCompleter.isCompleted) {
              widget.controller._offsetPreviewCompleter.complete(size.height);
            }
          },
          child: Visibility(
            visible: false,
            maintainState: true,
            maintainInteractivity: true,
            maintainAnimation: true,
            maintainSemantics: true,
            maintainSize: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.controller._dataList.mapIndexed((index, e) {
                return widget.itemBuilder(context, index, _animation);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

///定义一个扩展方法 mapIndexed
extension IterableExtensions<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    int index = 0;
    return map((e) => f(index++, e));
  }
}
