import 'dart:collection';

import 'package:flushbar/flushbar.dart';
import 'package:flushbar/flushbar_route.dart' as route;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/View/BaseView.dart';
import 'package:stripes_app/ViewModels/TestModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:stripes_app/Widgets/AddUserPopUp.dart';
import 'package:stripes_app/Widgets/DateTimePickerWidget.dart';
import 'package:stripes_app/Widgets/FourCornersWidget.dart';
import 'package:stripes_app/Widgets/MultiSelectChip.dart';
import 'package:stripes_app/Widgets/ScreenOverlay.dart';
import 'package:stripes_app/main.dart';

import 'SymptomRecorderPopup.dart';

ScreenOverlayController overlayController = ScreenOverlayController();

class Dashboard extends StatefulWidget {
  static GlobalKey<_DashboardState> dashboardKey = GlobalKey();

  const Dashboard(Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    overlayController = ScreenOverlayController();
    return ScreenOverlay(
        Center(
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 10), child: TopBar()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: RecordPanel()),
            ],
          ),
        ),
        overlayController);
  }

  submitAction(Stamped data) async {
    final bool res =
        await Provider.of<UserData>(context, listen: false).add(data);
    String type = "";
    if (data is SymptomData)
      type = DataType.symptom;
    else if (data is LifestyleData)
      type = DataType.lifestyle;
    else if (data is TestData)
      type = DataType.test;
    else
      type = DataType.bmi;
    DateTime stampedTime = DateTime.fromMillisecondsSinceEpoch(data.stamp);
    String timeString = TimeOfDay.fromDateTime(stampedTime)
        .format(Stripes.navigatorKey.currentContext);
    String dateString =
        "${stampedTime.month} - ${stampedTime.day} - ${stampedTime.year}";
    String notifier =
        "${res ? "Successfully" : "Failed to"} submitted $type data on $dateString at $timeString";
    showSnack(notifier);
  }

  addUser(User user) async {
    final bool res =
        await Provider.of<UserData>(context, listen: false).addUser(user);
    if (!res) showSnack("Failed to add user ${user.username}");
  }
}

class TopBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TopBarState();
  }
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.add,
            color: Colors.black54,
            size: 30,
          ),
          onPressed: () =>
              overlayController.setPopup(AddUserPopUp(overlayController)),
        ),
        Expanded(child: Consumer<UserData>(builder: (context, model, widget) {
          final List<String> values = List.of(model.getUsers(), growable: true);
          return values.isEmpty
              ? _addUserButton()
              : _getDropdown(values, model);
        })),
        IconButton(
          icon: Icon(
            Icons.edit,
            color: Colors.black54,
            size: 25,
          ),
          onPressed: () => {},
        )
      ],
    ));
  }

  Widget _addUserButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 3),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FlatButton(
          onPressed: () => setState(() {
                overlayController.setPopup(AddUserPopUp(overlayController));
              }),
          child: Center(
            child: Text(
              "Add a User",
              style: TextStyles.subHeader,
            ),
          )),
    );
  }

  Widget _getDropdown(List<String> values, UserData model) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54, width: 3),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
          isExpanded: true,
          value: model.currentUser,
          icon: Icon(Icons.arrow_drop_down),
          onChanged: (newValue) {
            setState(() {
              Provider.of<UserData>(context, listen: false).setUser(newValue);
            });
          },
          selectedItemBuilder: (context) {
            return values
                .map((value) => Center(
                      child: Text(
                        value,
                        style: TextStyles.subHeader,
                      ),
                    ))
                .toList(growable: false);
          },
          items: values.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Center(child: Text(value)),
            );
          }).toList(growable: false),
        ))));
  }
}

class RecordPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FourCornersWidget(
        PressableCardChild(
          SymptomRecorder(),
          topBar: Text(
            DataType.symptom,
            style: TextStyles.subHeader,
          ),
        ),
        PressableCardChild(LifestyleRecorder(),
            topBar: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  DataType.lifestyle,
                  style: TextStyles.subHeader,
                ))),
        PressableCardChild(
          TestRecorder(),
          topBar: Text(
            DataType.test,
            style: TextStyles.subHeader,
          ),
        ),
        PressableCardChild(
          BMIRecorder(),
          topBar: Text(
            DataType.bmi,
            style: TextStyles.subHeader,
          ),
        ));
  }
}

class SymptomRecorder extends StatelessWidget {
  static final AssetImage bmImage = AssetImage("assets/BM.png");
  static final AssetImage painImage = AssetImage("assets/Pain.png");
  static final AssetImage refluxImage = AssetImage("assets/Reflux.png");
  static final AssetImage otherImage = AssetImage("assets/Other.png");

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1,
          shrinkWrap: true,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          children: <Widget>[
            clickableStackedImage(bmImage, "BM", () => tapped(SymptomType.bm), context),
            clickableStackedImage(
                painImage, SymptomType.pain, () => tapped(SymptomType.pain), context),
            clickableStackedImage(refluxImage, SymptomType.reflux,
                () => tapped(SymptomType.reflux), context),
            clickableStackedImage(
                otherImage, SymptomType.other, () => tapped(SymptomType.other), context),
          ],
        ));
  }

  tapped(String type) {
    overlayController.setPopup(SymptomRecorderPopup(overlayController, type));
  }

  Widget clickableStackedImage(AssetImage image, String text, Function onTap, BuildContext context) {
    return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: <Widget>[
              Expanded(
                  child: FittedBox(
                      fit: BoxFit.fill,
                      child: ImageIcon(
                        image,
                        color: Theme.of(context).primaryColor,
                      ))),
              Text(
                text,
                style: TextStyles.descriptor,
              ),
            ],
          ),
        ));
  }
}

final String errorText = "Required Field";

bool validField(TextEditingController controller) {
  return controller.text.isNotEmpty;
}

class LifestyleRecorder extends StatefulWidget {
  final LinkedHashMap<String, Widget> conf = LinkedHashMap.of({
    LifestyleType.dietaryChange: DietaryChangeRecorder(),
    LifestyleType.medicalIntervention: MedicalInterventionRecorder(),
    LifestyleType.psychiatricHospitalization:
        PsychiatricHospitalizationRecorder(),
    LifestyleType.moved: MoveRecorder()
  });

  @override
  State<StatefulWidget> createState() {
    return _LifestyleRecorderState();
  }
}

class _LifestyleRecorderState extends State<LifestyleRecorder> {
  String value = LifestyleType.dietaryChange;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(mainAxisSize: MainAxisSize.min,
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Center(child: _getDropdown())),
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (widget, animation) {
                    return ScaleTransition(
                      child: widget,
                      scale: animation,
                    );
                  },
                  child: widget.conf[value],
                )),
            scrollDirection: Axis.vertical,
          ))
        ]));
  }

  Widget _getDropdown() {
    final keys = List.of(widget.conf.keys, growable: false);
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      style: TextStyles.descriptor,
      icon: Icon(Icons.arrow_drop_down),
      underline: Divider(
        height: 3,
        color: Colors.grey.shade700,
      ),
      onChanged: (newValue) {
        setState(() {
          value = newValue;
        });
      },
      items: keys
          .map<DropdownMenuItem<String>>((key) => DropdownMenuItem<String>(
                value: key,
                child: FittedBox(
                    fit: BoxFit.fill,
                    child: Text(
                      key,
                      style: TextStyles.descriptor,
                    )),
              ))
          .toList(),
    );
  }

  void selected(String newValue) {
    setState(() {
      value = newValue;
    });
  }
}

class DietaryChangeRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DietaryChangeRecorderState();
  }
}

class _DietaryChangeRecorderState extends State<DietaryChangeRecorder> {
  String currentSelection = "Added";
  TextEditingController dietaryField = TextEditingController();
  bool shouldUpdateText = false;

  final DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    dietaryField.addListener(() {
      if (shouldUpdateText)
        setState(() {
          shouldUpdateText = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
            child: MultiSelectChip(["Added", "Removed"], selected,
                initial: "Added")),
        TextField(
            decoration: InputDecoration(
                hintText: "Nutrient",
                errorStyle: TextStyles.textFieldError,
                errorText: shouldUpdateText ? errorText : null),
            style: TextStyles.textFieldNormal,
            controller: dietaryField),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Center(
                child: Text(
              "${currentSelection == "Added" ? "to" : "from"} diet",
              style: TextStyles.descriptor,
            ))),
        _button("Submit", (){
          _submitAction(context);
        }),
        Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: Text(
                "- at -",
                style: TextStyles.descriptor,
              ),
            )),
        DateTimePickerWidget(listener),
      ],
    );
  }

  void selected(String choice) {
    setState(() {
      currentSelection = choice;
    });
  }

  void _submitAction(BuildContext context) {
    if (validField(dietaryField)) {
      final String data =
          "$currentSelection ${dietaryField.text} ${currentSelection == "Added" ? "to" : "from"} diet";
      final change = LifestyleData(listener.combinedTime.millisecondsSinceEpoch,
          LifestyleType.dietaryChange, [data]);
      dietaryField.clear();
      context.findAncestorWidgetOfExactType<PressableCard>().shrinkAction();
      Dashboard.dashboardKey.currentState.submitAction(change);
    } else {
      setState(() {
        shouldUpdateText = true;
      });
    }
  }
}

class MedicalInterventionRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MedicalInterventionRecorderState();
  }
}

class _MedicalInterventionRecorderState
    extends State<MedicalInterventionRecorder> {
  final TextEditingController nameField = TextEditingController();
  final TextEditingController providerField = TextEditingController();

  bool shouldUpdateNameField = false;
  bool shouldUpdateProviderField = false;

  final DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    nameField.addListener(() {
      if (shouldUpdateNameField)
        setState(() {
          shouldUpdateNameField = false;
        });
    });
    providerField.addListener(() {
      if (shouldUpdateProviderField)
        setState(() {
          shouldUpdateProviderField = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
            decoration: InputDecoration(
              hintText: "Name",
              errorText: shouldUpdateNameField ? errorText : null,
              errorStyle: TextStyles.textFieldError,
            ),
            style: TextStyles.textFieldNormal,
            controller: nameField),
        TextField(
            decoration: InputDecoration(
                hintText: "Provider",
                errorText: shouldUpdateProviderField ? errorText : null,
                errorStyle: TextStyles.textFieldError),
            style: TextStyles.textFieldNormal,
            controller: providerField),
        _button("Submit", (){
          _submitAction(context);
        }),
        Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: Text(
                "- at -",
                style: TextStyles.descriptor,
              ),
            )),
        DateTimePickerWidget(listener),
      ],
    );
  }

  void _submitAction(BuildContext context) {
    final bool validName = validField(nameField);
    final bool validProvider = validField(providerField);
    if (validName && validProvider) {
      final change = LifestyleData(
          listener.combinedTime.millisecondsSinceEpoch,
          LifestyleType.medicalIntervention,
          [nameField.text, providerField.text]);
      nameField.clear();
      providerField.clear();
      context.findAncestorWidgetOfExactType<PressableCard>().shrinkAction();
      Dashboard.dashboardKey.currentState.submitAction(change);
    } else {
      if (!validName) {
        setState(() {
          shouldUpdateNameField = true;
        });
      }
      if (!validProvider) {
        setState(() {
          shouldUpdateProviderField = true;
        });
      }
    }
  }
}

class PsychiatricHospitalizationRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PsychiatricHospitalizationRecorderState();
  }
}

class _PsychiatricHospitalizationRecorderState
    extends State<PsychiatricHospitalizationRecorder> {
  final TextEditingController instituteField = TextEditingController();
  final TextEditingController reasonField = TextEditingController();

  bool shouldUpdateText = false;

  final DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    instituteField.addListener(() {
      if (shouldUpdateText)
        setState(() {
          shouldUpdateText = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
            decoration: InputDecoration(
              hintText: "Institute",
              errorText: shouldUpdateText ? errorText : null,
              errorStyle: TextStyles.textFieldError,
            ),
            style: TextStyles.textFieldNormal,
            controller: instituteField),
        TextField(
            decoration: InputDecoration(
              hintText: "Reason",
            ),
            keyboardType: TextInputType.text,
            maxLines: 4,
            controller: reasonField),
        _button("Submit", (){
          _submitAction(context);
        }),
        Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: Text(
                "- at -",
                style: TextStyles.descriptor,
              ),
            )),
        DateTimePickerWidget(listener),
      ],
    );
  }

  void _submitAction(BuildContext context) {
    if (validField(instituteField)) {
      final change = LifestyleData(
          listener.combinedTime.millisecondsSinceEpoch,
          LifestyleType.psychiatricHospitalization,
          [instituteField.text, reasonField.text]);
      instituteField.clear();
      reasonField.clear();
      context.findAncestorWidgetOfExactType<PressableCard>().shrinkAction();
      Dashboard.dashboardKey.currentState.submitAction(change);
    } else {
      setState(() {
        shouldUpdateText = true;
      });
    }
  }
}

class MoveRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MoveRecorderState();
  }
}

class _MoveRecorderState extends State<MoveRecorder> {
  final TextEditingController cityField = TextEditingController();
  final TextEditingController stateField = TextEditingController();
  final TextEditingController countryField = TextEditingController();

  bool shouldUpdateCity = false;
  bool shouldUpdateState = false;
  bool shouldUpdateCountry = false;

  final DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    cityField.addListener(() {
      if (shouldUpdateCity)
        setState(() {
          shouldUpdateCity = false;
        });
    });
    stateField.addListener(() {
      if (shouldUpdateState)
        setState(() {
          shouldUpdateState = false;
        });
    });
    countryField.addListener(() {
      if (shouldUpdateCountry)
        setState(() {
          shouldUpdateCountry = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
              hintText: "City",
              errorText: shouldUpdateCity ? errorText : null,
              errorStyle: TextStyles.textFieldError),
          style: TextStyles.textFieldNormal,
          controller: cityField,
        ),
        TextField(
          decoration: InputDecoration(
              hintText: "State/Province",
              errorText: shouldUpdateState ? errorText : null,
              errorStyle: TextStyles.textFieldError),
          style: TextStyles.textFieldNormal,
          controller: stateField,
        ),
        TextField(
          decoration: InputDecoration(
              hintText: "Country",
              errorText: shouldUpdateCountry ? errorText : null,
              errorStyle: TextStyles.textFieldError),
          style: TextStyles.textFieldNormal,
          controller: countryField,
        ),
        _button("Auto Fill", (){
          getLocation();
        }),
        _button("Submit", (){
          _submitAction(context);
        }),
        Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: Text(
                "- at -",
                style: TextStyles.descriptor,
              ),
            )),
        DateTimePickerWidget(listener),
      ],
    );
  }

  void _submitAction(BuildContext context) {
    final bool cityValid = validField(cityField);
    final bool stateValid = validField(stateField);
    final bool countryValid = validField(countryField);
    if (cityValid && stateValid && countryValid) {
      final change = LifestyleData(
          listener.combinedTime.millisecondsSinceEpoch,
          LifestyleType.moved,
          [cityField.text, stateField.text, countryField.text]);
      cityField.clear();
      stateField.clear();
      countryField.clear();
      context.findAncestorWidgetOfExactType<PressableCard>().shrinkAction();
      Dashboard.dashboardKey.currentState.submitAction(change);
    } else {
      if (!cityValid)
        setState(() {
          shouldUpdateCity = true;
        });
      if (!stateValid)
        setState(() {
          shouldUpdateState = true;
        });
      if (!countryValid)
        setState(() {
          shouldUpdateCountry = true;
        });
    }
  }

  getLocation() async {
    final GeolocationStatus status =
        await Geolocator().checkGeolocationPermissionStatus();
    if (status == GeolocationStatus.granted) {
      try {
        final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
        final position = await geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest);
        final List<Placemark> placemarks = await geolocator
            .placemarkFromCoordinates(position.latitude, position.longitude);
        final place = placemarks[0];
        setState(() {
          cityField.text = place.locality;
          stateField.text = place.administrativeArea;
          countryField.text = place.country;
        });
      } catch (e) {
        setState(() {
          cityField.text = "Failed";
        });
      }
    }
  }
}

class TestRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TestRecorderState();
  }
}

class _TestRecorderState extends State<TestRecorder> {
  double _sliderValue = 100;

  @override
  Widget build(BuildContext context) {
    return BaseView<TestModel>(onModelReady: (model) {
      model.init();
    }, builder: (context, model, widget) {
      final String state = model.currentState;
      return Padding(
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                        child: Text(
                      "Blue Dye Text",
                      style: TextStyle(
                          fontSize: 22, color: Colors.black54
                      ),
                    )),
                    ...(state == TestState.start
                        ? _start(model)
                        : state == TestState.finishedEating
                            ? _finishedEating(model)
                            : [])
                  ])));
    });
  }

  List<Widget> _start(TestModel model) {
    return [
      _button("About Blue Dye Test", (){

      }),
      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Center(
              child: Text(
        "After starting the test the smurf cake should be consumed immediately",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, color: Colors.black54,),
      ))),
      _button("Start Test", (){
        setState(() {
          model.startTest();
        });
      })
    ];
  }

  List<Widget> _finishedEating(TestModel model) {
    return [
      Text(""),
      Column(children: [
        Text(
          "Percent of smurf cake consumed",
          style: TextStyles.descriptor,
        ),
        Slider(
          value: _sliderValue,
          onChanged: (value) {
            setState(() {
              _sliderValue = value;
            });
          },
          label: "${_sliderValue.round().toString()}%",
          min: 1,
          max: 100,
          divisions: 99,
        ),
      ]),
      _button("Finished Eating", (){
        setState(() {
          model.finishedEating(_sliderValue);
        });
      }),
      _button("Cancel Test", (){
        setState(() {
          model.cancelTest();
        });
      })
    ];
  }
}

class BMIRecorder extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BMIRecorderState();
  }
}

class _BMIRecorderState extends State<BMIRecorder> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  String weightErrorText;

  String heightErrorText;

  final DateTimeListener listener = DateTimeListener();

  @override
  void initState() {
    super.initState();
    weightController.addListener(() {
      if (weightErrorText != null)
        setState(() {
          weightErrorText = null;
        });
    });
    heightController.addListener(() {
      if (heightErrorText != null)
        setState(() {
          heightErrorText = null;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Consumer<UserData>(builder: (context, dash, widget) {
          final List<BMIData> all = dash.get<BMIData>() ?? [];
          final BMIData first = all.isEmpty ? null : all.first;
          final String weightText = first == null
              ? "Weight(pounds)"
              : "Last Weight(pounds): ${first.pounds}";
          final String heightText = first == null
              ? "Height (feet,inches)"
              : "Last Height (ft,in): ${first.feet}'${first.inches}";
          return AspectRatio(
              aspectRatio: 1.18,
              child: IntrinsicHeight(
                  child: SingleChildScrollView(
                      child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                        hintText: weightText,
                        errorText: weightErrorText,
                        errorStyle: TextStyles.textFieldError),
                    controller: weightController,
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)
                    ],
                  ),
                  TextField(
                    decoration: InputDecoration(
                        hintText: heightText,
                        errorText: heightErrorText,
                        errorStyle: TextStyles.textFieldError),
                    controller: heightController,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                      LengthLimitingTextInputFormatter(4)
                    ],
                  ),
                  _button("Submit", () {
                    final BMIData res = validFields();
                    if (res != null) {
                      weightController.clear();
                      heightController.clear();
                      context
                          .findAncestorWidgetOfExactType<PressableCard>()
                          .shrinkAction();
                      Dashboard.dashboardKey.currentState.submitAction(res);
                    }
                  }),
                  Padding(
                      padding: EdgeInsets.all(4),
                      child: Center(
                        child: Text(
                          "- at -",
                          style: TextStyles.descriptor,
                        ),
                      )),
                  DateTimePickerWidget(listener),
                ],
              ))));
        }));
  }

  BMIData validFields() {
    final String height = heightController.text;
    final String weight = weightController.text;
    if (height.isEmpty || weight.isEmpty) {
      if (height.isEmpty)
        setState(() {
          heightErrorText = errorText;
        });
      if (weight.isEmpty)
        setState(() {
          weightErrorText = errorText;
        });
      return null;
    }
    List<String> res = height.split(',');
    if (res == null) {
      setState(() {
        heightErrorText = "Unable to parse height";
      });
      return null;
    }
    int feet;
    try {
      feet = int.parse(res[0]);
    } catch (e) {
      setState(() {
        heightErrorText = "Unable to parse feet";
      });
      return null;
    }
    int inches;
    try {
      inches = res.length == 1 ? 0 : int.parse(res[1]);
    } catch (e) {
      setState(() {
        heightErrorText = "Unable to parse inches";
      });
      return null;
    }
    int weightVal;
    try {
      weightVal = int.parse(weight);
    } catch (e) {
      setState(() {
        weightErrorText = "Unable to parse weight";
      });
      return null;
    }
    return BMIData(
        listener.combinedTime.millisecondsSinceEpoch, weightVal, feet, inches);
  }
}

Widget _button(String text, Function onClick) {
  return RaisedButton(
    child: Text(text, style: TextStyles.descriptor,),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    color: Colors.white,
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
