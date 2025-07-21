import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';
import '../constants/models/device.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import 'device_management.dart';

class EditDeviceInfoDialog extends StatefulWidget {
  final DeviceModel deviceModel;

  EditDeviceInfoDialog({
    super.key,
    required this.deviceModel,
  });

  @override
  State<EditDeviceInfoDialog> createState() => _EditDeviceInfoDialogState();
}

class _EditDeviceInfoDialogState extends State<EditDeviceInfoDialog> {
  List<DeviceModel> deviceTypeList = [];
  DeviceModel? selectedDeviceType;

  String? selectedLivestockType;

  String? selectedDeviceNumber;
  List<String> deviceNumberList = [];

  bool sex = false;
  bool sex1 = false;

  bool isPoisinous = false;
  bool isAlive = false;

  TextEditingController _createdByController = TextEditingController();
  FocusNode createdByFocusNode = FocusNode();
  TextEditingController _currentStatusController = TextEditingController();
  FocusNode currentStatusFocusNode = FocusNode();
  TextEditingController _firmWareVController = TextEditingController();
  FocusNode firmWareVFocusNode = FocusNode();
  TextEditingController _hardWareVController = TextEditingController();
  FocusNode hardWareVFocusNode = FocusNode();

  TextEditingController _imeiController = TextEditingController();
  FocusNode imeiFocusNode = FocusNode();
  TextEditingController _batteryCapacityController = TextEditingController();
  FocusNode batteryCapacityFocusNode = FocusNode();
  TextEditingController _powerController = TextEditingController();
  FocusNode powerFocusNode = FocusNode();
  TextEditingController _longitudeController = TextEditingController();
  FocusNode longitudeFocusNode = FocusNode();
  TextEditingController _latitudeController = TextEditingController();
  FocusNode latitudeFocusNode = FocusNode();
  TextEditingController _speedController = TextEditingController();
  FocusNode speedFocusNode = FocusNode();
  TextEditingController _iccidController = TextEditingController();
  FocusNode iccidFocusNode = FocusNode();
  TextEditingController _accuracyStatusController = TextEditingController();
  FocusNode accuracyFocusNode = FocusNode();
  TextEditingController _gpsTimeController = TextEditingController();
  FocusNode gpsTimeFocusNode = FocusNode();
  TextEditingController _tempController = TextEditingController();
  FocusNode tempFocusNode = FocusNode();

  TextEditingController _humidityController = TextEditingController();
  FocusNode humidityFocusNode = FocusNode();
  TextEditingController _lastAvailableController = TextEditingController();
  FocusNode lastAvailableFocusNode = FocusNode();
  TextEditingController _notesController = TextEditingController();
  FocusNode notesFocusNode = FocusNode();
  TextEditingController _checkedByController = TextEditingController();
  FocusNode checkedByFocusNode = FocusNode();
  TextEditingController _attachedByController = TextEditingController();
  FocusNode attachedByFocusNode = FocusNode();

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
                                "Update Device Info",
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
                                          Row(
                                            children: [
                                              /*    Expanded(
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
                                                            _iccidController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .iccid;
                                                            _firmWareVController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .firmwareVersion;

                                                            _createdByController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .created_by
                                                                    .user_email;

                                                            _currentStatusController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .currentStatus;

                                                            _firmWareVController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .firmwareVersion;

                                                            _hardWareVController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .hardwareVersion;

                                                            _imeiController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .imei;

                                                            _batteryCapacityController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .batteryCapacity
                                                                    .toString();

                                                            _powerController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .pvPower
                                                                    .toString();

                                                            _longitudeController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .longitude;

                                                            _latitudeController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .latitude;

                                                            _speedController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .speed
                                                                    .toString();

                                                            _accuracyStatusController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .accuracy;

                                                            _gpsTimeController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .gpsTime;

                                                            _tempController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .temperature
                                                                    .toString();

                                                            _humidityController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .humidity
                                                                    .toString();

                                                            _lastAvailableController
                                                                    .text =
                                                                Constants
                                                                    .formatter
                                                                    .format(selectedDeviceType!
                                                                        .lastAvailable);

                                                            _notesController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .notes;

                                                            _checkedByController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .lastCheckedBy;

                                                            _attachedByController
                                                                    .text =
                                                                selectedDeviceType!
                                                                    .deviceAttachedBy;
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
                                              ),*/
                                            ],
                                          ),
                                          SizedBox(
                                            height: 24,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomInputTransparent1(
                                                    controller:
                                                        _iccidController,
                                                    hintText: "Iccid",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: iccidFocusNode,
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
                                              "Created By",
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
                                                        _createdByController,
                                                    hintText: "Created By",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        createdByFocusNode,
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
                                              "Last Checked By",
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
                                                        _checkedByController,
                                                    hintText: "Last Checked By",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        createdByFocusNode,
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
                                              "Device Attached By",
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
                                                        _attachedByController,
                                                    hintText: "Breed",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        attachedByFocusNode,
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
                                              "Current Status ",
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
                                                        _currentStatusController,
                                                    hintText: "Current Status",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        currentStatusFocusNode,
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
                                              "Firmware version",
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
                                                        _firmWareVController,
                                                    hintText:
                                                        "Firmware version",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        firmWareVFocusNode,
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
                                              "Hardware version",
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
                                                        _hardWareVController,
                                                    hintText:
                                                        "Hardware version",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        hardWareVFocusNode,
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
                                      height: 22,
                                    )
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
                                              "IMEII",
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
                                                    controller: _imeiController,
                                                    hintText: "imei",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: imeiFocusNode,
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
                                              "Iccid",
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
                                                        _iccidController,
                                                    hintText: "Iccid",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: iccidFocusNode,
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
                                      width: 12,
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
                                              "Battery Capacity",
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
                                                        _batteryCapacityController,
                                                    hintText:
                                                        "Battery Capacity",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        batteryCapacityFocusNode,
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
                                              "Temperature",
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
                                                    controller: _tempController,
                                                    hintText: "Temperature",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: tempFocusNode,
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
                                              "Humidity",
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
                                                        _humidityController,
                                                    hintText: "Humidity",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        humidityFocusNode,
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
                                      width: 12,
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
                                              "Pv Power",
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
                                                        _powerController,
                                                    hintText: "Pv Power",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: powerFocusNode,
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
                                      width: 12,
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
                                              "Speed",
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
                                                        _speedController,
                                                    hintText: "Speed",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: speedFocusNode,
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
                                              "Gps Time",
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
                                                        _gpsTimeController,
                                                    hintText: "Gps Time",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: gpsTimeFocusNode,
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
                                              "Last Available",
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
                                                        _lastAvailableController,
                                                    hintText: "Last Available",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        lastAvailableFocusNode,
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
                                      width: 12,
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
                                              "Accuracy",
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
                                                        _accuracyStatusController,
                                                    hintText: "Accuracy",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        accuracyFocusNode,
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
                                              "Notes",
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
                                                        _notesController,
                                                    hintText: "Notes",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode: notesFocusNode,
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
                                              "last Checked By",
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
                                                        _checkedByController,
                                                    hintText: "last Checked By",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        checkedByFocusNode,
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
                                      width: 12,
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
                                              "Device Attached By",
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
                                                        _attachedByController,
                                                    hintText:
                                                        "Device Attached By",
                                                    onChanged: (val) {
                                                      setState(() {});
                                                    },
                                                    onSubmitted: (val) {
                                                      setState(() {});
                                                    },
                                                    focusNode:
                                                        attachedByFocusNode,
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
    super.initState();

    _createdByController.text = widget.deviceModel.created_by.user_email;

    _currentStatusController.text = widget.deviceModel.currentStatus;

    _firmWareVController.text = widget.deviceModel.firmwareVersion;

    _hardWareVController.text = widget.deviceModel.hardwareVersion;
    _iccidController.text = widget.deviceModel.iccid;

    _imeiController.text = widget.deviceModel.imei;

    _batteryCapacityController.text =
        widget.deviceModel.batteryCapacity.toString();

    _powerController.text = widget.deviceModel.pvPower.toString();

    _longitudeController.text = widget.deviceModel.longitude;

    _latitudeController.text = widget.deviceModel.latitude;

    _speedController.text = widget.deviceModel.speed.toString();

    _accuracyStatusController.text = widget.deviceModel.accuracy;

    _gpsTimeController.text = widget.deviceModel.gpsTime;

    _tempController.text = widget.deviceModel.temperature.toString();

    _humidityController.text = widget.deviceModel.humidity.toString();

    _lastAvailableController.text =
        Constants.formatter.format(widget.deviceModel.lastAvailable);

    _notesController.text = widget.deviceModel.notes;

    _checkedByController.text = widget.deviceModel.lastCheckedBy;

    _attachedByController.text = widget.deviceModel.deviceAttachedBy;
  }
}
