import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:universal_html/html.dart' as html;

import '../../constants/Constants.dart';
import '../../custom_widgets/customCard.dart';
import '../../custom_widgets/customInput.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

late html.File selected_file_hml;
late html.File selected_file_hml1;
late io.File selected_file_io;

class _SecurityPageState extends State<SecurityPage> {
  String imageName = "";
  File? _image;
  Uint8List? imageBytes;

  TextEditingController _fullNameController = TextEditingController();
  FocusNode fullNameFocusNode = FocusNode();
  TextEditingController _emailController = TextEditingController();
  FocusNode emailFocusNode = FocusNode();

  List<String> roleList = ["Admin 1", "Admin 2", "Admin 3"];
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Text(
                  "Billing",
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),
              SizedBox(
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Settings for your personal profile",
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(
                            fontSize: 14,
                            color: Constants.ctaTextColor,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                    Expanded(child: Container()),
                    SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                          side: BorderSide(
                              color: Constants.ctaColorGreen, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                          minimumSize: Size(120, 50)),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: Constants.ctaTextColor,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: Constants.ctaColorGreen,
                          side: BorderSide(
                              color: Constants.ctaColorGreen, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                          minimumSize: Size(120, 50)),
                      child: Center(
                        child: Text(
                          "Save Changes",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Divider(
                  thickness: 0.5,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Profile Picture",
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(360),
                                child: Image.memory(
                                  imageBytes!,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                CupertinoIcons.person,
                                size: 40,
                                color: Colors.black,
                              ),
                        SizedBox(
                          width: 12,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              Constants.myDisplayname,
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              "Workplace Admin",
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ],
                        ),
                        Expanded(child: Container()),
                        TextButton.icon(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              allowMultiple: false,
                              type: FileType.image,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              // Use the file path
                              imageBytes = result.files.first.bytes;

                              if (imageBytes != null) {
                                String fileName = result.files.first.name;
                                //print("Selected file path: $imageBytes");

                                //_imageURLController.text = filePath;
                                print("Selected file name: $fileName");
                              } else {
                                print("Error: File path is null.");
                              }
                            } else {
                              print("No file was selected.");
                            }
                          },
                          style: TextButton.styleFrom(
                              side: BorderSide(
                                  color: Constants.ctaColorGreen, width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
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
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Divider(
                  thickness: 0.5,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Container(
                  //height: 48,
                  padding:
                      EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(360),
                      border: Border.all(
                          color: Constants.ctaColorGreen, width: 1.0)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        "lib/asset/images/google1.png",
                        width: 25,
                        height: 25,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          "This account is connected to your google account. Your details can only be changed from the google account",
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        "Full Names",
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
                              controller: _fullNameController,
                              hintText: "Full Names",
                              onChanged: (val) {},
                              onSubmitted: (val) {},
                              focusNode: fullNameFocusNode,
                              textInputAction: TextInputAction.next,
                              isPasswordField: false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        "Email",
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
                              controller: _emailController,
                              hintText: "Email",
                              onChanged: (val) {},
                              onSubmitted: (val) {},
                              focusNode: emailFocusNode,
                              textInputAction: TextInputAction.next,
                              isPasswordField: false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
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
                          child: Container(
                              width: 120,
                              height: 45,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(360)),
                              child: Center(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  padding: EdgeInsets.only(left: 12, right: 12),
                                  borderRadius: BorderRadius.circular(12),
                                  value:
                                      selectedRole, // Use selectedIndustry (of type Industry?)
                                  isExpanded: true,
                                  hint: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Select a Role",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedRole = newValue;
                                      //regionList = regionList.where((item) => newValue?.id == item.provinceId).toList();
                                    });
                                  },
                                  selectedItemBuilder: (BuildContext ctxt) {
                                    return roleList.map<Widget>((item) {
                                      return DropdownMenuItem<String>(
                                        child: Container(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Text(
                                              "${item}", // Assuming item is of type Industry
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        value: item,
                                      );
                                    }).toList();
                                  },
                                  items: roleList
                                      .map<DropdownMenuItem<String>>((value) {
                                    return DropdownMenuItem<String>(
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
              ),
              SizedBox(height: 24),
              CustomCard(
                elevation: 5,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          "Delete Account",
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0XFFDC2626),
                                letterSpacing: 0,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          "Delete user account",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: Constants.ctaTextColor,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Divider(
                        thickness: 0.5,
                        color: Colors.black,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          "By deleting your account you will lose all your data that you are associated with.",
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: Constants.ctaTextColor,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: TextButton(
                          onPressed: () {
                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                              side: BorderSide(
                                  color: Constants.ctaColorGreen, width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
                              ),
                              maximumSize: Size(240, 50)),
                          child: Center(
                            child: Text(
                              "Request account deletion",
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                    fontSize: 13,
                                    color: Constants.ctaTextColor,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
