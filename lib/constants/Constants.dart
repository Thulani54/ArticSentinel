import 'package:artic_sentinel/models/business.dart';
import 'package:artic_sentinel/models/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/device.dart';

class Constants {
  static String datePickerValue1 = "";
  static String datePickerValue = "";
  static int selectedTab = 0;
  static int selectedTab1 = 0;
  static String business_name = "";
  static int business_uid = 0;
  static int user_uid = 0;
  static String articBaseUrl2 = "https://api.articsentinel.com/";
  static String articBaseUrl3 = "https://api.articsentinel.com/";
  static String myDisplayname = "";

  static String myFirstname = "------";
  static String myLastname = "------";
  static String myEmail = "khutsondao7@gmail.com";
  static String myAddress = "-----";
  static String myCountry = "-------";
  static String myPostalCode = "------";
  static String myProvince = "------";
  // Main color constants
  static var ctaColorLight = Color(0xFF222b45);
  static var ctaColorGreen = Color(0xFF10B981); // Proper green color
  static var ctaColorGrey = Color(0xFF9CA3AF);   // Proper grey color
  static var ctaTextColor = Color(0xFF737791);
  
  // State colors
  static var criticalColor = Color(0xFFEF4444);    // Red for critical conditions
  static var compressorOnColor = Color(0xFF10B981); // Green for compressor on
  static var compressorOffColor = Color(0xFF9CA3AF); // Grey for compressor off
  
  // Spacing constants
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  
  // Opacity constants
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.25;
  static const double opacityHeavy = 0.5;
  static Business myBusiness = Business.empty();
  static String myAccountCreaded = "";
  static String myUsername = "";
  static String myUid = "";
  static String ages = "";
  static String genders = "x x";
  static DateFormat formatter = DateFormat('yyyy-MM-dd');
  //_____________________________
  //____________________________________________
  static String myBusinessName = "ABC Farming";
  static String myBusinessNationality = "------";
  static String myBusinessSupportEmail = "support@lyme.com";
  static String myBusinessAddressLine1 = "-----";
  static String myBusinessAddressLine2 = "------";
  static String myBusinessCity = "------";
  static String myBusinessProvince = "------";
  static String myBusinessPostalCode = "------";
  static String myBusinessVatNumber = "------";
  static String myBusinessRegistrationNumber = "------";
  static String myBusinessSupportContactNumber = "+27678113433";

  static DateFormat dateTimeformatter = DateFormat("yyyy-MM-dd hh:mm");

  static List<DailyAggregate> hourlyData = [];
  static List<LatestDeviceData> latestDeviceData = [];
  static List<DeviceModel3> allDeviceData = [];

  // Authentication
  static String authToken = "";

  // User Profile Information
  static String userType = "";
  static String jobTitle = "";
  static String department = "";
  static String cellphoneNumber = "";
  static String workPhone = "";
  static String address = "";
  static String city = "";
  static String province = "";
  static String postalCode = "";
  static String country = "";
  static String gender = "";
  static String idNumber = "";
  static String employeeId = "";
  static String employmentStatus = "";

  // Contact Preferences
  static bool isPrimaryContact = false;
  static bool isSecondaryContact = false;
  static bool isEmergencyContact = false;

  // Communication Preferences
  static bool emailNotifications = true;
  static bool smsNotifications = false;
  static bool emergencyNotifications = true;
  static bool marketingEmails = false;

  // System Preferences
  static String timezone = "Africa/Johannesburg";
  static String language = "en";
  static String dateFormat = "DD/MM/YYYY";

  // Security
  static bool twoFactorEnabled = false;
  static String backupEmail = "";
  static bool isVerified = false;

  // Business Information
  static String registrationNumber = "";
  static String businessContactPerson = "";
  static String businessEmail = "";
  static String businessPhone = "";
  static String businessAddress = "";
  static String businessCity = "";
  static String businessProvince = "";
  static String businessPostalCode = "";
  static String businessCountry = "";
  static String billingEmail = "";
  static String supportEmail = "";
  static String emergencyContact = "";

  // Multiple Businesses
  static List<dynamic> secondaryBusinesses = [];
  static int totalBusinesses = 0;

  // Profile Picture
  static String profilePictureUrl = "";

  // Dates
  static String dateJoined = "";
  static String lastLogin = "";
  static String profileCreated = "";
  static String profileModified = "";
  static String startDate = "";
  static String endDate = "";
  static String dateOfBirth = "";
}
