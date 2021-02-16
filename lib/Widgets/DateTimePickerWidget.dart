import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Utility/TextStyles.dart';

class DateTimePickerWidget extends StatefulWidget {
  final DateTimeListener timeListener;

  final DateTime startDate;

  final DateTime endDate;

  final TimeOfDay startTime;

  final Duration earliestDateFromStart;

  DateTimePickerWidget(this.timeListener,
      {this.startDate,
      this.startTime,
      this.endDate,
      this.earliestDateFromStart});

  @override
  State<StatefulWidget> createState() {
    return _DateTimePickerWidgetState();
  }
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  final DateTime currentTime = DateTime.now();

  DateTime picked;

  DateTime lastPossible;

  TimeOfDay timeOfDay;

  @override
  void initState() {
    super.initState();
    picked = widget.startDate ?? currentTime;
    timeOfDay = widget.startTime ?? TimeOfDay.now();
    lastPossible = widget.endDate ?? currentTime;
    widget.timeListener.setDate(picked);
    widget.timeListener.setTime(timeOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: SingleChildScrollView(
          child: LayoutBuilder(builder: (context, constraint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            RaisedButton(
                onPressed: () => _pickDate(context),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IntrinsicWidth(
                        child: Row(children: [
                      Icon(
                        Icons.date_range,
                      ),
                      Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            "${picked.month} - ${picked.day} - ${picked.year}",
                            overflow: TextOverflow.clip,
                            style: TextStyles.descriptor,
                          )),
                    ])),
                    constraint.biggest.width > 200
                        ? Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              "Change",
                              overflow: TextOverflow.clip,
                              style: TextStyles.descriptor,
                            ))
                        : Container(),
                  ],
                )),
            SizedBox(
              height: 4,
            ),
            RaisedButton(
                onPressed: () => _pickTime(context),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IntrinsicWidth(
                        child: Row(children: [
                      Icon(
                        Icons.access_time,
                      ),
                      Flexible(
                          fit: FlexFit.loose,
                          child: Text(timeOfDay.format(context), style: TextStyles.descriptor,)),
                    ])),
                    constraint.biggest.width > 150
                        ? Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              "Change",
                              overflow: TextOverflow.clip,
                              style: TextStyles.descriptor,
                            ))
                        : Container(),
                  ],
                )),
          ],
        );
      })),
    );
  }

  _pickDate(BuildContext context) async {
    Duration earliestPossible =
        widget.earliestDateFromStart ?? Duration(days: 365);
    DateTime date = await showDatePicker(
        context: context,
        firstDate: picked.subtract(earliestPossible),
        lastDate: lastPossible,
        initialDate: picked);
    if (date != null)
      setState(() {
        picked = date;
        widget.timeListener.setDate(date);
      });
  }

  _pickTime(BuildContext context) async {
    TimeOfDay time =
        await showTimePicker(context: context, initialTime: timeOfDay);
    if (time != null)
      setState(() {
        timeOfDay = time;
        widget.timeListener.setTime(time);
      });
  }
}

class DateTimeListener {
  DateTime _date;
  TimeOfDay _time;

  setDate(DateTime date) => _date = date;

  setTime(TimeOfDay time) => _time = time;

  DateTime get combinedTime => (_date != null && _time != null) ?
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute) : DateTime.now();
}
