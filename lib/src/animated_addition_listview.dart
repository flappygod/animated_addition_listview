import 'anchor_scroller/anchor_scroll_controller.dart';
import 'anchor_scroller/anchor_scroll_wrapper.dart';
import 'package:synchronized/synchronized.dart';
import 'animated_addition_preview.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

///animated addition data provider
typedef AnimatedAdditionDataProvider<T> = Future<List<T>> Function(
    T? current, int count);

///animated addition
typedef AnimatedAdditionControllerListener = void Function(
    int type, dynamic data);

///animated addition
typedef AnimatedAdditionOnShow<T> = void Function(List<T> data);

///animated addition listview controller
class AnimatedAdditionListViewController<T> {
  static const int _loadHeadEvent = 1;
  static const int _loadTailEvent = 2;
  static const int _jumpToNotExists = 3;

  //list scroll controller
  final AnchorScrollController _listScrollController;

  //listeners
  final List<AnimatedAdditionControllerListener> _listeners = [];

  //list lock
  final Lock _listLock = Lock();

  //list Key
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  //data list
  final List<T> _dataList;

  //page count
  final int pageCount;

  //page size check
  final bool pageSizeCheck;

  //scroll speed
  final double scrollSpeed;

  //curve
  final Curve curve;

  //provide tail data
  final AnimatedAdditionDataProvider<T> tailDataProvider;

  //provide head data
  final AnimatedAdditionDataProvider<T> headDataProvider;

  //get scroll controller
  AnchorScrollController get scrollController => _listScrollController;

  //get data list
  List<T> get dataList => List.from(_dataList);

  //head end
  bool _isHeadEnd = false;

  //tail end
  bool _isTailEnd = false;

  //add listener
  void addListener(AnimatedAdditionControllerListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  //remove listener
  bool removeListener(AnimatedAdditionControllerListener listener) {
    return _listeners.remove(listener);
  }

  //notify listeners
  void notifyListeners(int event, dynamic data) {
    for (AnimatedAdditionControllerListener listener in _listeners) {
      listener(event, data);
    }
  }

  //animated addition list view controller
  AnimatedAdditionListViewController({
    required this.tailDataProvider,
    required this.headDataProvider,
    this.scrollSpeed = 4,
    this.curve = Curves.linear,
    double anchorOffset = 0,
    AnchorScrollController? scrollController,
    List<T> dataList = const [],
    this.pageCount = 20,
    this.pageSizeCheck = true,
  })  : _listScrollController = scrollController ??
            AnchorScrollController(anchorOffsetAll: anchorOffset),
        _dataList = dataList;

  //load head items
  void loadHeadItems() {
    notifyListeners(_loadHeadEvent, null);
  }

  //load tail items
  void loadTailItems() {
    notifyListeners(_loadTailEvent, null);
  }

  //animated to item
  void animateToItem(
    T t,
  ) {
    //animated to item
    int index = _dataList.indexOf(t);
    if (index != -1) {
      animateToIndex(index);
    } else {
      notifyListeners(_jumpToNotExists, t);
    }
  }

  //animate to index
  void animateToIndex(
    int index,
  ) {
    _listScrollController.scrollToIndex(
      index: index,
      scrollSpeed: scrollSpeed,
      curve: curve,
    );
  }

  //scroll to top
  void scrollToTop({
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeIn,
  }) {
    _listScrollController.animateTo(
      0,
      duration: duration,
      curve: curve,
    );
  }
}

///animated addition listview
class AnimatedAdditionListView<T> extends StatefulWidget {
  final AnimatedAdditionListViewController<T> controller;
  final AnimatedItemBuilder itemBuilder;
  final AnimatedAdditionOnShow<T>? onItemShow;
  final int initialItemCount;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final double loadOffset;

  const AnimatedAdditionListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onItemShow,
    this.initialItemCount = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.clipBehavior = Clip.hardEdge,
    this.loadOffset = 50,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnimatedAdditionListViewState<T>();
  }
}

///animated addition listview state
class _AnimatedAdditionListViewState<T>
    extends State<AnimatedAdditionListView<T>> {
  //controller
  final AnimatedAdditionPreviewController<T> _previewController =
      AnimatedAdditionPreviewController<T>();

  //function listener
  late AnimatedAdditionControllerListener _listener;

  @override
  void initState() {
    _listener = (int event, dynamic data) {
      if (event == AnimatedAdditionListViewController._loadHeadEvent) {
        _loadHeadItems();
      }
      if (event == AnimatedAdditionListViewController._loadTailEvent) {
        _loadTailItems();
      }
      if (event == AnimatedAdditionListViewController._jumpToNotExists) {
        _jumpToItemNotExists(data);
      }
    };
    widget.controller.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyOnShow();
    });
    super.initState();
  }

  @override
  void didUpdateWidget(AnimatedAdditionListView<T> oldWidget) {
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
  }

  @override
  Widget build(BuildContext context) {
    return _buildAdditionList();
  }

  ///build animated addition list view
  Widget _buildAdditionList() {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ///preview items widget
          AnimatedAdditionPreview<T>(
            padding: widget.padding,
            itemBuilder: widget.itemBuilder,
            controller: _previewController,
          ),

          ///animated list view
          AnimatedList(
            key: widget.controller._listKey,
            controller: widget.controller.scrollController,
            itemBuilder:
                (BuildContext context, int index, Animation<double> animation) {
              Widget child = widget.itemBuilder(context, index, animation);
              return AnchorItemWrapper(
                index: index,
                controller: widget.controller.scrollController,
                child: child,
              );
            },
            initialItemCount: widget.controller._dataList.length,
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            primary: widget.primary,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            padding: widget.padding,
            clipBehavior: widget.clipBehavior,
          ),
        ],
      ),
    );
  }

  ///handle notification
  bool _handleNotification(ScrollNotification notification) {
    ///加载之前的消息，FormerMessages
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - widget.loadOffset) {
      _loadTailItems();
    }

    ///加载新的消息
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels <= widget.loadOffset) {
      _loadHeadItems();
    }

    ///通知消息被展示
    if (notification is ScrollEndNotification) {
      _notifyOnShow();
    }

    return false;
  }

  void _loadTailItems() {
    ///加载尾部数据
    widget.controller._listLock.synchronized(() async {
      ///check is tail end
      if (widget.controller.pageSizeCheck && widget.controller._isTailEnd) {
        return;
      }

      ///get former list
      T? former = widget.controller.dataList.lastOrNull;
      List<T> formerList = await widget.controller
          .tailDataProvider(former, widget.controller.pageCount);
      if (formerList.isEmpty) {
        return;
      }

      ///set tail end
      if (widget.controller.pageSizeCheck &&
          formerList.length < widget.controller.pageCount) {
        widget.controller._isTailEnd = true;
      }

      ///index
      int index = widget.controller._dataList.length;
      widget.controller._dataList.addAll(formerList);
      widget.controller._listKey.currentState?.insertAllItems(
        index,
        formerList.length,
        isAsync: true,
      );
    }).then((_) {
      setState(() {});
    });
  }

  ///加载头部数据
  void _loadHeadItems() {
    widget.controller._listLock.synchronized(() async {
      ///check is tail end
      if (widget.controller.pageSizeCheck && widget.controller._isHeadEnd) {
        return;
      }

      ///first or null
      T? former = widget.controller.dataList.firstOrNull;
      List<T> newerList = await widget.controller
          .headDataProvider(former, widget.controller.pageCount);
      if (newerList.isEmpty) {
        return;
      }

      ///set head end
      if (widget.controller.pageSizeCheck &&
          newerList.length < widget.controller.pageCount) {
        widget.controller._isHeadEnd = true;
      }

      ///calculate height
      widget.controller._dataList.insertAll(0, newerList);
      double height = await _previewController.previewItemsHeight(newerList);
      widget.controller._listKey.currentState?.insertAllItems(
        0,
        newerList.length,
        isAsync: true,
      );

      ///jump to next
      double jumpToOffset = widget.controller.scrollController.offset + height;

      ///ignore: invalid_use_of_protected_member
      widget.controller.scrollController.position.forcePixels(jumpToOffset);

      ///wait complete to complete
      WidgetsBinding.instance.addPostFrameCallback((data) {
        if (jumpToOffset >
            widget.controller.scrollController.position.maxScrollExtent) {
          widget.controller.scrollController.position.jumpTo(
            widget.controller.scrollController.position.maxScrollExtent,
          );
        }
      });
    }).then((_) {
      ///set state
      if (mounted) {
        setState(() {});
      }
    });
  }

  ///notify current on show
  void _notifyOnShow() {
    if (!mounted) {
      return;
    }

    ///is scrolling or not
    if (widget.controller.scrollController.isScrollingApproximate()) {
      return;
    }

    if (widget.onItemShow != null) {
      ///item show
      List<T> dataList = [];
      List<int> keys = [];

      ///keys
      for (int key in widget.controller.scrollController.itemMap.keys) {
        AnchorItemWrapperState? data =
            widget.controller.scrollController.itemMap[key];
        RenderBox? itemBox = data?.context.findRenderObject() as RenderBox?;
        Offset? offset = itemBox?.localToGlobal(const Offset(0.0, 0.0));
        if (offset == null || itemBox == null) {
          continue;
        }
        if ((offset.dy > 0 &&
                offset.dy + itemBox.size.height <
                    MediaQuery.of(context).size.height) ||
            offset.dy <= 0 &&
                offset.dy + itemBox.size.height >=
                    MediaQuery.of(context).size.height) {
          keys.add(key);
        }
      }

      ///keys data
      for (int s = 0; s < widget.controller._dataList.length; s++) {
        if (keys.contains(s)) {
          dataList.add(widget.controller._dataList[s]);
        }
      }
      widget.onItemShow!(dataList);
    }
  }

  ///clear and add new items
  void _clearAndAddNewItems(List<T> newItems) {
    // Step 1: Remove all existing items
    for (int i = widget.controller._dataList.length - 1; i >= 0; i--) {
      _removeItem(i);
    }
    // Step 2: Clear the data source
    widget.controller._dataList.clear();
    // Step 3: Add new items
    for (int i = 0; i < newItems.length; i++) {
      _insertItem(i, newItems[i]);
    }
  }

  ///remove item
  void _removeItem(int index) {
    widget.controller._listKey.currentState?.removeItem(
      index,
      (context, animation) {
        return widget.itemBuilder(context, index, animation);
      },
      duration: Duration.zero,
    );
  }

  ///insert item
  void _insertItem(int index, T item) {
    widget.controller._dataList.insert(index, item);
    widget.controller._listKey.currentState?.insertItem(
      index,
      duration: Duration.zero,
    );
  }

  ///jump to item not exists
  void _jumpToItemNotExists(T t) {
    ///加载尾部数据
    widget.controller._listLock.synchronized(() async {
      ///所有数据进行组装
      List<T> tailList = await widget.controller
          .tailDataProvider(t, widget.controller.pageCount);
      List<T> headList = await widget.controller
          .headDataProvider(t, widget.controller.pageCount);

      ///设置end
      if (widget.controller.pageSizeCheck &&
          headList.length < widget.controller.pageCount) {
        widget.controller._isHeadEnd = true;
      }

      ///设置end
      if (widget.controller.pageSizeCheck &&
          tailList.length < widget.controller.pageCount) {
        widget.controller._isTailEnd = true;
      }

      ///total data list
      List<T> totalDataList = [...headList, t, ...tailList];

      ///清理所有数据并重新加载
      _clearAndAddNewItems(totalDataList);

      ///ignore: invalid_use_of_protected_member
      widget.controller.scrollController.position.forcePixels(0);

      ///set state
      if (mounted) {
        setState(() {});
      }

      ///next frame
      Completer<bool> completer = Completer();
      WidgetsBinding.instance.addPostFrameCallback((data) {
        widget.controller.animateToItem(t);
        completer.complete(true);
      });
      await completer.future;
    });
  }
}
