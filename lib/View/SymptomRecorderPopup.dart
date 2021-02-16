import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import 'package:stripes_app/Models/QuestionData.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/View/BaseView.dart';
import 'package:stripes_app/View/Dashboard.dart';
import 'package:stripes_app/ViewModels/SymptomRecordModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:stripes_app/Widgets/DateTimePickerWidget.dart';
import 'package:stripes_app/Widgets/PictureFetcherPopUp.dart';
import 'package:stripes_app/Widgets/ScreenOverlay.dart';

class SymptomRecorderPopup extends StatelessWidget {
  final ScreenOverlayController controller;

  final String type;

  SymptomRecorderPopup(this.controller, this.type);


  @override
  Widget build(BuildContext context) {
    return BaseView<SymptomRecordModel>(
        onModelReady: (model) => model.setType(type),
        builder: (context, model, widget) {
          return Center(
            child: FractionallySizedBox(
                widthFactor: 0.9,
                heightFactor: 0.9,
                child: Card(
                    elevation: 10,
                    child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Column(
                          children: <Widget>[
                            _topBar(),
                            Divider(
                              height: 3,
                              indent: 5,
                              endIndent: 5,
                              color: Colors.grey.shade700,
                            ),
                            model.onSubmit
                                ? SubmitView(controller)
                                : type == SymptomType.bm
                                    ? BMTypeSelection()
                                    : QuestionList(this.type),
                          ],
                        )))),
          );
        });
  }

  Widget _topBar() {
    return Row(children: <Widget>[
      Expanded(
          child: Center(
              child: Text(
        type,
        style: TextStyle(fontSize: 30),
      ))),
      Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              controller.setShowing(false);
            },
          )),
    ]);
  }
}

class SubmitView extends StatefulWidget {
  final ScreenOverlayController controller;

  SubmitView(this.controller);

  @override
  State<StatefulWidget> createState() {
    return _SubmitViewState();
  }
}

class _SubmitViewState extends State<SubmitView> {
  final TextEditingController description = TextEditingController();

  final PictureListener listener = PictureListener();

  int _numEntries = 1;

  bool get showsSpanSelection => _numEntries > 1;

  final DateTimeListener startTime = DateTimeListener();

  final DateTimeListener endTime = DateTimeListener();

  @override
  Widget build(BuildContext context) {
    final double dateAcceptorSize = MediaQuery.of(context).size.height / 6;
    return Expanded(
        child: SingleChildScrollView(
                padding: EdgeInsets.all(5),
                child: IntrinsicHeight(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                        elevation: 5,
                        child: Padding(
                            padding: EdgeInsets.all(5),
                            child: TextField(
                              maxLines: 3,
                              controller: description,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                  hintText: "Describe Your Experience"),
                            ))),
                    Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: RaisedButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          onPressed: () => {
                            showDialog(context: context, builder: (context){
                              return PictureFetcherPopUp(listener);
                            })
                          },
                          child: Text("Add Image"),
                        )),
                    Card(
                        elevation: 3,
                        child: IntrinsicHeight(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                              Center(child: Text("Occurrences: ")),
                              Padding(
                                  padding: EdgeInsets.only(left: 30, right: 30),
                                  child: NumberPicker.horizontal(
                                      initialValue: _numEntries,
                                      minValue: 1,
                                      maxValue: 60,
                                      listViewHeight: 50,
                                      highlightSelectedValue: true,
                                      step: 1,
                                      onChanged: (newValue) {
                                        setState(() {
                                          _numEntries = newValue;
                                        });
                                      })),
                              _numEntries != 1
                                  ? Column(children: [
                                      Text(
                                        "Date Symptom Started",
                                        style: TextStyles.descriptor,
                                      ),
                                      Container(
                                          height: dateAcceptorSize,
                                          child: DateTimePickerWidget(
                                            startTime,
                                            startDate: endTime.combinedTime
                                                .subtract(Duration(days: 7)),
                                            endDate: endTime.combinedTime,
                                          ))
                                    ])
                                  : Container(),
                            ]))),
                    Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onPressed: () => _submit(context),
                                child: Text("Submit Entry"),
                              ),
                              Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Center(
                                    child: Text(
                                      "- at -",
                                      style: TextStyles.descriptor,
                                    ),
                                  )),
                              Container(
                                  height: dateAcceptorSize,
                                  child: DateTimePickerWidget(endTime)),
                            ])),
                  ],
                ))));
  }

  void _submit(BuildContext context) {
    Provider.of<SymptomRecordModel>(context, listen: false).setDescription(description.text);
    List<SymptomData> retrieved =
        Provider.of<SymptomRecordModel>(context, listen: false)
            .submit(_numEntries, endTime.combinedTime, startTime.combinedTime);
    for (SymptomData data in retrieved)
      Dashboard.dashboardKey.currentState.submitAction(data);
    widget.controller.setShowing(false);
  }
}

class BMTypeSelection extends StatefulWidget {
  final LinkedHashMap<int, AssetImage> states = LinkedHashMap.of({
    1: AssetImage("assets/poop1.png"),
    2: AssetImage("assets/poop2.png"),
    3: AssetImage("assets/poop3.png"),
    4: AssetImage("assets/poop4.png"),
    5: AssetImage("assets/poop5.png"),
    6: AssetImage("assets/poop6.png"),
    7: AssetImage("assets/poop7.png"),
  });

  @override
  State<StatefulWidget> createState() {
    return _BMTypeSelectionState();
  }
}

class _BMTypeSelectionState extends State<BMTypeSelection> {
  double _currentValue = 1;

  bool typeSelected = false;

  @override
  Widget build(BuildContext context) {
    return typeSelected
        ? QuestionList(SymptomType.bm)
        : Expanded(
            child: SingleChildScrollView(child: IntrinsicHeight(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Text(
                "Rate 1-7 on bristol stool scale",
                style: TextStyle(fontSize: 14),
              )),
              Flexible(
                  fit: FlexFit.loose,
                  child: AspectRatio(
                      aspectRatio: 1.6,
                      child:
                          Image(image: widget.states[_currentValue.round()]))),
              Slider(
                value: _currentValue,
                onChanged: (value) {
                  setState(() {
                    _currentValue = value;
                  });
                },
                label: _currentValue.round().toString(),
                min: 1,
                max: 7,
                divisions: 6,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Text("<Hard"),
                Text("Slide to select"),
                Text("Watery>")
              ]),
              Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text("Continue"),
                    onPressed: () => submit(context),
                  )),
            ],
          ))));
  }

  void submit(BuildContext context) {
    Provider.of<SymptomRecordModel>(context, listen: false).addResponse(
        Response(
            Question("4", "Average BM type(1-7)", SymptomType.bm, true, false),
            severity: _currentValue));
    setState(() {
      typeSelected = true;
    });
  }
}

class QuestionList extends StatelessWidget {
  final String type;

  final RowHandler handler = RowHandler();

  QuestionList(this.type);

  @override
  Widget build(BuildContext context) {
    questionRows(context);
    return Expanded(
      child: ListView.separated(
          scrollDirection: Axis.vertical,
          itemCount: handler.rows.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return handler.rows[index];
          },
          separatorBuilder: (context, int) {
            return Divider(
              height: 4,
              indent: 25,
              endIndent: 25,
              color: Colors.grey.shade400,
            );
          }),
    );
  }

  questionRows(BuildContext context) {
    final double height = MediaQuery.of(context).size.height / 9;
    List<Question> forType = questionForType(type);
    List<Widget> rows = [];
    for (Question question in forType) {
      rows.add(SelectionRow(question, height));
    }
    if (type == SymptomType.other) rows.add(OtherAdditionRow(height));
    rows.add(ContinueRow(height));
    handler.addRows(rows);
  }

  callContinue(BuildContext context) {
    handler.logResponses(context);
    Provider.of<SymptomRecordModel>(context, listen: false).readyForSubmit();
  }
}

class RowHandler {
  List<Widget> _rows = [];

  List<Widget> get rows => _rows;

  addRows(List<Widget> newRows) {
    _rows.addAll(newRows);
  }

  logResponses(BuildContext context) {
    List<Response> responses = [];
    for (Widget row in _rows) {
      try {
        Collectable collectable = row as Collectable;
        Response res = collectable.collect();
        if (res != null) responses.add(res);
      } catch (e) {
        continue;
      }
    }
    Provider.of<SymptomRecordModel>(context, listen: false)
        .addResponses(responses);
  }
}

abstract class Collectable {
  Response collect();
}

class ContinueRow extends StatelessWidget with Collectable {
  final double height;

  ContinueRow(this.height);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        height: height,
        child: Center(
            child: Text(
          "Continue",
          style: TextStyles.subHeader,
        )),
      ),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context
            .findAncestorWidgetOfExactType<QuestionList>()
            .callContinue(context);
      },
    );
  }

  @override
  Response collect() {
    return null;
  }
}

class OtherAdditionRow extends StatefulWidget with Collectable {
  final double height;

  OtherAdditionRow(this.height);

  @override
  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }

  @override
  Response collect() {
    // TODO: implement collect
    throw UnimplementedError();
  }
}

class SelectionRow extends StatefulWidget with Collectable {
  final Question question;

  final double height;

  final SelectionRowListener listener = SelectionRowListener();

  SelectionRow(this.question, this.height);

  @override
  State<StatefulWidget> createState() {
    return _SelectionRowState(listener);
  }

  @override
  Response collect() {
    if (!listener.selected) return null;
    return Response(
      question,
      severity: listener.severity,
      location: listener.location,
    );
  }
}

class _SelectionRowState extends State<SelectionRow> {
  bool _isToggled = false;

  double _value = 3;

  final SelectionRowListener listener;

  _SelectionRowState(this.listener);

  @override
  Widget build(BuildContext context) {
    final double expandedHeight = widget.height * 1.5;
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _isToggled = !_isToggled;
            listener.setSelected(_isToggled);
          });
        },
        child: Container(
            height: shouldExpand() ? expandedHeight : widget.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                    height: widget.height,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Flexible(
                            child: Text(
                          widget.question.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        )),
                        _isToggled ? Icon(Icons.check) : Container()
                      ],
                    )),
                shouldExpand()
                    ? Container(
                        height: expandedHeight - widget.height,
                        child: Slider(
                          value: _value,
                          onChanged: (value) {
                            setState(() {
                              _value = value;
                              listener.setSeverity(_value);
                            });
                          },
                          label: _value.round().toString(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                        ),
                      )
                    : Container(),
              ],
            )));
  }

  bool shouldExpand() => _isToggled && widget.question.hasSeverity;
}

class SelectionRowListener {
  String _location;
  double _severity;
  bool _selected = false;

  String get location => _location;

  double get severity => _severity;

  bool get selected => _selected;

  setLocation(String location) => _location = location;

  setSeverity(double severity) => _severity = severity;

  setSelected(bool selected) => _selected = selected;
}
