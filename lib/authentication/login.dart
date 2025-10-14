import 'dart:convert';

import 'package:artic_sentinel/authentication/signup.dart';
import 'package:artic_sentinel/screens/dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';

import '../constants/Constants.dart';
import '../custom_widgets/customCard.dart';
import '../custom_widgets/customInput.dart';
import '../models/business.dart';
import '../services/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _emailController = TextEditingController();
  FocusNode emailFocusNode = FocusNode();

  TextEditingController _passwordController = TextEditingController();
  FocusNode passwordFocusNode = FocusNode();
  bool isHidden = false;
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Row(
              children: [
                Spacer(),
                CustomCard(
                  elevation: 5,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    constraints: BoxConstraints(maxWidth: 500, maxHeight: 633),
                    //padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      height: 140,
                                      width: 140,
                                      child: Image.asset(
                                          "lib/assets/artic_logo.png")),
                                  Text(
                                    "Artic Sentinel.",
                                    style: GoogleFonts.lato(
                                      fontSize: 30,
                                      color: Constants.ctaColorLight,
                                      letterSpacing: 1.3,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  Text(
                                    "Login",
                                    style: GoogleFonts.lato(
                                      textStyle: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  // Email field
                                  CustomInputTransparent1(
                                    controller: _emailController,
                                    hintText: "Email",
                                    onChanged: (value) {},
                                    onSubmitted: (value) {},
                                    focusNode: emailFocusNode,
                                    textInputAction: TextInputAction.none,
                                    isPasswordField: false,
                                  ),
                                  SizedBox(height: 20),
                                  // Password field
                                  CustomInputTransparent1(
                                      controller: _passwordController,
                                      hintText: "Password",
                                      onChanged: (value) {},
                                      onSubmitted: (value) {},
                                      focusNode: passwordFocusNode,
                                      textInputAction: TextInputAction.none,
                                      maxLines: 1,
                                      isPasswordField: isHidden,
                                      suffix: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: IconButton(
                                            onPressed: () {
                                              isHidden = !isHidden;
                                              setState(() {});
                                            },
                                            icon: Icon(
                                              isHidden == true
                                                  ? CupertinoIcons.eye_slash
                                                  : CupertinoIcons.eye,
                                              color: Constants.ctaColorLight,
                                            )),
                                      )),

                                  SizedBox(height: 20),
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32),
                                              side: BorderSide(
                                                  color:
                                                      Constants.ctaColorLight)),
                                          checkColor: Colors.white,
                                          activeColor: Constants.ctaColorLight,
                                          value: isChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isChecked = value!;
                                            });
                                          },
                                        ),
                                        SizedBox(
                                          width: 22,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Text(
                                              'By proceeding to login, you accept our Terms of use and Privacy policy.',
                                              style: GoogleFonts.lato(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  // Login button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            if (_emailController.text.isEmpty) {
                                              MotionToast.error(
                                                onClose: () {},
                                                description: Text(
                                                  "Please enter your email",
                                                  style: GoogleFonts.lato(
                                                      color: Colors.white),
                                                ),
                                              ).show(context);
                                            } else if (_passwordController
                                                .text.isEmpty) {
                                              MotionToast.error(
                                                onClose: () {},
                                                description: Text(
                                                  "Please enter your password",
                                                  style: GoogleFonts.lato(
                                                      color: Colors.white),
                                                ),
                                              ).show(context);
                                            } else {
                                              signInUser();
                                              /*Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LymeDashboard()),
                                            );*/
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(32)),
                                            minimumSize: Size.fromHeight(50),
                                            backgroundColor: Constants
                                                .ctaColorLight, // Background color
                                          ),
                                          child: Text(
                                            'Login',
                                            style: GoogleFonts.lato(
                                                color: Colors.white,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  // Login button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SignUpPage()),
                                            );
                                            setState(() {});
                                          },
                                          style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          32)),
                                              minimumSize: Size.fromHeight(50),
                                              side: BorderSide(
                                                width: 1.0,
                                                color: Constants.ctaColorLight,
                                              ),
                                              backgroundColor: Colors
                                                  .transparent // Background color
                                              ),
                                          child: Text(
                                            'Create Account',
                                            style: GoogleFonts.lato(
                                                color: Colors.black,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  RichText(
                                    text: TextSpan(
                                      text:
                                          'Artic Sentinel © ${DateTime.now().year}.',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'All rights reserved',
                                          style: GoogleFonts.inter(
                                            textStyle: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> signInUser() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Constants.ctaColorLight,
                  strokeWidth: 1.5,
                ),
                SizedBox(width: 20),
                Text("Logging In..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      final String baseUrl = "${Constants.articBaseUrl2}api/login/";

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode({
          "user_email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      print("Login API: $baseUrl");
      print("Email: ${_emailController.text}");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("Response: $responseBody");

        if (responseBody["message"] == "Login successful") {
          print('Account logged in successfully.');

          final user = responseBody["user"];
          final primaryBusiness = responseBody["primary_business"];
          if (responseBody["business"] != null) {
            Constants.myBusiness = Business.fromJson(responseBody["business"]);
            Sharedprefs.saveBusinessDataPreference(Constants.myBusiness);
          }
          final secondaryBusinesses =
              responseBody["secondary_businesses"] ?? [];
          final token = responseBody["token"];

          print("User Data: $user");
          print("Primary Business: $primaryBusiness");
          print("Secondary Businesses: $secondaryBusinesses");
          print("Token: $token");

          // Update Constants with user information
          Constants.myEmail = user["email"];
          Constants.user_uid = user["user_uid"];
          Constants.myDisplayname = "${user["firstname"]} ${user["lastname"]}";

          // Store authentication token
          Constants.authToken = token;

          // Store user profile information
          Constants.userType = user["user_type"] ?? "";
          Constants.jobTitle = user["job_title"] ?? "";
          Constants.department = user["department"] ?? "";
          Constants.cellphoneNumber = user["cellphone_number"] ?? "";
          Constants.isPrimaryContact = user["is_primary_contact"] ?? false;
          Constants.emailNotifications = user["email_notifications"] ?? true;
          Constants.smsNotifications = user["sms_notifications"] ?? false;
          Constants.timezone = user["timezone"] ?? "Africa/Johannesburg";
          Constants.language = user["language"] ?? "en";

          // Store primary business information
          if (primaryBusiness != null) {
            Constants.business_uid = primaryBusiness["business_uid"] ?? "";
            Constants.business_name = primaryBusiness["business_name"] ?? "";
            Constants.businessContactPerson =
                primaryBusiness["contact_person"] ?? "";
            Constants.businessEmail = primaryBusiness["email"] ?? "";
            Constants.businessPhone = primaryBusiness["phone"] ?? "";
            Constants.businessAddress = primaryBusiness["address"] ?? "";
            Constants.businessCity = primaryBusiness["city"] ?? "";
            Constants.businessProvince = primaryBusiness["province"] ?? "";
            Constants.registrationNumber =
                primaryBusiness["registration_number"] ?? "";
            Constants.billingEmail = primaryBusiness["billing_email"] ?? "";
            Constants.supportEmail = primaryBusiness["support_email"] ?? "";
            Constants.emergencyContact =
                primaryBusiness["emergency_contact"] ?? "";
          }

          // Store secondary businesses (if you need them)
          Constants.secondaryBusinesses = secondaryBusinesses;
          Constants.totalBusinesses = responseBody["total_businesses"] ?? 0;

          // Save user information locally using SharedPreferences
          await Sharedprefs.saveUserLoggedInSharedPreference(true);
          await Sharedprefs.saveUserNameSharedPreference(
              Constants.myDisplayname);
          await Sharedprefs.saveUserEmailSharedPreference(user["email"]);
          await Sharedprefs.saveUserUidSharedPreference(user["user_uid"]);
          await Sharedprefs.saveUserPasswordPreference(
              _passwordController.text);
          await Sharedprefs.saveAuthTokenPreference(token);

          // Save business information
          if (primaryBusiness != null) {
            await Sharedprefs.saveBusinessUidSharedPreference(
                primaryBusiness["business_uid"] ?? "");
            await Sharedprefs.saveBusinessNameSharedPreference(
                primaryBusiness["business_name"] ?? "");
          }

          // Save additional user profile data
          await Sharedprefs.saveUserTypePreference(user["user_type"] ?? "");
          await Sharedprefs.saveJobTitlePreference(user["job_title"] ?? "");
          await Sharedprefs.saveCellphoneNumberPreference(
              user["cellphone_number"] ?? "");
          await Sharedprefs.saveTimezonePreference(
              user["timezone"] ?? "Africa/Johannesburg");
          await Sharedprefs.saveLanguagePreference(user["language"] ?? "en");

          // Save notification preferences
          await Sharedprefs.saveEmailNotificationsPreference(
              user["email_notifications"] ?? true);
          await Sharedprefs.saveSmsNotificationsPreference(
              user["sms_notifications"] ?? false);

          // Save business contact information (if needed)
          if (primaryBusiness != null) {
            await Sharedprefs.saveBusinessContactPersonPreference(
                primaryBusiness["contact_person"] ?? "");
            await Sharedprefs.saveBusinessEmailPreference(
                primaryBusiness["email"] ?? "");
            await Sharedprefs.saveBusinessPhonePreference(
                primaryBusiness["phone"] ?? "");
          }

          // Clear form inputs
          _emailController.clear();
          _passwordController.clear();

          // Navigate to the home screen
          context.goNamed('dashboard');

          setState(() {});
        } else {
          // Handle error response
          MotionToast.error(
            description: Text(
              responseBody["message"],
              style: TextStyle(color: Colors.white),
            ),
            layoutOrientation: TextDirection.ltr,
            animationType: AnimationType.fromTop,
            width: 400,
            height: 55,
            animationDuration: const Duration(milliseconds: 2500),
          ).show(context);
        }
      } else {
        // Handle unexpected status codes
        print("Error: ${response.statusCode} - ${response.body}");

        String errorMessage = "Login failed. Please try again.";
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody["message"] ?? errorMessage;
        } catch (e) {
          // If response body is not valid JSON, use default message
        }

        MotionToast.error(
          description: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
          layoutOrientation: TextDirection.ltr,
          animationType: AnimationType.fromTop,
          width: 400,
          height: 55,
          animationDuration: const Duration(milliseconds: 2500),
        ).show(context);
      }
    } catch (e) {
      // Close loading dialog in case of an exception
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Log the error and show a toast
      print("Error during login: $e");
      MotionToast.error(
        description: const Text(
          "Could not sign in. Please try again later.",
          style: TextStyle(color: Colors.white),
        ),
        layoutOrientation: TextDirection.ltr,
        animationType: AnimationType.fromTop,
        width: 400,
        height: 55,
        animationDuration: const Duration(milliseconds: 2500),
      ).show(context);
    }
  }
}
