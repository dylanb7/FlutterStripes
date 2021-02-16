
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class FourCornersWidget extends StatefulWidget {
  final PressableCardChild first;
  final PressableCardChild second;
  final PressableCardChild third;
  final PressableCardChild fourth;

  FourCornersWidget(this.first, this.second, this.third, this.fourth);

  @override
  State<StatefulWidget> createState() {
    return _FourCornersWidgetState(first, second, third, fourth);
  }
}

class _FourCornersWidgetState extends State<FourCornersWidget>
    with SingleTickerProviderStateMixin {
  double flex;
  Animation<double> animation;
  AnimationController controller;
  List<PressableCard> plain;

  _FourCornersWidgetState(
      PressableCardChild first, PressableCardChild second, PressableCardChild third, PressableCardChild fourth) {
    plain = [
      PressableCard(
        first,
        pressAction: action,
        shrinkAction: shrinkAction,
      ),
      PressableCard(
        second,
        pressAction: action,
        shrinkAction: shrinkAction,
      ),
      PressableCard(
        third,
        pressAction: action,
        shrinkAction: shrinkAction,
      ),
      PressableCard(
        fourth,
        pressAction: action,
        shrinkAction: shrinkAction,
      )
    ];
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      reverseDuration: Duration(milliseconds: 300),
    );
    animation = Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutSine))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            //plain[isExpanded()].controller.expanded(true);
          });
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            for (int i = 0; i < plain.length; i++) {
              plain[i].controller.showing(true);
            }
            plain[isExpanded()].controller.expanded(false);
          });
        }
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1,
        child: Container(
            child: Stack(
          children: <Widget>[
            generateChild(plain[0], 0),
            generateChild(plain[1], 1),
            generateChild(plain[2], 2),
            generateChild(plain[3], 3),
          ],
        )));
  }

  Widget generateChild(PressableCard child, int index) {
    int expandedIndex = isExpanded();
    return AspectRatio(
        aspectRatio: 1,
        child: Align(
          alignment: Alignment(index.isOdd ? 1.0 : -1.0, index < 2 ? -1 : 1),
          child: FractionallySizedBox(
            widthFactor: computeWidthValue(index, expandedIndex),
            heightFactor: computeHeightValue(index, expandedIndex),
            child: child,
          ),
        ));
  }

  double computeWidthValue(int index, int expandedIndex) {
    final bool selected = index == expandedIndex;
    final double movingValue = selected ? animation.value : 1 - animation.value;
    return selected || (expandedIndex - index).abs() != 2
        ? movingValue
        : 1 - movingValue;
  }

  double computeHeightValue(int index, int expandedIndex) {
    final bool selected = index == expandedIndex;
    final double movingValue = selected ? animation.value : 1 - animation.value;
    return selected
        ? movingValue
        : !opposite(index, expandedIndex) && (expandedIndex - index).abs() != 2 ? 1 - movingValue : movingValue;
  }

  bool opposite(int index, int expandedIndex) {
    return index == 1 && expandedIndex == 2 ||
        index == 2 && expandedIndex == 1 ||
        index == 0 && expandedIndex == 3 ||
        index == 3 && expandedIndex == 0;
  }

  void action(PressableCard card) {
    if (isExpanded() != -1) {
      setState(() {
        runAnimation();
      });
    } else {
      setState(() {
        plain[plain.indexOf(card)].controller.expanded(true);
        final int expanded = isExpanded();
        for (int i = 0; i < plain.length; i++) {
          if (expanded != i) {
            plain[i].controller.showing(false);
          }
        }
        runAnimation();
      });
    }
  }

  void shrinkAction() {
    final int expanded = isExpanded();
    if (expanded != -1) action(plain[expanded]);
  }

  void runAnimation() {
    if (animation.status == AnimationStatus.completed)
      controller.reverse();
    else
      controller.forward();
  }

  int isExpanded() {
    for (int i = 0; i < plain.length; i++) {
      if (plain[i].controller.getExpanded) return i;
    }
    return -1;
  }
}

class PressableCard extends StatelessWidget {
  final PressableCardChild child;

  final Function(PressableCard) pressAction;

  final Function shrinkAction;

  final PressableCardController _controller = PressableCardController();

  PressableCard(this.child, {this.pressAction, this.shrinkAction});

  PressableCardController get controller => _controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PressableCardController>(
        create: (context) => _controller,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            color: Colors.white70,
            child: GestureDetector(
          onTap: () {
            pressAction(this);
          },
          child: Consumer<PressableCardController>(
            builder: (context, model, widget) {
              return model.getShowing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          Flexible(child: child.topBar),
                          model.getExpanded ? Icon(Icons.remove, color: Colors.black54,) : Icon(Icons.add, color: Colors.black54,),
                        ],
                      ), child.main])
                  : Container();
            },
          ),
          behavior: HitTestBehavior.opaque,
        )));
  }
}

class PressableCardChild {
  final Widget topBar;

  final Widget main;

  PressableCardChild(this.main, {this.topBar});
}

class PressableCardController extends ChangeNotifier {
  bool _isExpanded = false;

  bool _isShowing = true;

  bool get getShowing => _isShowing;

  bool get getExpanded => _isExpanded;

  void expanded(bool isExpanded) {
    _isExpanded = isExpanded;
    notifyListeners();
  }

  void showing(bool isShowing) {
    _isShowing = isShowing;
    notifyListeners();
  }

  void setAll(bool isShowing, bool isExpanded) {
    _isShowing = isShowing;
    _isExpanded = isExpanded;
    notifyListeners();
  }
}
