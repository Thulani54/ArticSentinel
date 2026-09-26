import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artic_sentinel/models/device.dart';
import 'package:artic_sentinel/screens/device_alert_rules.dart';

Map<String,dynamic> payload({List<Map<String,dynamic>>? rules})=>{
 'revision':0,'metrics':[
 {'id':'gas_level','label':'Gas remaining','unit':'%','minimum':0,'maximum':100,'reset_margin':5,'boolean':false},
 {'id':'temp','label':'Temperature','unit':'°C','minimum':-100,'maximum':500,'reset_margin':.5,'boolean':false},
 {'id':'relay','label':'Relay','unit':'','minimum':0,'maximum':1,'reset_margin':.5,'boolean':true}],
 'rules':rules??[{'metric':'gas_level','comparison':'lte','thresholds':[50,30,10]}]};
void main(){
 testWidgets('custom percentage list is validated and saved on a narrow phone',(tester)async{
  tester.view.physicalSize=const Size(320,850);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  Map<String,dynamic>? saved;
  await tester.pumpWidget(MaterialApp(home:DeviceAlertRulesScreen(device:Device(id:7,name:'Kitchen gas',deviceId:'1133'),loadRules:()async=>payload(),saveRules:(data)async{saved=data;return {...payload(),...data,'revision':1};})));
  await tester.pumpAndSettle();expect(tester.takeException(),isNull);
  await tester.enterText(find.byType(TextFormField),'101, 30');
  await tester.tap(find.text('Save my alerts'));await tester.pumpAndSettle();expect(saved,isNull);
  await tester.enterText(find.byType(TextFormField),'75, 40, 15');
  await tester.tap(find.text('Save my alerts'));await tester.pumpAndSettle();
  expect(((saved!['rules'] as List).single as Map)['thresholds'],[75.0,40.0,15.0]);expect(tester.takeException(),isNull);
 });
 testWidgets('removing all conditions saves an empty list to disable personal alerts',(tester)async{
  Map<String,dynamic>? saved;
  await tester.pumpWidget(MaterialApp(home:DeviceAlertRulesScreen(device:Device(id:7,name:'Gas',deviceId:'1133'),loadRules:()async=>payload(),saveRules:(data)async{saved=data;return {...payload(),...data,'revision':1};})));
  await tester.pumpAndSettle();await tester.tap(find.text('Remove'));await tester.pumpAndSettle();
  await tester.tap(find.text('Save my alerts'));await tester.pumpAndSettle();expect(saved!['rules'],isEmpty);expect(tester.takeException(),isNull);
 });
 testWidgets('temperature rule retains signed thresholds and above comparison',(tester)async{
  Map<String,dynamic>? saved;
  await tester.pumpWidget(MaterialApp(home:DeviceAlertRulesScreen(device:Device(id:8,name:'Freezer',deviceId:'cold'),loadRules:()async=>payload(rules:[{'metric':'temp','comparison':'gte','thresholds':[-18]}]),saveRules:(data)async{saved=data;return {...payload(),...data,'revision':1};})));
  await tester.pumpAndSettle();await tester.tap(find.text('Save my alerts'));await tester.pumpAndSettle();
  expect((saved!['rules'] as List).single,{'metric':'temp','comparison':'gte','thresholds':[-18.0]});
 });
}
