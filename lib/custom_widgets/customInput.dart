import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';

class CustomInput extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  TextInputType? keyboardType;
  CustomInput(
      {super.key,
      required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.keyboardType,
      this.inputFormatters,
      this.prefix,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3)),
      ),
      padding: const EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 8),
      width: MediaQuery.of(context).size.width,
      height: 65,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: const TextStyle(
                fontSize: 13.5,
                color: Colors.black,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF161929)),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13.5),
      ),
    );
  }
}

class CustomInputTransparent1 extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final bool? integersOnly;
  CustomInputTransparent1(
      {required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix,
      this.maxLines,
      this.integersOnly});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      padding: EdgeInsets.only(left: 2, right: 2, top: 8, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 55,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        maxLines: maxLines,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        inputFormatters: integersOnly == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 0,
                fontWeight: FontWeight.normal),
          ),
          contentPadding: EdgeInsets.only(left: 16, top: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.0)),
            borderRadius: BorderRadius.circular(32),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorGreen),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.normal, fontSize: 13.5),
      ),
    );
  }
}

class CustomInputTransparent extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  CustomInputTransparent(
      {super.key,
      required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      decoration: const BoxDecoration(
        // border: Border.all(color: ,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(360),
            topRight: Radius.circular(360),
            bottomLeft: Radius.circular(360),
            bottomRight: Radius.circular(360)),

        color: Colors.transparent,
      ),
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 45,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
                fontSize: 13.5,
                color: Colors.grey,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey!.withOpacity(0.65), width: 0.7),
            borderRadius: BorderRadius.circular(360),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorGreen),
            borderRadius: BorderRadius.circular(360),
          ),
        ),
        style: GoogleFonts.lato(
          textStyle: TextStyle(
              fontSize: 13.5,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
      ),
    );
  }
}

class CustomInputTransparentOption extends StatelessWidget {
  final String hintText, labelText;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final FocusNode focusNode;
  TextEditingController? controller;
  final TextInputAction textInputAction;
  final bool isPasswordField;
  final Widget? prefix;
  final Widget? suffix;
  CustomInputTransparentOption(
      {required this.hintText,
      required this.onChanged,
      required this.onSubmitted,
      required this.focusNode,
      required this.textInputAction,
      required this.isPasswordField,
      this.controller,
      this.prefix,
      this.suffix,
      required this.labelText});

  @override
  Widget build(BuildContext context) {
    bool _isPasswordField = isPasswordField;
    return Container(
      decoration: BoxDecoration(
        // border: Border.all(color: ,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(6)),

        color: Colors.white,
      ),
      padding: EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),
      width: MediaQuery.of(context).size.width,
      height: 45,
      child: TextField(
        obscureText: _isPasswordField,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        controller: controller,
        textInputAction: textInputAction,
/*        validator: (val) {
            return RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                .hasMatch(val!)
                ? null
                : "Please Enter Correct Email";
          },*/
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          hintStyle: GoogleFonts.inter(
            textStyle: TextStyle(
                fontSize: 13.5,
                color: Colors.grey,
                letterSpacing: 0,
                fontWeight: FontWeight.w500),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey!.withOpacity(0.45), width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorGreen),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        style: GoogleFonts.lato(
          textStyle: TextStyle(
              fontSize: 13.5,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
      ),
    );
  }
}
