import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:artic_sentinel/screens/dashboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../custom_widgets/date_picker.dart';
import '../models/client.dart';
import '../models/province.dart';
import '../services/authentication.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Business Info---------------------------------
  late html.File selected_file_hml;
  late html.File selected_file_hml1;
  late io.File selected_file_io;

  String imageName = "";
  File? _image;
  Uint8List? imageBytes;

  TextEditingController _businessNameController = TextEditingController();
  FocusNode businessNameFocusNode = FocusNode();
  TextEditingController _countryController = TextEditingController();
  FocusNode countryFocusNode = FocusNode();
  TextEditingController _businessTypeController = TextEditingController();
  FocusNode businessTypeFocusNode = FocusNode();
  TextEditingController _businessDescriptionController =
      TextEditingController();
  FocusNode businessDescriptionFocusNode = FocusNode();
  TextEditingController _ownerNameController = TextEditingController();
  FocusNode ownerNameFocusNode = FocusNode();
  TextEditingController _roleController = TextEditingController();
  FocusNode roleDescriptionFocusNode = FocusNode();

  TextEditingController _businessEmailController = TextEditingController();
  FocusNode businessEmailFocusNode = FocusNode();
  TextEditingController _businessContactNumberController =
      TextEditingController();
  FocusNode businessContactNumberFocusNode = FocusNode();
  TextEditingController _address1Controller = TextEditingController();
  FocusNode address1FocusNode = FocusNode();
  TextEditingController _address2Controller = TextEditingController();
  FocusNode address2FocusNode = FocusNode();
  TextEditingController _cityController = TextEditingController();
  FocusNode cityFocusNode = FocusNode();
  TextEditingController _postalCodeController = TextEditingController();
  FocusNode postalCodeFocusNode = FocusNode();
  TextEditingController _vatNumberController = TextEditingController();
  FocusNode vatNumberFocusNode = FocusNode();
  TextEditingController _websiteController = TextEditingController();
  FocusNode websiteFocusNode = FocusNode();
  TextEditingController _registrationNumberController = TextEditingController();
  FocusNode registrationNumberFocusNode = FocusNode();
  TextEditingController _registrationDateController = TextEditingController();
  FocusNode registrationDateFocusNode = FocusNode();

  //Primary Contact Info-------------
  TextEditingController _firstNameController = TextEditingController();
  FocusNode firstNameFocusNode = FocusNode();
  TextEditingController _lastNameController = TextEditingController();
  FocusNode lastNameFocusNode = FocusNode();
  TextEditingController _primaryContactEmailController =
      TextEditingController();
  FocusNode primaryContactEmailFocusNode = FocusNode();
  TextEditingController _primaryContactNumberController =
      TextEditingController();
  FocusNode primaryContactNumberFocusNode = FocusNode();
  TextEditingController _nationalityController = TextEditingController();
  FocusNode nationalityFocusNode = FocusNode();
  TextEditingController _userIDController = TextEditingController();
  FocusNode userIdFocusNode = FocusNode();
  //TextEditingController _roleController = TextEditingController();
  //FocusNode roleFocusNode = FocusNode();

  //Secondary Contact Info-------------
  TextEditingController _passwordController = TextEditingController();
  FocusNode passwordFocusNode = FocusNode();
  TextEditingController _confirmPasswordController = TextEditingController();
  FocusNode confirmPasswordFocusNode = FocusNode();
  TextEditingController _secondaryEmailController = TextEditingController();
  FocusNode secondaryEmailFocusNode = FocusNode();

  //Authentication  Info-------------
  TextEditingController _secondaryContactFirstNameController =
      TextEditingController();
  FocusNode secondaryContactFirstNameFocusNode = FocusNode();
  TextEditingController _secondaryContactLastNameController =
      TextEditingController();
  FocusNode secondaryContactLastNameFocusNode = FocusNode();
  TextEditingController _secondaryContactNameController =
      TextEditingController();
  FocusNode secondaryContactNameFocusNode = FocusNode();
  TextEditingController _secondaryContactNumberController =
      TextEditingController();
  FocusNode secondaryContactNumberFocusNode = FocusNode();

  List<Province> provinceList = [];
  Province? selectedProvince;
  String? selectedGender;
  List<String> genderList = ["Male", "Female", "Other"];
  int businessIndex = 0;

  var uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomCard(
              elevation: 5,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 550,
                height: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                constraints: BoxConstraints(
                  maxWidth: 600,
                ),
                //padding: EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: businessIndex == 0
                      ? Column(
                          children: [
                            SizedBox(
                              height: 24,
                            ),
                            Text(
                              "Artic Sentinel.",
                              style: GoogleFonts.lato(
                                fontSize: 30,
                                color: Constants.ctaColorGreen,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              "Create Business",
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Business Information",
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              thickness: 0.5,
                              color: Colors.black54,
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Business Name",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _businessNameController,
                                          hintText: "Business Name",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: businessNameFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Owner Name",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _ownerNameController,
                                          hintText: "Owner Name",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: ownerNameFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Industry Type",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _businessTypeController,
                                          hintText: "Industry Type",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: businessTypeFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Business Description",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller:
                                              _businessDescriptionController,
                                          hintText: "Business Description",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode:
                                              businessDescriptionFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 4),
                                        child: Text(
                                          "Role",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomInputTransparent1(
                                                controller: _roleController,
                                                hintText: "Role",
                                                onChanged: (val) {},
                                                onSubmitted: (val) {},
                                                focusNode:
                                                    roleDescriptionFocusNode,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 8),
                                        child: Text(
                                          "Business Logo",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: imageBytes != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.memory(
                                                      imageBytes!,
                                                      height: 45,
                                                      width: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Icon(
                                                    Iconsax.image,
                                                    size: 40,
                                                    color: Colors.black,
                                                  ),
                                          ),
                                          SizedBox(
                                            width: 16,
                                          ),
                                          TextButton.icon(
                                            onPressed: () async {
                                              FilePickerResult? result =
                                                  await FilePicker.platform
                                                      .pickFiles(
                                                allowMultiple: false,
                                                type: FileType.image,
                                              );

                                              if (result != null &&
                                                  result.files.isNotEmpty) {
                                                // Use the file path
                                                imageBytes =
                                                    result.files.first.bytes;
                                                setState(() {});

                                                if (imageBytes != null) {
                                                  String fileName =
                                                      result.files.first.name;
                                                  imageName =
                                                      result.files.first.name;
                                                  //print("Selected file path: $imageBytes");

                                                  //_imageURLController.text = filePath;
                                                  if (kDebugMode) {
                                                    print(
                                                        "Selected file name: $fileName");
                                                  }
                                                } else {
                                                  if (kDebugMode) {
                                                    print(
                                                        "Error: File path is null.");
                                                  }
                                                }
                                              } else {
                                                if (kDebugMode) {
                                                  print(
                                                      "No file was selected.");
                                                }
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                                side: BorderSide(
                                                    color:
                                                        Constants.ctaColorGreen,
                                                    width: 1.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          360),
                                                ),
                                                minimumSize: Size(90, 50)),
                                            icon: Icon(
                                              Iconsax.document_upload,
                                              color: Colors.black,
                                            ),
                                            label: Center(
                                              child: Text(
                                                "Upload",
                                                style: GoogleFonts.inter(
                                                  textStyle: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black,
                                                      letterSpacing: 0,
                                                      fontWeight:
                                                          FontWeight.normal),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 4),
                                        child: Text(
                                          "Website",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomInputTransparent1(
                                                controller: _websiteController,
                                                hintText: "website",
                                                onChanged: (val) {},
                                                onSubmitted: (val) {},
                                                focusNode: websiteFocusNode,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 8),
                                        child: Text(
                                          "Registration Date",
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomDatePicker(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Country",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _countryController,
                                          hintText: "Country",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: countryFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Business Email",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _businessEmailController,
                                          hintText: "Business Email",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: businessEmailFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Business Contact Number",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller:
                                              _businessContactNumberController,
                                          hintText: "Business Contact Number",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode:
                                              businessContactNumberFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Address Line 1",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _address1Controller,
                                          hintText: "Address Line 1",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: address1FocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Address Line 2",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _address2Controller,
                                          hintText: "Address Line 2",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: address2FocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "City",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _cityController,
                                          hintText: "City",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: cityFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Province",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                          width: 120,
                                          height: 45,
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(360)),
                                          child: Center(
                                            child: DropdownButton<Province>(
                                              dropdownColor: Colors.white,
                                              padding: EdgeInsets.only(
                                                  left: 12, right: 12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              value:
                                                  selectedProvince, // Use selectedIndustry (of type Industry?)
                                              isExpanded: true,
                                              hint: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  "Select Province",
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14),
                                                ),
                                              ),
                                              onChanged: (Province? newValue) {
                                                setState(() {
                                                  selectedProvince = newValue;
                                                  //regionList = regionList.where((item) => newValue?.id == item.provinceId).toList();
                                                });
                                              },
                                              selectedItemBuilder:
                                                  (BuildContext ctxt) {
                                                return provinceList
                                                    .map<Widget>((item) {
                                                  return DropdownMenuItem<
                                                      Province>(
                                                    child: Container(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 8.0),
                                                        child: Text(
                                                          "${item.name}", // Assuming item is of type Industry
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ),
                                                    ),
                                                    value: item,
                                                  );
                                                }).toList();
                                              },
                                              items: provinceList.map<
                                                      DropdownMenuItem<
                                                          Province>>(
                                                  (Province value) {
                                                return DropdownMenuItem<
                                                    Province>(
                                                  value: value,
                                                  child: Text(value.name),
                                                );
                                              }).toList(),
                                              underline: Container(),
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Postal Code",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _postalCodeController,
                                          hintText: "Postal Code",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: postalCodeFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "VAT Number",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller: _vatNumberController,
                                          hintText: "VAT Number",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode: vatNumberFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    "Registration Number",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomInputTransparent1(
                                          controller:
                                              _registrationNumberController,
                                          hintText: "Registration Number",
                                          onChanged: (val) {},
                                          onSubmitted: (val) {},
                                          focusNode:
                                              registrationNumberFocusNode,
                                          textInputAction: TextInputAction.next,
                                          isPasswordField: false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LoginPage()),
                                    );

                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(200, 50),
                                      side: BorderSide(
                                        width: 1.0,
                                        color: Constants.ctaColorGreen,
                                      ),
                                      backgroundColor: Constants
                                          .ctaColorGreen // Background color
                                      ),
                                  child: Text(
                                    'Back',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (_businessNameController.text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the business name"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_ownerNameController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the ownership name"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_businessEmailController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter business email"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_businessContactNumberController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter business contact number"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_address1Controller
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter address 1"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_address2Controller
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter address 2"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_cityController.text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the city"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (selectedProvince == null) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the province"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_postalCodeController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the postal code"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_countryController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the country"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_websiteController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the website"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (Constants.datePickerValue ==
                                        "") {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the registration date"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_registrationNumberController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the registration number"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_vatNumberController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the vat number"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (Constants.datePickerValue ==
                                        "") {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the registration date"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_registrationNumberController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the registration number"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_vatNumberController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter the vat number"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (imageName == "") {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description:
                                            Text("Please enter upload logo"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_businessTypeController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the business type"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else if (_businessDescriptionController
                                        .text.isEmpty) {
                                      MotionToast.error(
                                        title: Text("Error"),
                                        description: Text(
                                            "Please enter the description"),
                                        layoutOrientation: TextDirection.rtl,
                                        animationType: AnimationType.fromTop,
                                        width: 400,
                                        height: 55,
                                        animationDuration: const Duration(
                                          milliseconds: 2500,
                                        ),
                                      ).show(context);
                                    } else {
                                      businessIndex = 1;
                                    }

                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                      minimumSize: Size(200, 50),
                                      side: BorderSide(
                                        width: 1.0,
                                        color: Constants.ctaColorGreen,
                                      ),
                                      backgroundColor:
                                          Colors.transparent // Background color
                                      ),
                                  child: Text(
                                    'Next',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],
                        )
                      : businessIndex == 1
                          ? Column(
                              children: [
                                SizedBox(
                                  height: 24,
                                ),
                                Text(
                                  "Artic Sentinel.",
                                  style: GoogleFonts.lato(
                                    fontSize: 30,
                                    color: Constants.ctaColorGreen,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  "Create Business",
                                  style: GoogleFonts.inter(
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Primary Contact Information",
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.normal),
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                  thickness: 0.5,
                                  color: Colors.black54,
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "First Name",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller: _firstNameController,
                                              hintText: "First Name",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode: firstNameFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Last Name",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller: _lastNameController,
                                              hintText: "Last Name",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode: lastNameFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Gender",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
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
                                                      BorderRadius.circular(
                                                          360)),
                                              child: Center(
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  padding: EdgeInsets.only(
                                                      left: 12, right: 12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  value:
                                                      selectedGender, // Use selectedIndustry (of type Industry?)
                                                  isExpanded: true,
                                                  hint: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(
                                                      "Select Gender",
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      selectedGender = newValue;
                                                      //regionList = regionList.where((item) => newValue?.id == item.provinceId).toList();
                                                    });
                                                  },
                                                  selectedItemBuilder:
                                                      (BuildContext ctxt) {
                                                    return genderList
                                                        .map<Widget>((item) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        child: Container(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 8.0),
                                                            child: Text(
                                                              "${item}", // Assuming item is of type Industry
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                          ),
                                                        ),
                                                        value: item,
                                                      );
                                                    }).toList();
                                                  },
                                                  items: genderList.map<
                                                      DropdownMenuItem<
                                                          String>>((value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  underline: Container(),
                                                ),
                                              )),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "ID Number",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller: _userIDController,
                                              hintText: "ID Number",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode: userIdFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Primary Contact Email",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller:
                                                  _primaryContactEmailController,
                                              hintText: "Primary Contact Email",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode:
                                                  primaryContactEmailFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Primary Contact Number",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller:
                                                  _primaryContactNumberController,
                                              hintText:
                                                  "Primary Contact Number",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode:
                                                  primaryContactNumberFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Nationality",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller:
                                                  _nationalityController,
                                              hintText: "Nationality",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              focusNode: nationalityFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: false),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "New Password",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller: _passwordController,
                                              hintText: "New Password",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              maxLines: 1,
                                              focusNode: passwordFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: true),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 4),
                                      child: Text(
                                        "Confirm Password",
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomInputTransparent1(
                                              controller:
                                                  _confirmPasswordController,
                                              hintText: "Confirm Password",
                                              onChanged: (val) {},
                                              onSubmitted: (val) {},
                                              maxLines: 1,
                                              focusNode:
                                                  confirmPasswordFocusNode,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isPasswordField: true),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        businessIndex = 0;
                                        setState(() {});
                                      },
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(200, 50),
                                          side: BorderSide(
                                            width: 1.0,
                                            color: Constants.ctaColorGreen,
                                          ),
                                          backgroundColor: Constants
                                              .ctaColorGreen // Background color
                                          ),
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (_firstNameController.text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description:
                                                Text("Please enter first name"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_lastNameController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your last name"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_userIDController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your ID number"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (selectedGender == null) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your gender"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_roleController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description:
                                                Text("Please enter your role"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_primaryContactEmailController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description:
                                                Text("Please enter your email"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_primaryContactNumberController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your contact number"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_nationalityController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your nationality"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_passwordController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your password"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_confirmPasswordController
                                            .text.isEmpty) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your confirm password"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else if (_passwordController.text !=
                                            _confirmPasswordController.text) {
                                          MotionToast.error(
                                            title: Text("Error"),
                                            description: Text(
                                                "Please enter your password not matching"),
                                            layoutOrientation:
                                                TextDirection.rtl,
                                            animationType:
                                                AnimationType.fromTop,
                                            width: 400,
                                            height: 55,
                                            animationDuration: const Duration(
                                              milliseconds: 2500,
                                            ),
                                          ).show(context);
                                        } else {
                                          createBusinessAccount(context);
                                        }

                                        setState(() {});
                                      },
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(200, 50),
                                          side: BorderSide(
                                            width: 1.0,
                                            color: Constants.ctaColorGreen,
                                          ),
                                          backgroundColor: Colors
                                              .transparent // Background color
                                          ),
                                      child: Text(
                                        'Next',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                              ],
                            )
                          : businessIndex == 2
                              ? Column(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                    ),
                                    Text(
                                      "Artic Sentinel.",
                                      style: GoogleFonts.lato(
                                        fontSize: 30,
                                        color: Constants.ctaColorGreen,
                                        letterSpacing: 1.3,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    Text(
                                      "Create Business",
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Secondary Contact Person Information",
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      thickness: 0.5,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, bottom: 4),
                                          child: Text(
                                            "Secondary Contact First Name",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomInputTransparent1(
                                                  controller:
                                                      _secondaryContactFirstNameController,
                                                  hintText:
                                                      "Secondary Contact First Name",
                                                  onChanged: (val) {},
                                                  onSubmitted: (val) {},
                                                  focusNode:
                                                      secondaryContactFirstNameFocusNode,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  isPasswordField: false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, bottom: 4),
                                          child: Text(
                                            "Secondary Contact Last Name",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomInputTransparent1(
                                                  controller:
                                                      _secondaryContactNameController,
                                                  hintText:
                                                      "Secondary Contact Last LastName",
                                                  onChanged: (val) {},
                                                  onSubmitted: (val) {},
                                                  focusNode:
                                                      secondaryContactLastNameFocusNode,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  isPasswordField: false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, bottom: 4),
                                          child: Text(
                                            "Secondary Contact Number",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomInputTransparent1(
                                                  controller:
                                                      _secondaryContactNumberController,
                                                  hintText:
                                                      "Secondary Contact Number",
                                                  onChanged: (val) {},
                                                  onSubmitted: (val) {},
                                                  focusNode:
                                                      secondaryContactNumberFocusNode,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  isPasswordField: false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8, bottom: 4),
                                          child: Text(
                                            "Secondary email",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CustomInputTransparent1(
                                                  controller:
                                                      _secondaryEmailController,
                                                  hintText: "Secondary email",
                                                  onChanged: (val) {},
                                                  onSubmitted: (val) {},
                                                  focusNode:
                                                      secondaryEmailFocusNode,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  isPasswordField: false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            if (_secondaryContactFirstNameController
                                                .text.isEmpty) {
                                              MotionToast.error(
                                                title: Text("Error"),
                                                description: Text(
                                                    "Please enter your first name"),
                                                layoutOrientation:
                                                    TextDirection.rtl,
                                                animationType:
                                                    AnimationType.fromTop,
                                                width: 400,
                                                height: 55,
                                                animationDuration:
                                                    const Duration(
                                                  milliseconds: 2500,
                                                ),
                                              ).show(context);
                                            }
                                            if (_secondaryContactLastNameController
                                                .text.isEmpty) {
                                              MotionToast.error(
                                                title: Text("Error"),
                                                description: Text(
                                                    "Please enter your last name"),
                                                layoutOrientation:
                                                    TextDirection.rtl,
                                                animationType:
                                                    AnimationType.fromTop,
                                                width: 400,
                                                height: 55,
                                                animationDuration:
                                                    const Duration(
                                                  milliseconds: 2500,
                                                ),
                                              ).show(context);
                                            }
                                            if (_secondaryContactNumberController
                                                .text.isEmpty) {
                                              MotionToast.error(
                                                title: Text("Error"),
                                                description: Text(
                                                    "Please enter secondary contact number"),
                                                layoutOrientation:
                                                    TextDirection.rtl,
                                                animationType:
                                                    AnimationType.fromTop,
                                                width: 400,
                                                height: 55,
                                                animationDuration:
                                                    const Duration(
                                                  milliseconds: 2500,
                                                ),
                                              ).show(context);
                                            }
                                            if (_secondaryEmailController
                                                .text.isEmpty) {
                                              MotionToast.error(
                                                title: Text("Error"),
                                                description: Text(
                                                    "Please enter your first name"),
                                                layoutOrientation:
                                                    TextDirection.rtl,
                                                animationType:
                                                    AnimationType.fromTop,
                                                width: 400,
                                                height: 55,
                                                animationDuration:
                                                    const Duration(
                                                  milliseconds: 2500,
                                                ),
                                              ).show(context);
                                            } else {
                                              createUserAccount(context);
                                            }
                                            //businessIndex = 3;
                                            setState(() {});
                                          },
                                          style: TextButton.styleFrom(
                                              minimumSize: Size(
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  50),
                                              side: BorderSide(
                                                width: 1.0,
                                                color: Constants.ctaColorGreen,
                                              ),
                                              backgroundColor: Colors
                                                  .transparent // Background color
                                              ),
                                          child: Text(
                                            'Create Account',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 24,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            businessIndex = 1;
                                            setState(() {});
                                          },
                                          style: TextButton.styleFrom(
                                              minimumSize: Size(
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  50),
                                              side: BorderSide(
                                                width: 1.0,
                                                color: Constants.ctaColorGreen,
                                              ),
                                              backgroundColor: Constants
                                                  .ctaColorGreen // Background color
                                              ),
                                          child: Text(
                                            'Back',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                )
                              : Container(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    getProvinces();
    super.initState();
  }

  Future<void> createBusinessAccount(BuildContext context) async {
    AuthenticationApiService authenticationApiService =
        AuthenticationApiService(
            baseUrl: "${Constants.articBaseUrl2}create_business_account/");

    String business_uid = uuid.v4();
    String user_uid = uuid.v4();

    ClientInformation clientInformation = ClientInformation(
      business_uid: business_uid,
      user_uid: user_uid,
      business_name: _businessNameController.text,
      owner_name: _ownerNameController.text,
      business_email: _businessEmailController.text,
      business_phone_number: _businessContactNumberController.text,
      address_line1: _address1Controller.text,
      address_line2: _address2Controller.text,
      city: _cityController.text,
      state: selectedProvince!.name,
      postal_code: _postalCodeController.text,
      country: _countryController.text,
      website: _websiteController.text,
      registration_date: Constants.datePickerValue,
      registration_number: _registrationNumberController.text,
      vat_number: _vatNumberController.text,
      industry_type: _businessTypeController.text,
      logo: imageName,
      description: _businessDescriptionController.text,
      first_name: _firstNameController.text,
      last_name: _lastNameController.text,
      password: _passwordController.text,
      role: _roleController.text,
      id_number: _userIDController.text,
      is_primary_contact: true,
      nationality: _nationalityController.text,
      cellphone_number: _primaryContactNumberController.text,
      gender: selectedGender!,
      user_email: _primaryContactEmailController.text,
      is_secondary_contact: false,
    );

    ClientInformation? client = await authenticationApiService
        .createBusinessAccount(clientInformation, context);
    print("ghhghfhj......$client");
    if (client != null) {
      businessIndex = 2;
    } else {
      /*  Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );*/
    }
  }

  Future<void> createUserAccount(BuildContext context) async {
    AuthenticationApiService authenticationApiService =
        AuthenticationApiService(baseUrl: Constants.articBaseUrl2);

    String business_uid = uuid.v4();
    String user_uid = uuid.v4();

    ClientInformation clientInformation = ClientInformation(
      business_uid: business_uid,
      user_uid: user_uid,
      business_name: _businessNameController.text,
      owner_name: _ownerNameController.text,
      business_email: _businessEmailController.text,
      business_phone_number: _businessContactNumberController.text,
      address_line1: _address1Controller.text,
      address_line2: _address2Controller.text,
      city: _cityController.text,
      state: selectedProvince!.name,
      postal_code: _postalCodeController.text,
      country: _countryController.text,
      website: _websiteController.text,
      registration_date: Constants.datePickerValue,
      registration_number: _registrationNumberController.text,
      vat_number: _vatNumberController.text,
      industry_type: _businessTypeController.text,
      logo: imageName,
      description: _businessDescriptionController.text,
      first_name: _secondaryContactFirstNameController.text,
      last_name: _secondaryContactLastNameController.text,
      password: "",
      role: "",
      id_number: "",
      is_primary_contact: false,
      nationality: "",
      cellphone_number: _secondaryContactNumberController.text,
      gender: "",
      user_email: _secondaryEmailController.text,
      is_secondary_contact: true,
    );

    ClientInformation? clientUser = await authenticationApiService
        .createBusinessAccount(clientInformation, context);
    print("ghhghfhj......$clientUser");
    if (clientUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ArticDashboard()),
      );
    } else {
      /*  Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );*/
    }
  }

  void showErrorToast(BuildContext context, String message) {
    MotionToast.error(
      title: Text("Error"),
      description: Text(message),
      layoutOrientation: TextDirection.ltr,
      animationType: AnimationType.fromTop,
      width: 400,
      height: 55,
      animationDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }

  Future<void> getProvinces() async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse("https://artic.net/parlour_config/parlour-config/"));
    request.body = json.encode({"identityNumber": ""});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      print("users.....above.....");
      if (response.statusCode != 200) {
        String jsonData = '''
  [
    {"id": 1, "name": "Eastern Cape"},
    {"id": 2, "name": "Free State"},
    {"id": 3, "name": "Gauteng"},
    {"id": 4, "name": "KwaZulu-Natal"},
    {"id": 5, "name": "Limpopo"},
    {"id": 6, "name": "Mpumalanga"},
    {"id": 7, "name": "North West"},
    {"id": 8, "name": "Northern Cape"},
    {"id": 9, "name": "Western Cape"}
  ]
  ''';

        List<dynamic> provList = jsonDecode(jsonData);

        for (var prov in provList) {
          Province provinces = Province.fromJson(prov);
          provinceList.add(provinces);
          setState(() {});
          print("province ${provinces.name}");
        }
        print("province ${provinceList.length}");
      } else {
        print(response.reasonPhrase);
      }
    } catch (e) {
      print("An error occurred: $e");
    }
  }
}
