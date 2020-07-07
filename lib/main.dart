import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'debounce.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: HoverCircle(),
    ));
  }
}

class HoverCircle extends StatefulWidget {
  @override
  _HoverCircleState createState() => _HoverCircleState();
}

class _HoverCircleState extends State<HoverCircle> {
  bool _hasHover = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _hasHover ? Colors.red : Colors.grey,
        borderRadius: const BorderRadius.all(
          Radius.circular(25),
        ),
      ),
      child: Stack(
        overflow: Overflow.visible,
        children: [
          Positioned(
            left: -10,
            right: -10,
            top: -10,
            bottom: -10,
            child: ColoredBox(
              color: Colors.blue.withOpacity(0.25),
              child: OverflowingMouseRegion(
                onHover: (_) {
                  setState(() {
                    _hasHover = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hasHover = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OverflowingMouseRegion extends StatefulWidget {
  /// See [MouseRegion.onEnter]
  final PointerEnterEventListener onEnter;

  /// See [MouseRegion.onHover]
  final PointerHoverEventListener onHover;

  /// See [MouseRegion.onExit]
  final PointerExitEventListener onExit;

  final Widget child;

  const OverflowingMouseRegion({
    Key key,
    this.child,
    this.onEnter,
    this.onHover,
    this.onExit,
  }) : super(key: key);

  @override
  _OverflowingMouseRegionState createState() => _OverflowingMouseRegionState();
}

class _OverflowingMouseRegionState extends State<OverflowingMouseRegion> {
  OverlayEntry _helper;
  Rect _globalRect;
  void _updateHelper() {
    // Create an overlay that we can mouse region.

    _helper?.remove();
    _helper = OverlayEntry(
      maintainState: true,
      builder: (context) {
        return Positioned(
          left: _globalRect.left,
          top: _globalRect.top,
          width: _globalRect.width,
          height: _globalRect.height,
          child: MouseRegion(
            onEnter: widget.onEnter,
            onExit: widget.onExit,
            onHover: widget.onHover,
            child: SizedBox(),
          ),
        );
      },
    );

    Overlay.of(context).insert(_helper);
  }

  void _layoutChanged(Rect rect) {
    _globalRect = rect;
    debounce(_updateHelper);
  }

  @override
  void dispose() {
    cancelDebounce(_updateHelper);
    _helper?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutDetector(
      layoutChanged: _layoutChanged,
      child: widget.child,
    );
  }
}

typedef LayoutChangedCallback = void Function(Rect);

class LayoutDetector extends SingleChildRenderObjectWidget {
  final LayoutChangedCallback layoutChanged;

  const LayoutDetector({
    Widget child,
    this.layoutChanged,
    Key key,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLayoutDetector()..layoutChanged = layoutChanged;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderLayoutDetector renderObject) {
    renderObject..layoutChanged = layoutChanged;
  }
}

class _RenderLayoutDetector extends RenderProxyBox {
  Rect _layoutRect;
  LayoutChangedCallback _layoutChanged;
  LayoutChangedCallback get layoutChanged => _layoutChanged;
  set layoutChanged(LayoutChangedCallback value) {
    if (value == _layoutChanged) {
      return;
    }
    _layoutChanged = value;
    if (_layoutRect == null) {
      markNeedsPaint();
    } else {
      _layoutChanged?.call(_layoutRect);
    }
  }

  _RenderLayoutDetector({
    RenderBox child,
  }) : super(child);

  void _updateBounds() {
    var rect = localToGlobal(Offset.zero) & size;

    if (rect != _layoutRect) {
      _layoutRect = rect;
      _layoutChanged?.call(_layoutRect);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final layer = _LayoutDetectLayer(_updateBounds);
    context.pushLayer(layer, super.paint, offset);

    super.paint(context, offset);
  }
}


class _LayoutDetectLayer extends ContainerLayer {
  final void Function() addedToScene;

  _LayoutDetectLayer(this.addedToScene);
  @override
  void addToScene(SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    super.addToScene(builder, layerOffset);
    addedToScene();
  }
}
