import '../../widgets/mobile_forms.dart';
import 'mobile_account_widgets.dart';
import '../../gasmon/gas_theme.dart';
import '../../gasmon/gas_widgets.dart';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:universal_html/html.dart' as html;

import '../../constants/Constants.dart';
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

  Future<void> _pickProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
  }

  Widget _buildMobileSecurity() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        GPanel(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: GasPalette.page,
                backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
                child: imageBytes == null
                    ? const Icon(Icons.person_outline, color: GasPalette.ink2, size: 20) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Constants.myDisplayname, style: gasTitle(context).copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text('Workplace Admin', style: gasSmall(context)),
              ])),
              Tooltip(
                message: 'Upload profile picture',
                child: TextButton(
                  onPressed: _pickProfilePicture,
                  style: accountButtonStyle(context, TextButton.styleFrom(foregroundColor: GasPalette.ink)),
                  child: const Text('Upload'),
                ),
              ),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: GasPalette.border)),
            Text('Connected to your Google account. Update these details in Google.',
                style: gasSmall(context).copyWith(height: 1.5)),
          ]),
        ),
        const SizedBox(height: 18),
        Text('Account details', style: gasTitle(context).copyWith(fontSize: 14)),
        const SizedBox(height: 12),
        Text('Full Names', style: gasSmall(context)),
        const SizedBox(height: 6),
        CustomInputTransparent1(
          controller: _fullNameController, hintText: 'Full Names',
          onChanged: (val) {}, onSubmitted: (val) {},
          focusNode: fullNameFocusNode, textInputAction: TextInputAction.next,
          isPasswordField: false,
        ),
        const SizedBox(height: 12),
        Text('Email', style: gasSmall(context)),
        const SizedBox(height: 6),
        CustomInputTransparent1(
          controller: _emailController, hintText: 'Email',
          onChanged: (val) {}, onSubmitted: (val) {},
          focusNode: emailFocusNode, textInputAction: TextInputAction.next,
          isPasswordField: false,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedRole, isExpanded: true,
          decoration: mobileInputDecoration(context,
              const InputDecoration(labelText: 'Role', hintText: 'Select a role')),
          items: roleList.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (newValue) => setState(() => selectedRole = newValue),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() {}),
            style: accountButtonStyle(context, OutlinedButton.styleFrom(
                foregroundColor: GasPalette.ink2, side: const BorderSide(color: GasPalette.border))),
            child: const Text('Cancel'),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => setState(() {}),
            style: accountButtonStyle(context, ElevatedButton.styleFrom(), primary: true),
            child: const Text('Save Changes'),
          )),
        ]),
        const SizedBox(height: 20),
        GPanel(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Delete Account', style: gasTitle(context).copyWith(fontSize: 14)),
            const SizedBox(height: 6),
            Text('By deleting your account you will lose all your data that you are associated with.',
                style: gasSmall(context).copyWith(height: 1.5)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => setState(() {}),
              style: accountButtonStyle(context, OutlinedButton.styleFrom(
                  foregroundColor: GasPalette.critInk, side: const BorderSide(color: GasPalette.border))),
              child: const Text('Request account deletion'),
            ),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = isPhoneLayout(context);
    if (phone) return _buildMobileSecurity();
    return AccountCard(
      elevation: isPhoneLayout(context) ? 0 : 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPhoneLayout(context) ? 14 : 12),
          side: isPhoneLayout(context)
              ? const BorderSide(color: GasPalette.border)
              : BorderSide.none),
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
                  "Security",
                  style: accountInter(
                    context,
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
                child: MobileFormRow(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Settings for your personal profile",
                      style: accountInter(
                        context,
                        textStyle: TextStyle(
                            fontSize: 14,
                            color: phone
                                ? GasPalette.ink2
                                : Constants.ctaTextColor,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                    if (!isPhoneLayout(context)) Expanded(child: Container()),
                    SizedBox(
                      width: 16,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {});
                      },
                      style: accountButtonStyle(
                          context,
                          TextButton.styleFrom(
                              side: BorderSide(
                                  color: phone
                                      ? GasPalette.border
                                      : Constants.ctaColorGreen,
                                  width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
                              ),
                              minimumSize: Size(120, 50)),
                          primary: false),
                      child: Center(
                        child: Text(
                          "Cancel",
                          style: accountInter(
                            context,
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: phone
                                    ? GasPalette.ink
                                    : Constants.ctaTextColor,
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
                      style: accountButtonStyle(
                          context,
                          TextButton.styleFrom(
                              backgroundColor: phone
                                  ? GasPalette.primary
                                  : Constants.ctaColorGreen,
                              side: BorderSide(
                                  color: phone
                                      ? GasPalette.primary
                                      : Constants.ctaColorGreen,
                                  width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
                              ),
                              minimumSize: Size(120, 50)),
                          primary: true),
                      child: Center(
                        child: Text(
                          "Save Changes",
                          style: accountInter(
                            context,
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
                  color: phone ? GasPalette.border : Colors.black,
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
                      style: accountInter(
                        context,
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
                    MobileFormRow(
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
                              style: accountInter(
                                context,
                                textStyle: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              "Workplace Admin",
                              style: accountInter(
                                context,
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
                          onPressed: _pickProfilePicture,
                          style: accountButtonStyle(
                              context,
                              TextButton.styleFrom(
                                  side: BorderSide(
                                      color: phone
                                          ? GasPalette.border
                                          : Constants.ctaColorGreen,
                                      width: 1.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(360),
                                  ),
                                  minimumSize: Size(90, 50)),
                              primary: false),
                          icon: Icon(
                            Iconsax.document_upload,
                            color: phone ? GasPalette.ink : Colors.black,
                          ),
                          label: Center(
                            child: Text(
                              "Upload",
                              style: accountInter(
                                context,
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
                  color: phone ? GasPalette.border : Colors.black,
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
                      color: phone ? GasPalette.panelAlt : null,
                      borderRadius: BorderRadius.circular(phone ? 14 : 360),
                      border: Border.all(
                          color: phone
                              ? GasPalette.border
                              : Constants.ctaColorGreen,
                          width: 1.0)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (isPhoneLayout(context))
                        const Icon(Icons.link, size: 25, color: GasPalette.ink2)
                      else
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
                          style: accountInter(
                            context,
                            textStyle: TextStyle(
                                fontSize: 13,
                                height: phone ? 1.5 : null,
                                color: phone ? GasPalette.ink2 : Colors.black,
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
                          child: isPhoneLayout(context)
                              ? DropdownButtonFormField<String>(
                                  initialValue: selectedRole,
                                  isExpanded: true,
                                  decoration: mobileInputDecoration(
                                      context,
                                      const InputDecoration(
                                          hintText: 'Select a role')),
                                  items: roleList
                                      .map((value) => DropdownMenuItem(
                                          value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedRole = newValue;
                                    });
                                  },
                                )
                              : Container(
                                  width: 120,
                                  height: 45,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(360)),
                                  child: Center(
                                    child: DropdownButton<String>(
                                      dropdownColor: Colors.white,
                                      padding:
                                          EdgeInsets.only(left: 12, right: 12),
                                      borderRadius: BorderRadius.circular(12),
                                      value:
                                          selectedRole, // Use selectedIndustry (of type Industry?)
                                      isExpanded: true,
                                      hint: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
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
                                          .map<DropdownMenuItem<String>>(
                                              (value) {
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
              AccountCard(
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
                          style: accountInter(
                            context,
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
                          style: accountInter(
                            context,
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: phone
                                    ? GasPalette.ink2
                                    : Constants.ctaTextColor,
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
                        color: phone ? GasPalette.border : Colors.black,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Text(
                          "By deleting your account you will lose all your data that you are associated with.",
                          style: accountInter(
                            context,
                            textStyle: TextStyle(
                                fontSize: 13,
                                color: phone
                                    ? GasPalette.ink2
                                    : Constants.ctaTextColor,
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
                          style: accountButtonStyle(
                              context,
                              TextButton.styleFrom(
                                  side: BorderSide(
                                      color: phone
                                          ? GasPalette.border
                                          : Constants.ctaColorGreen,
                                      width: 1.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(360),
                                  ),
                                  maximumSize: Size(240, 50)),
                              primary: false),
                          child: Center(
                            child: Text(
                              "Request account deletion",
                              style: accountInter(
                                context,
                                textStyle: TextStyle(
                                    fontSize: 13,
                                    color: phone
                                        ? GasPalette.ink2
                                        : Constants.ctaTextColor,
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
