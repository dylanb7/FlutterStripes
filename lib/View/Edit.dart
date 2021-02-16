import 'dart:collection';
import 'dart:math';

import 'package:flushbar/flushbar_route.dart' as route;
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stripes_app/Enums/CurrentState.dart';
import 'package:stripes_app/Models/QuestionData.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/ViewModels/EditModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:provider/provider.dart';
import 'package:stripes_app/Widgets/ScreenOverlay.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import '../main.dart';
import 'BaseView.dart';

ScreenOverlayController overlayController;

final String editStatus = "editStatus";

final String editsSubmitted = "submitEdits";

class EditController extends PropertyChangeNotifier<String> {
  Stamped _edited;

  Map<String, String> _changes = Map();

  setEditing(Stamped edit) {
    this._edited = edit;
    notifyListeners(editStatus);
  }

  setChanges(Map<String, String> changes) {
    this._changes = changes;
  }

  submitEdits() {
    notifyListeners(editsSubmitted);
  }

  reset() {
    _changes = Map();
    _edited = null;
    notifyListeners(editStatus);
  }

  Map<String, String> get changes => _changes;

  Stamped get edited => _edited;

  bool get editing => _edited != null;
}

class Edit extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EditState();
  }
}

class _EditState extends State<Edit> {
  String typeValue = "All";

  EditModel model;

  bool Function(Stamped) typeFilter = (stamp) => true;

  bool Function(Stamped) dateFilter = (stamp) => true;

  DateTime startDate;

  DateTime endDate;

  final EditController editController = EditController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<EditModel>(onModelReady: (model) {
      model.init(Provider.of<UserData>(context), context);
    }, builder: (context, model, widget) {
      overlayController = ScreenOverlayController();
      this.model = model;
      editController.addListener(listener, [editsSubmitted]);
      final shown = List.of(model.stamps.reversed);

      DateTime start;
      DateTime end;
      bool hasData = model.allStamps.isNotEmpty;
      if (hasData) {
        start = DateTime.fromMillisecondsSinceEpoch(
            model.allStamps[model.allStamps.length - 1].stamp);
        end = DateTime.fromMillisecondsSinceEpoch(model.allStamps[0].stamp);
        startDate ??= start;
        endDate ??= end;
      }
      double datePickWidth = MediaQuery.of(context).size.width / 1.6;

      return model.state == CurrentState.Waiting
          ? Center(
              child: Container(
                  constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
                  child: CircularProgressIndicator()))
          : ScreenOverlay(
              PropertyChangeProvider<EditController>(
                  value: editController,
                  child: Padding(
                      padding: EdgeInsets.only(top: 40.0, left: 15, right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PropertyChangeConsumer<EditController>(
                            properties: [editStatus],
                            builder: (context, model, properties) {
                              return model.editing || !hasData
                                  ? Container()
                                  : Container(
                                      color: Colors.grey[300],
                                      height: 75,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Column(children: [
                                            SizedBox(
                                                width: datePickWidth,
                                                height: 35,
                                                child: DateTimePickerWidget(
                                                    startSelected,
                                                    start,
                                                    endDate,
                                                    startDate,
                                                    true)),
                                            SizedBox(
                                                width: datePickWidth,
                                                height: 33,
                                                child: DateTimePickerWidget(
                                                    endSelected,
                                                    startDate,
                                                    end,
                                                    endDate,
                                                    false)),
                                          ]),
                                          Padding(padding: EdgeInsets.only(right: 6), child: getDropdown(context, this.model)),
                                        ],
                                      ));
                            },
                          ),
                          shown.isEmpty
                              ? Center(
                                  child: Text(
                                    "No data",
                                    style: TextStyles.subHeader,
                                  ),
                                )
                              : PropertyChangeConsumer<EditController>(
                                  properties: [editStatus],
                                  builder: (context, model, properties) {
                                    return model.editing
                                        ? Center(
                                            child: StampedTile(
                                                model.edited, _delete))
                                        : Expanded(
                                            child: ListView.builder(
                                            itemBuilder:
                                                (BuildContext context, int i) {
                                              return Dismissible(
                                                  key: Key("${shown[i].stamp}"),
                                                  onDismissed: (direction) {
                                                    _delete(shown[i].stamp);
                                                  },
                                                  background: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                        color: Colors.red),
                                                    padding: EdgeInsets.all(5),
                                                  ),
                                                  child: StampedTile(
                                                      shown[i], _delete));
                                            },
                                            itemCount: shown.length,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                          ));
                                  })
                        ],
                      ))),
              overlayController);
    });
  }

  Widget getDropdown(BuildContext context, EditModel model) {
    List<String> values = [
      'All',
      DataType.symptom,
      "Lifestyle",
      DataType.test,
      DataType.bmi
    ];
    return DropdownButton<String>(
        value: typeValue,
        icon: Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        style: TextStyles.descriptor,
        underline: Container(
          height: 2,
          color: Theme.of(context).primaryColor,
        ),
        onChanged: (String newValue) {
          setState(() {
            typeValue = newValue;
            if (typeValue == "All")
              typeFilter = (stamped) => true;
            else if (typeValue == DataType.symptom)
              typeFilter = (stamped) => stamped is SymptomData;
            else if (typeValue == "Lifestyle")
              typeFilter = (stamped) => stamped is LifestyleData;
            else if (typeValue == DataType.bmi)
              typeFilter = (stamped) => stamped is BMIData;
            else
              typeFilter = (stamped) => stamped is TestData;
            model.setCondition(
                (stamp) => typeFilter(stamp) && dateFilter(stamp));
          });
        },
        items: values.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyles.subHeader,
            ),
          );
        }).toList(),
        selectedItemBuilder: (context) {
          return List.of(values.map((text) => Center(
                  child: Text(
                text,
                style: TextStyles.descriptor,
                textAlign: TextAlign.center,
              ))));
        });
  }

  startSelected(DateTime start) {
    setState(() {
      startDate = start;
      dateFilter = (stamped) =>
          stamped.stamp >= startDate.millisecondsSinceEpoch &&
          stamped.stamp <= endDate.millisecondsSinceEpoch;
      this
          .model
          .setCondition((stamp) => typeFilter(stamp) && dateFilter(stamp));
    });
  }

  endSelected(DateTime end) {
    setState(() {
      endDate = end;
      dateFilter = (stamped) =>
          stamped.stamp >= startDate.millisecondsSinceEpoch &&
          stamped.stamp <= endDate.millisecondsSinceEpoch;
      this
          .model
          .setCondition((stamp) => typeFilter(stamp) && dateFilter(stamp));
    });
  }

  listener() {
    final Stamped stamp = editController.edited;
    final Map<String, String> changes = editController.changes;
    editController.reset();
    _edit(stamp, changes);
  }

  _edit(Stamped stamped, Map<String, String> changes) async {
    if (!(await model.edit(stamped, changes)))
      showSnack(
          "Unable to edit data at ${getTimeString(stamped.stamp, context)}");
    else
      setState(() {});
  }

  _delete(int stamp) async {
    if (!(await model.delete(stamp))) {
      showSnack("Unable to delete data at ${getTimeString(stamp, context)}");
    } else {
      if (mounted) setState(() {});
    }
  }
}

class StampedTile extends StatefulWidget {
  final Stamped data;

  final Function(int time) delete;

  StampedTile(this.data, this.delete);

  @override
  State<StatefulWidget> createState() {
    return _StampedTileState();
  }
}

class _StampedTileState extends State<StampedTile> {
  String type;

  Editable displayed;

  @override
  void initState() {
    super.initState();
    if (widget.data is SymptomData) {
      this.type = DataType.symptom;
      this.displayed = SymptomWidget(widget.data);
    } else if (widget.data is LifestyleData) {
      this.type = DataType.lifestyle;
      this.displayed = LifestyleWidget(widget.data);
    } else if (widget.data is BMIData) {
      this.type = DataType.bmi;
      this.displayed = BMIWidget(widget.data);
    } else {
      this.type = DataType.test;
      this.displayed = TestWidget(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 1,
        child: Card(
          elevation: 3,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              actionsRow(type),
              Center(
                  child: Text(
                timeString(widget.data, context),
                style: TextStyles.descriptor,
              )),
              this.displayed
            ],
          ),
        ));
  }

  Widget actionsRow(String type) => SizedBox(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PropertyChangeConsumer<EditController>(
              properties: [editStatus],
              builder: (context, model, properties) {
                return model.editing
                    ? IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          model.reset();
                        })
                    : SizedBox(
                        width: 50,
                      );
              }),
          Text(
            type,
            style: TextStyles.subHeader,
          ),
          PropertyChangeConsumer<EditController>(
              properties: [editStatus],
              builder: (context, model, properties) {
                return IconButton(
                    icon: Icon(model.editing ? Icons.done : Icons.edit),
                    onPressed: () {
                      if (model.editing) {
                        model.setChanges(displayed.getFields());
                        model.submitEdits();
                      } else {
                        model.setEditing(widget.data);
                      }
                    });
              }),
        ],
      ));
}

mixin Editable on Widget {
  Map<String, String> getFields();
}

class SymptomWidget extends StatefulWidget with Editable {
  final SymptomData data;

  final Map<String, TextEditingController> fields = {
    "description": TextEditingController(),
    "responses": TextEditingController(),
  };

  SymptomWidget(this.data);

  @override
  State<StatefulWidget> createState() {
    return _SymptomWidgetState();
  }

  @override
  Map<String, String> getFields() {
    Map<String, String> trans =
        fields.map((key, value) => MapEntry(key, value.text));
    trans.removeWhere((key, value) => value.isEmpty);
    return trans;
  }
}

class _SymptomWidgetState extends State<SymptomWidget>
    with SingleTickerProviderStateMixin {
  TabController tabController;

  List<Response> responses = [];

  @override
  void initState() {
    responses = List.of(
        widget.data.responses.where((element) => element.question.id != "4"));
    super.initState();
    tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                height: 40,
                child: TabBar(
                  controller: tabController,
                  unselectedLabelColor: Colors.white70,
                  labelColor: Colors.white,
                  tabs: [
                    Tab(
                      text: "Description",
                    ),
                    Tab(
                      text: "Responses",
                    ),
                    Tab(
                      text: "Image",
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height: 200,
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: [description(), responsePage(), Text("Image")],
                  ))
            ]));
  }

  Widget description() => Padding(
      padding: EdgeInsets.only(top: 5),
      child: Column(children: [
        Text(
          "Symptom Type: \n${widget.data.type}",
          style: TextStyles.descriptor,
          textAlign: TextAlign.center,
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              "Description:",
              style: TextStyles.descriptor,
            )),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: PropertyChangeConsumer<EditController>(
                properties: [editStatus],
                builder: (context, model, properties) {
                  return model.editing
                      ? editingField(widget.fields["description"],
                          widget.data.description, 5)
                      : SingleChildScrollView(
                          child: Text(
                          widget.data.description,
                          style: TextStyles.descriptor,
                          maxLines: null,
                          textAlign: TextAlign.center,
                        ));
                })),
      ]));

  Widget responsePage() {
    final pageController =
        PageController(viewportFraction: 0.8, initialPage: 0, keepPage: true);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: PageView(
            controller: pageController,
            children: [
              ...List.generate(
                  responses.length,
                  (index) => Card(
                        color: Colors.grey[100],
                        elevation: 1,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      responses[index].question.text,
                                      style: TextStyles.descriptor,
                                      textAlign: TextAlign.center,
                                    )),
                                Spacer(),
                                Center(
                                    child: responses[index]
                                                .question
                                                .hasSeverity &&
                                            responses[index].severity != null
                                        ? PropertyChangeConsumer<
                                                EditController>(
                                            properties: [editStatus],
                                            builder:
                                                (context, model, properties) {
                                              return model.editing
                                                  ? SliderHolder((value) {
                                                      responses[index]
                                                          .severity = value;
                                                      serializeResponses();
                                                    },
                                                      responses[index].severity)
                                                  : Text(
                                                      "Severity: ${responses[index].severity}",
                                                      style:
                                                          TextStyles.descriptor,
                                                    );
                                            })
                                        : Container()),
                                /*responses[index].question.hasLocation
                                ? widget.editing
                                    ? editingField(
                                        controller,
                                        "Location: ${responses[index].location}",
                                        1)
                                    : Text(
                                        "Location: ${responses[index].location}",
                                        style: TextStyles.descriptor,
                                      )
                                : Container(),*/
                                Spacer(),
                                PropertyChangeConsumer<EditController>(
                                    properties: [editStatus],
                                    builder: (context, model, properties) {
                                      return model.editing
                                          ? _button("Remove", () {
                                              setState(() {
                                                pageController.jumpToPage(0);
                                                responses
                                                    .remove(responses[index]);
                                                serializeResponses();
                                              });
                                            }, context)
                                          : Container();
                                    }),
                              ],
                            )),
                      ))
            ],
          )),
          Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                  child: SizedBox(
                      height: 16,
                      child: SmoothPageIndicator(
                        count: responses.length,
                        axisDirection: Axis.horizontal,
                        effect: ColorTransitionEffect(
                            activeDotColor: Theme.of(context).primaryColor),
                        controller: pageController,
                      )))),
        ]);
  }

  void serializeResponses() {
    List<Response> averageBm = List.of(
        widget.data.responses.where((element) => element.question.id == "4"));
    if (averageBm.isEmpty) {
      widget.fields["responses"].text =
          SymptomSerializer().serializeResponses(responses);
    } else {
      List<Response> copy = List.of(responses);
      copy.add(averageBm[0]);
      widget.fields["responses"].text =
          SymptomSerializer().serializeResponses(copy);
    }
  }
}

class LifestyleWidget extends StatelessWidget with Editable {
  final LifestyleData lifestyleData;

  final List<TextEditingController> fields = List();

  LifestyleWidget(this.lifestyleData);

  @override
  Widget build(BuildContext context) {
    fields.clear();
    for (int _ = 0; _ < lifestyleData.description.length; _++)
      fields.add(TextEditingController());
    int index = 0;
    return Padding(
        padding: EdgeInsets.only(top: 10, left: 8, right: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lifestyle Type: \n${lifestyleData.type}",
                style: TextStyles.descriptor,
                textAlign: TextAlign.center,
              ),
              SingleChildScrollView(
                  child: Column(children: [
                ...lifestyleData.description
                    .map((text) => PropertyChangeConsumer<EditController>(
                        properties: [editStatus],
                        builder: (context, model, properties) {
                          return Padding(
                              padding: EdgeInsets.only(top: 25),
                              child: model.editing
                                  ? editingField(
                                      fields[index++],
                                      text,
                                      text.isEmpty
                                          ? 1
                                          : min(
                                              (text.length.ceilToDouble() / 30)
                                                  .ceil(),
                                              7))
                                  : Center(
                                      child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: TextStyles.descriptor,
                                    )));
                        }))
              ]))
            ]));
  }

  @override
  Map<String, String> getFields() {
    List<String> texts = List.of(fields.map((controller) => controller.text));
    for (int i = 0; i < texts.length; i++)
      if (texts[i].isEmpty) texts[i] = lifestyleData.description[i];
    return {"description": LifestyleSerializer().joined(texts)};
  }
}

class BMIWidget extends StatelessWidget with Editable {
  final BMIData bmiData;

  final LinkedHashMap<String, TextEditingController> fields = LinkedHashMap.of({
    "feet": TextEditingController(),
    "inches": TextEditingController(),
    "pounds": TextEditingController()
  });

  BMIWidget(this.bmiData);

  @override
  Widget build(BuildContext context) {
    List<int> bmi = [bmiData.feet, bmiData.inches, bmiData.pounds];
    int index = 0;
    return Padding(
        padding: EdgeInsets.only(top: 10, left: 8, right: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...fields.keys
                  .map((key) => PropertyChangeConsumer<EditController>(
                      properties: [editStatus],
                      builder: (context, model, properties) {
                        return Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: model.editing
                                ? bmiInput(
                                    fields[key], "$key: ${bmi[index++]}", index)
                                : Center(
                                    child: Text(
                                    "$key: ${bmi[index++]}",
                                    style: TextStyles.descriptor,
                                  )));
                      }))
            ]));
  }

  @override
  Map<String, String> getFields() {
    fields.removeWhere((key, value) => value.text.isEmpty);
    return fields.map((key, controller) => MapEntry(key, controller.text));
  }

  TextField bmiInput(
      TextEditingController controller, String hintText, int maxLength) {
    return TextField(
        controller: controller,
        maxLines: 1,
        minLines: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxLength),
          FilteringTextInputFormatter.digitsOnly
        ],
        decoration: InputDecoration(
          hintText: hintText,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(),
          ),
        ));
  }
}

class TestWidget extends StatelessWidget with Editable {
  final TestData testData;

  TestWidget(this.testData);

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Map<String, String> getFields() {
    return {};
  }
}

class SliderHolder extends StatefulWidget {
  final Function(double) onChanged;

  final double initialValue;

  SliderHolder(this.onChanged, this.initialValue);

  @override
  State<StatefulWidget> createState() {
    return _SliderHolderState();
  }
}

class _SliderHolderState extends State<SliderHolder> {
  double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: Text(
            "Initial value: ${widget.initialValue}",
            style: TextStyles.descriptor,
          )),
          SizedBox(
              height: 30,
              child: Slider(
                value: _value,
                onChanged: (value) {
                  setState(() {
                    _value = value;
                    widget.onChanged(_value);
                  });
                },
                label: _value.round().toString(),
                min: 1,
                max: 5,
                divisions: 4,
              ))
        ]);
  }
}

class DateTimePickerWidget extends StatefulWidget {
  final Function(DateTime) picked;

  final DateTime startDate;

  final DateTime endDate;

  final DateTime initial;

  final bool isStart;

  DateTimePickerWidget(
      this.picked, this.startDate, this.endDate, this.initial, this.isStart);

  @override
  State<StatefulWidget> createState() {
    return _DateTimePickerWidgetState();
  }
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime picked;

  @override
  void initState() {
    super.initState();
    picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: LayoutBuilder(builder: (context, constraint) {
        return RaisedButton(
            onPressed: () => _pickDate(context),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                constraint.biggest.width > 200
                    ? Text(
                        "${widget.isStart ? "Start" : "End"} date: ",
                        overflow: TextOverflow.clip,
                        style: TextStyles.descriptor,
                      )
                    : Container(),
                Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "${picked.month}/${picked.day}/${picked.year}",
                        overflow: TextOverflow.clip,
                        style: TextStyles.descriptor,
                      ),
                      Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.date_range,
                          )),
                    ]),
              ],
            ));
      }),
    );
  }

  _pickDate(BuildContext context) async {
    DateTime date = await showDatePicker(
        context: context,
        firstDate: widget.startDate,
        lastDate: widget.endDate,
        initialDate: picked);
    if (date != null)
      setState(() {
        date =
            widget.isStart ? date : date.add(Duration(hours: 23, minutes: 59));
        picked = date;
        widget.picked(date);
      });
  }
}

Widget editingField(
    TextEditingController controller, String hintText, int lines) {
  return TextField(
      cursorRadius: Radius.circular(5),
      controller: controller,
      maxLines: lines,
      minLines: lines,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: BorderSide(),
        ),
      ));
}

Widget _button(String text, Function onClick, BuildContext context) {
  return RaisedButton(
    child: Text(
      text,
      style: TextStyle(fontSize: 15, color: Colors.white),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    color: Theme.of(context).primaryColor,
    onPressed: () {
      onClick();
    },
  );
}

showSnack(String message) {
  final BuildContext context = Stripes.navigatorKey.currentContext;
  final Flushbar bar = Flushbar(
    messageText: Text(
      message,
      style: TextStyle(fontSize: 16, color: Colors.white70),
    ),
    backgroundColor: Colors.black54,
    duration: Duration(seconds: 4),
    flushbarStyle: FlushbarStyle.FLOATING,
    borderColor: Colors.white70,
    borderWidth: 2,
    borderRadius: 8,
    flushbarPosition: FlushbarPosition.TOP,
    margin: EdgeInsets.all(8),
  );
  final _route = route.showFlushbar(context: context, flushbar: bar);
  Navigator.of(context).push(_route);
}
