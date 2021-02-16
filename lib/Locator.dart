import 'package:get_it/get_it.dart';
import 'package:stripes_app/ViewModels/EditModel.dart';
import 'package:stripes_app/ViewModels/ExportModel.dart';

import 'package:stripes_app/ViewModels/SymptomRecordModel.dart';
import 'package:stripes_app/ViewModels/TestModel.dart';

import 'ViewModels/UserData.dart';

GetIt locator = GetIt.asNewInstance();

void setUpLocator() {

  locator.registerFactory(() => UserData());
  locator.registerFactory(() => SymptomRecordModel());
  locator.registerFactory(() => TestModel());
  locator.registerFactory(() => ExportModel());
  locator.registerFactory(() => EditModel());

}