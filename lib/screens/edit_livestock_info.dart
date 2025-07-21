import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../models/livestock_model.dart';
import 'device_management.dart';

class EditInfoDialog extends StatefulWidget {
  final LivestockModel livestockModel;
  final List<String> livestockTypeList;
  EditInfoDialog(
      {super.key,
      required this.livestockModel,
      required this.livestockTypeList});

  @override
  State<EditInfoDialog> createState() => _EditInfoDialogState();
}

class _EditInfoDialogState extends State<EditInfoDialog> {
  List<DeviceModel> deviceTypeList = [];
  DeviceModel? selectedDeviceType;

  String? selectedLivestockType;

  String? selectedDeviceNumber;
  List<String> deviceNumberList = [];

  String? selectedSize;
  List<String> sizeList = [
    "50cm",
    "100cm",
    "150cm",
    "200cm",
    "250cm",
    "300cm",
    "400cm",
    "500cm",
    "600cm",
    "700cm",
    "800cm",
    "900cm",
    "1m"
  ];
  String? selectedWeight;
  List<String> weightList = [
    "20Kg",
    "30Kg",
    "50Kg",
    "60Kg",
    "70Kg",
    "80Kg",
    "90Kg",
    "100Kg",
    "150Kg",
    "200Kg",
    "300Kg",
    "400Kg",
    "500Kg",
    "600Kg",
    "800Kg",
    "1Ton"
  ];

  bool sex = false;
  bool sex1 = false;

  bool isPoisinous = false;
  bool isAlive = false;

  TextEditingController _livestockTypeNumberController =
      TextEditingController();
  FocusNode livestockTypeNumberFocusNode = FocusNode();
  TextEditingController _colorVariant1Controller = TextEditingController();
  FocusNode colorVariant1FocusNode = FocusNode();
  TextEditingController _colorVariant2Controller = TextEditingController();
  FocusNode colorVariant2FocusNode = FocusNode();
  TextEditingController _colorVariant3Controller = TextEditingController();
  FocusNode colorVariant3FocusNode = FocusNode();

  TextEditingController _nameController = TextEditingController();
  FocusNode nameFocusNode = FocusNode();
  TextEditingController _speciesController = TextEditingController();
  FocusNode speciesFocusNode = FocusNode();
  TextEditingController _breedController = TextEditingController();
  FocusNode breedFocusNode = FocusNode();
  TextEditingController _ageController = TextEditingController();
  FocusNode ageFocusNode = FocusNode();
  TextEditingController _weightController = TextEditingController();
  FocusNode weightFocusNode = FocusNode();
  TextEditingController _healthStatusController = TextEditingController();
  FocusNode healthStatusFocusNode = FocusNode();
  TextEditingController _vaccinationStatusController = TextEditingController();
  FocusNode vaccinationStatusFocusNode = FocusNode();
  TextEditingController _medicalHistoryController = TextEditingController();
  FocusNode medicalHistoryFocusNode = FocusNode();
  //TextEditingController _colorVariant3Controller = TextEditingController();
  //FocusNode colorVariant3FocusNode = FocusNode();

  Color colorVariant1 = Colors.white;
  Color colorVariant2 = Colors.white;
  Color colorVariant3 = Colors.white;

  Color getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'grey':
        return Colors.grey;
      case 'blue':
        return Colors.blue;
      case 'brown':
        return Colors.brown;
      // Add more colors as needed
      default:
        return Colors.white; // Default color if not found
    }
  }

  @override
  Widget build(BuildContext context) {
    // var device = deviceTypeList;
    return StatefulBuilder(
        builder: (context1, setState) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  //height: 380,
                  constraints: BoxConstraints(
                    minHeight: 200,
                    maxWidth: 900,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Constants.ctaColorGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 8,
                              ),
                              IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.arrow_back_sharp)),
                              Spacer(),
                              Text(
                                "Add Livestock",
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        child: CustomCard(
                          elevation: 5,
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Livestock Type",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            "Code will be generated automatically",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Constants.ctaTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    width: 120,
                                                    height: 45,
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(32)),
                                                    child: Center(
                                                      child: DropdownButton<
                                                          String>(
                                                        dropdownColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 12,
                                                                right: 12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        value:
                                                            selectedLivestockType,
                                                        isExpanded: true,
                                                        hint: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                            "Select Livestock Type ",
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 14),
                                                          ),
                                                        ),
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            selectedLivestockType =
                                                                newValue;
                                                            _livestockTypeNumberController
                                                                .text = (Random()
                                                                        .nextInt(
                                                                            899999999) +
                                                                    100000)
                                                                .toString();
                                                          });
                                                        },
                                                        selectedItemBuilder:
                                                            (BuildContext
                                                                context) {
                                                          return widget
                                                              .livestockTypeList
                                                              .map<Widget>(
                                                                  (item) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: item,
                                                              child: Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            8.0),
                                                                child: Text(
                                                                  item,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                        items: widget
                                                            .livestockTypeList
                                                            .map<
                                                                    DropdownMenuItem<
                                                                        String>>(
                                                                (value) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: value,
                                                            child: Text(value),
                                                          );
                                                        }).toList(),
                                                        underline: Container(),
                                                        // Uncomment if you want to add validation
                                                        // validator: (value) => value == null ? 'Device Type is required' : null,
                                                      ),
                                                    )),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _livestockTypeNumberController,
                                                    hintText:
                                                        "Livestock Number",
                                                    onChanged: (val) {},
                                                    onSubmitted: (val) {},
                                                    focusNode:
                                                        livestockTypeNumberFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Divider(
                                  thickness: 0.5,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Device Information",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            "Unique device information",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Constants.ctaTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          /*     Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    width: 120,
                                                    height: 45,
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(32)),
                                                    child: Center(
                                                      child: DropdownButton<
                                                          DeviceModel>(
                                                        dropdownColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 12,
                                                                right: 12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        value:
                                                            selectedDeviceType,
                                                        isExpanded: true,
                                                        hint: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                            "Select Device Type ",
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 14),
                                                          ),
                                                        ),
                                                        onChanged: (newValue) {
                                                          deviceNumberList = [];
                                                          setState(() {
                                                            selectedDeviceType =
                                                                newValue;

                                                            deviceNumberList.add(
                                                                selectedDeviceType!
                                                                    .iccid);
                                                          });
                                                        },
                                                        selectedItemBuilder:
                                                            (BuildContext
                                                                context) {
                                                          return deviceAvailable
                                                              .map<Widget>(
                                                                  (item) {
                                                            return DropdownMenuItem<
                                                                DeviceModel>(
                                                              value: item,
                                                              child: Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            8.0),
                                                                child: Text(
                                                                  item.deviceId,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                        items: deviceAvailable.map<
                                                                DropdownMenuItem<
                                                                    DeviceModel>>(
                                                            (DeviceModel
                                                                value) {
                                                          return DropdownMenuItem<
                                                              DeviceModel>(
                                                            value: value,
                                                            child: Text(
                                                                value.deviceId),
                                                          );
                                                        }).toList(),
                                                        underline: Container(),
                                                        // Uncomment if you want to add validation
                                                        // validator: (value) => value == null ? 'Device Type is required' : null,
                                                      ),
                                                    )),
                                              ),
                                            ],
                                          ),*/
                                          SizedBox(
                                            height: 24,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                    width: 120,
                                                    height: 45,
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(32)),
                                                    child: Center(
                                                      child: DropdownButton<
                                                          String>(
                                                        dropdownColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 12,
                                                                right: 12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        value:
                                                            selectedDeviceNumber,
                                                        isExpanded: true,
                                                        hint: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                            "Select Device iccid ",
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 14),
                                                          ),
                                                        ),
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            selectedDeviceNumber =
                                                                newValue;
                                                          });
                                                        },
                                                        selectedItemBuilder:
                                                            (BuildContext
                                                                context) {
                                                          return deviceNumberList
                                                              .map<Widget>(
                                                                  (item) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: item,
                                                              child: Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        left:
                                                                            8.0),
                                                                child: Text(
                                                                  item.toString(),
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                        items: deviceNumberList.map<
                                                                DropdownMenuItem<
                                                                    String>>(
                                                            (value) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: value,
                                                            child: Text(value
                                                                .toString()),
                                                          );
                                                        }).toList(),
                                                        underline: Container(),
                                                        // Uncomment if you want to add validation
                                                        // validator: (value) => value == null ? 'Device Type is required' : null,
                                                      ),
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Divider(
                                  thickness: 0.5,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "sex",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black),
                                    ),
                                    Expanded(child: Container()),
                                    Transform.scale(
                                      scaleX: 1.7,
                                      scaleY: 1.7,
                                      child: Checkbox(
                                          value: sex1,
                                          side: BorderSide(
                                              width: 1.2,
                                              color: Constants.ctaColorGreen),
                                          activeColor: Colors.blue,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(360)),
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              sex1 = newValue!;
                                            });
                                          }),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      "Female",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                    SizedBox(
                                      width: 40,
                                    ),
                                    Transform.scale(
                                      scaleX: 1.7,
                                      scaleY: 1.7,
                                      child: Checkbox(
                                          value: sex,
                                          side: BorderSide(
                                              width: 1.2,
                                              color: Constants.ctaColorGreen),
                                          activeColor: Colors.blue,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(360)),
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              sex = newValue!;
                                            });
                                          }),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      "Male",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Divider(
                                  thickness: 0.5,
                                  color: Colors.black54,
                                ),
                                SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Color Variants",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            "Colours for the animal",
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Constants.ctaTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: colorVariant1,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 16,
                                              ),
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _colorVariant1Controller,
                                                    hintText: "Color Variant 1",
                                                    onChanged: (val) {
                                                      colorVariant1 =
                                                          getColorFromString(
                                                              _colorVariant1Controller
                                                                  .text
                                                                  .toLowerCase());

                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      colorVariant1 =
                                                          getColorFromString(
                                                              _colorVariant1Controller
                                                                  .text
                                                                  .toLowerCase());

                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        colorVariant1FocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: colorVariant2,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 16,
                                              ),
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _colorVariant2Controller,
                                                    hintText: "Color Variant 2",
                                                    onChanged: (val) {
                                                      colorVariant2 =
                                                          getColorFromString(
                                                              _colorVariant2Controller
                                                                  .text
                                                                  .toLowerCase());
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      colorVariant1 =
                                                          getColorFromString(
                                                              _colorVariant2Controller
                                                                  .text
                                                                  .toLowerCase());
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        colorVariant2FocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: colorVariant3,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 16,
                                              ),
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _colorVariant3Controller,
                                                    hintText: "Color Variant 3",
                                                    onChanged: (val) {
                                                      colorVariant3 =
                                                          getColorFromString(
                                                              _colorVariant3Controller
                                                                  .text
                                                                  .toLowerCase());
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      colorVariant1 =
                                                          getColorFromString(
                                                              _colorVariant3Controller
                                                                  .text
                                                                  .toLowerCase());
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        colorVariant3FocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Name",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller: _nameController,
                                                    hintText: "Name",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: nameFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Species",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _speciesController,
                                                    hintText: "Species",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: speciesFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Breed",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _breedController,
                                                    hintText: "Breed",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: breedFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Age",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller: _ageController,
                                                    hintText: "Age",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: ageFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Weight",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _weightController,
                                                    hintText: "Weight",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: weightFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Health Status",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _healthStatusController,
                                                    hintText: "Health Status",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        healthStatusFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Vaccination Status",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _vaccinationStatusController,
                                                    hintText:
                                                        "Vaccination Status",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        vaccinationStatusFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8, bottom: 4),
                                            child: Text(
                                              "Medication History",
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _medicalHistoryController,
                                                    hintText:
                                                        "Medication History",
                                                    maxLines: 4,
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        medicalHistoryFocusNode,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    isPasswordField: false),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Transform.scale(
                                      scaleX: 1.7,
                                      scaleY: 1.7,
                                      child: Checkbox(
                                          value: isPoisinous,
                                          side: BorderSide(
                                              width: 1.2,
                                              color: Constants.ctaColorGreen),
                                          activeColor: Colors.blue,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(360)),
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              isPoisinous = newValue!;
                                            });
                                          }),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      "Is Poisonous",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                    SizedBox(
                                      width: 22,
                                    ),
                                    Transform.scale(
                                      scaleX: 1.7,
                                      scaleY: 1.7,
                                      child: Checkbox(
                                          value: isAlive,
                                          side: BorderSide(
                                              width: 1.2,
                                              color: Constants.ctaColorGreen),
                                          activeColor: Colors.blue,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(360)),
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              isAlive = newValue!;
                                            });
                                          }),
                                    ),
                                    SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      "Is Alive",
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                  minimumSize: Size(110, 50),
                                  side: BorderSide(
                                      width: 1.2,
                                      color: Constants.ctaColorGreen)),
                              child: Text(
                                "Go Back",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                  minimumSize: Size(110, 50),
                                  backgroundColor: Constants.ctaColorGreen,
                                  side: BorderSide(
                                      width: 1.2,
                                      color: Constants.ctaColorGreen)),
                              child: Text(
                                "Save Details",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ))),
            ));
  }

  @override
  void initState() {
    _livestockTypeNumberController.text = widget.livestockModel.device.iccid;
    _colorVariant1Controller.text = widget.livestockModel.color;
    selectedLivestockType = widget.livestockModel.species;
    _nameController.text = widget.livestockModel.name;
    _speciesController.text = widget.livestockModel.species;
    _breedController.text = widget.livestockModel.breed;
    _ageController.text = widget.livestockModel.age.toString();
    _weightController.text = widget.livestockModel.weight.toString();
    _healthStatusController.text = widget.livestockModel.healthStatus;
    _vaccinationStatusController.text = widget.livestockModel.vaccinationStatus;
    _medicalHistoryController.text = widget.livestockModel.medicalHistory;
    isAlive = widget.livestockModel.isAlive;
    isPoisinous = widget.livestockModel.isPoisonous;

    colorVariant1 =
        getColorFromString(widget.livestockModel.color.toLowerCase());
    super.initState();
  }
}
