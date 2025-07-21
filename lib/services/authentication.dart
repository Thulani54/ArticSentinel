import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';

import '../constants/Constants.dart';
import '../models/client.dart';

class AuthenticationApiService {
  final String baseUrl;
  AuthenticationApiService({required this.baseUrl});

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  Future<ClientInformation?> createBusinessAccount(
      ClientInformation clientInfo, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return  Center(
            child: CircularProgressIndicator(  color: Constants.ctaColorLight,
                                strokeWidth: 1.5,),
          );
        },
      );

      print("Request payload: ${clientInfo.toJson()}");
      final response = await http.post(
        Uri.parse('$baseUrl'),
        headers: headers,
        body: json.encode(clientInfo.toJson()),
      );

      Navigator.of(context).pop(); // Close the loading dialog
      print("Response: ${response.body}");
      if (response.statusCode == 201) {
        print("Response: ${response.body}");

        try {
          Map<String, dynamic> responseData = json.decode(response.body);
          ClientInformation createdClientInfo =
              ClientInformation.fromJson(responseData);

          MotionToast.success(
            title: const Text("Success"),
            description: const Text(
              "Business Account Created Successfully",
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            layoutOrientation: TextDirection.ltr,
            animationType: AnimationType.fromTop,
            height: 55,
            animationDuration: const Duration(milliseconds: 2500),
          ).show(context);

          return createdClientInfo;
        } catch (jsonError) {
          print("JSON Parsing Error: $jsonError");
          showErrorToast(context, "Failed to parse server response.");
          return null;
        }
      } else {
        print("Error Response: ${response.body}");
        showErrorToast(context, "Failed to create Business account");
        return null;
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure the loading dialog is closed
      print("Exception: $e");
      showErrorToast(context, e.toString());
      return null;
    }
  }

  Future<ClientInformation?> createUserAccount(
      ClientInformation clientInfo, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return  Center(
            child: CircularProgressIndicator(  color: Constants.ctaColorLight,
                                strokeWidth: 1.5,),
          );
        },
      );

      print("Request payload: ${clientInfo.toJson()}");
      print("Request payload: ${clientInfo.toJson()}");
      final response = await http.post(
        Uri.parse('$baseUrl+create_business_account/'),
        headers: headers,
        body: json.encode(clientInfo.toJson()),
      );

      Navigator.of(context).pop(); // Close the loading dialog

      if (response.statusCode == 201) {
        print("Response: ${response.body}");

        try {
          Map<String, dynamic> responseData = json.decode(response.body);
          ClientInformation createdClientInfo =
              ClientInformation.fromJson(responseData);

          MotionToast.success(
            title: const Text("Success"),
            description: const Text(
              "Business Account Created Successfully",
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            layoutOrientation: TextDirection.ltr,
            animationType: AnimationType.fromTop,
            height: 55,
            animationDuration: const Duration(milliseconds: 2500),
          ).show(context);

          return createdClientInfo;
        } catch (jsonError) {
          print("JSON Parsing Error: $jsonError");
          showErrorToast(context, "Failed to parse server response.");
          return null;
        }
      } else {
        print("Error Response: ${response.body}");
        showErrorToast(context, "Failed to create user account");
        return null;
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure the loading dialog is closed
      print("Exception: $e");
      showErrorToast(context, e.toString());
      return null;
    }
  }

  Future<http.Response> AddNewLivestock(Map<String, dynamic> livestock) async {
    print("Request payload: $livestock");
    final response = await http.post(
      Uri.parse('${baseUrl}create_new_livestock/'),
      headers: headers,
      body: json.encode(livestock),
    );
    return response;
  }

  /// Helper method to show error toasts
  void showErrorToast(BuildContext context, String message) {
    MotionToast.error(
      title: const Text("Error"),
      description: Text(message),
      layoutOrientation: TextDirection.rtl,
      animationType: AnimationType.fromTop,
      width: 400,
      height: 55,
      animationDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }
}
