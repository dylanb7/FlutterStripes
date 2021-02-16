import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stripes_app/Utility/TextStyles.dart';
import 'package:stripes_app/View/BaseView.dart';
import 'package:stripes_app/ViewModels/ExportModel.dart';
import 'package:stripes_app/ViewModels/UserData.dart';
import 'package:provider/provider.dart';

class Export extends StatelessWidget {
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return BaseView<ExportModel>(
      onModelReady: (model) {
        model.init(Provider.of<UserData>(context), context);
      },
      builder: (context, model, widget) {
        final bool isEmpty = model.listCsv.isEmpty;
        model.listCsv.forEach((element) {
          if (element.length > 10) element.removeLast();
        });
        return Padding(
          padding: EdgeInsets.only(top: 40.0, left: 15, right: 15),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Text(
                  "${model.currentName}'s data",
                  style: TextStyles.subHeader,
                ),
              ),
              Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Card(
                          elevation: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        "CSV",
                                        style: TextStyles.subHeader,
                                      )),
                                  IconButton(
                                    icon: Icon(Icons.send),
                                    onPressed: () {},
                                  )
                                ],
                              ),
                              isEmpty
                                  ? Text(
                                      "No data collected",
                                      style: TextStyles.subHeader,
                                    )
                                  : Expanded(
                                      child: Padding(padding: EdgeInsets.all(10),child: Container(
                                          child: GestureDetector(
                                              onTapUp: (details) =>
                                                  _transformationController
                                                      .toScene(details
                                                          .localPosition),
                                              child: InteractiveViewer(
                                                  alignPanAxis: true,
                                                  constrained: false,
                                                  transformationController:
                                                      _transformationController,
                                                  scaleEnabled: true,
                                                  boundaryMargin: EdgeInsets.all(8),
                                                  child: ClipRRect(
                                                      child: Table(
                                                    defaultColumnWidth:
                                                        FixedColumnWidth(100.0),
                                                    children: model.listCsv
                                                        .map((items) {
                                                      return TableRow(
                                                          children:
                                                              items.map((row) {
                                                        String val;
                                                        if (row != null ||
                                                            row != "null")
                                                          val = row.toString();
                                                        else
                                                          val = "N/A";
                                                        return Text(
                                                          val,
                                                          style: val.contains(
                                                                  "N/A")
                                                              ? TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .red)
                                                              : TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black),
                                                        );
                                                      }).toList());
                                                    }).toList(),
                                                  ))))))),
                            ],
                          )))),
            ],
          ),
        );
      },
    );
  }
}
