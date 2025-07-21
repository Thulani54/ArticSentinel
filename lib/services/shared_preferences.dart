import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/business.dart';

class Sharedprefs {
  // Existing keys
  static String sharedPreferenceUserLoggedInKey = "ISLOGGEDIN";
  static String sharedPreferenceUserNameKey = "USERNAMEKEY";
  static String sharedPreferenceUserEmailKey = "USEREMAILKEY";
  static String sharedPreferenceBusinessNameKey = "BUSINESSNAMEKEY";
  static String sharedPreferenceUserEmailKey2 = "USEREMAILKEY";
  static String sharedPreferenceUidKey = "USEREUIDKEY";
  static String sharedPreferenceBusinessUidKey = "BUSINESSUIDKEY";
  static String sharedPreferenceBarcodeKey = "USEREBARCODEKEY";
  static String sharedPreferenceCellKey = "USERECELLKEY";
  static String sharedPreferenceEmpIdKey = "USEREEMPIDKEY";
  static String sharedPreferenceCecClientIdKey = "USERCECCLIENTIDKEY";
  static String sharedPasswordPrefKey = "USERPASSWORDKEY";

  // New keys for additional user profile data
  static String sharedPreferenceAuthTokenKey = "AUTHTOKENKEY";
  static String sharedPreferenceUserTypeKey = "USERTYPEKEY";
  static String sharedPreferenceJobTitleKey = "JOBTITLEKEY";
  static String sharedPreferenceDepartmentKey = "DEPARTMENTKEY";
  static String sharedPreferenceCellphoneNumberKey = "CELLPHONENUMBERKEY";
  static String sharedPreferenceWorkPhoneKey = "WORKPHONEKEY";
  static String sharedPreferenceAddressKey = "ADDRESSKEY";
  static String sharedPreferenceCityKey = "CITYKEY";
  static String sharedPreferenceProvinceKey = "PROVINCEKEY";
  static String sharedPreferencePostalCodeKey = "POSTALCODEKEY";
  static String sharedPreferenceCountryKey = "COUNTRYKEY";
  static String sharedPreferenceGenderKey = "GENDERKEY";
  static String sharedPreferenceDateOfBirthKey = "DATEOFBIRTHKEY";
  static String sharedPreferenceIdNumberKey = "IDNUMBERKEY";
  static String sharedPreferenceEmployeeIdKey = "EMPLOYEEIDKEY";
  static String sharedPreferenceEmploymentStatusKey = "EMPLOYMENTSTATUSKEY";
  static String sharedPreferenceStartDateKey = "STARTDATEKEY";
  static String sharedPreferenceEndDateKey = "ENDDATEKEY";
  static String sharedPreferenceTimezoneKey = "TIMEZONEKEY";
  static String sharedPreferenceLanguageKey = "LANGUAGEKEY";
  static String sharedPreferenceDateFormatKey = "DATEFORMATKEY";

  // Contact preferences
  static String sharedPreferenceIsPrimaryContactKey = "ISPRIMARYCONTACTKEY";
  static String sharedPreferenceIsSecondaryContactKey = "ISSECONDARYCONTACTKEY";
  static String sharedPreferenceIsEmergencyContactKey = "ISEMERGENCYCONTACTKEY";

  // Communication preferences
  static String sharedPreferenceEmailNotificationsKey = "EMAILNOTIFICATIONSKEY";
  static String sharedPreferenceSmsNotificationsKey = "SMSNOTIFICATIONSKEY";
  static String sharedPreferenceEmergencyNotificationsKey =
      "EMERGENCYNOTIFICATIONSKEY";
  static String sharedPreferenceMarketingEmailsKey = "MARKETINGEMAILSKEY";

  // Security
  static String sharedPreferenceTwoFactorEnabledKey = "TWOFACTORENABLED";
  static String sharedPreferenceBackupEmailKey = "BACKUPEMAILKEY";
  static String sharedPreferenceIsVerifiedKey = "ISVERIFIEDKEY";

  // Business contact information
  static String sharedPreferenceBusinessContactPersonKey =
      "BUSINESSCONTACTPERSONKEY";
  static String sharedPreferenceBusinessDataKey = "BUSINESSDATAKEY";
  static String sharedPreferenceSecondaryBusinessesKey =
      "SECONDARYBUSINESSESKEY";
  static String sharedPreferenceTotalBusinessesKey = "TOTALBUSINESSESKEY";
  static String sharedPreferenceBusinessEmailKey = "BUSINESSEMAILKEY";
  static String sharedPreferenceBusinessPhoneKey = "BUSINESSPHONEKEY";
  static String sharedPreferenceBusinessAddressKey = "BUSINESSADDRESSKEY";
  static String sharedPreferenceBusinessCityKey = "BUSINESSCITYKEY";
  static String sharedPreferenceBusinessProvinceKey = "BUSINESSPROVINCEKEY";
  static String sharedPreferenceBusinessPostalCodeKey = "BUSINESSPOSTALCODEKEY";
  static String sharedPreferenceBusinessCountryKey = "BUSINESSCOUNTRYKEY";
  static String sharedPreferenceRegistrationNumberKey = "REGISTRATIONNUMBERKEY";
  static String sharedPreferenceBillingEmailKey = "BILLINGEMAILKEY";
  static String sharedPreferenceSupportEmailKey = "SUPPORTEMAILKEY";
  static String sharedPreferenceEmergencyContactKey = "EMERGENCYCONTACTKEY";

  // Profile picture and dates
  static String sharedPreferenceProfilePictureUrlKey = "PROFILEPICTUREURLKEY";
  static String sharedPreferenceDateJoinedKey = "DATEJOINEDKEY";
  static String sharedPreferenceLastLoginKey = "LASTLOGINKEY";
  static String sharedPreferenceProfileCreatedKey = "PROFILECREATEDKEY";
  static String sharedPreferenceProfileModifiedKey = "PROFILEMODIFIEDKEY";

  // Existing methods
  static Future<bool> saveUserLoggedInSharedPreference(
      bool isUserLoggedIn) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceUserLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserNameSharedPreference(String userName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserNameKey, userName);
  }

  static Future<bool> saveUserEmpIdSharedPreference(int cec_employeeid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceEmpIdKey, cec_employeeid);
  }

  static Future<bool> saveUserPasswordPreference(String password) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPasswordPrefKey, password);
  }

  static Future<bool> saveUserCecClientIdSharedPreference(
      int cec_client_id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(
        sharedPreferenceCecClientIdKey, cec_client_id);
  }

  static Future<bool> saveUserUidSharedPreference(int uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceUidKey, uid);
  }

  static Future<bool> saveBusinessUidSharedPreference(int business_uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(
        sharedPreferenceBusinessUidKey, business_uid);
  }

  static Future<bool> saveUserBarcodeSharedPreference(String uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBarcodeKey, uid);
  }

  static Future<bool> saveUserEmailSharedPreference(String userEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserEmailKey, userEmail);
  }

  static Future<bool> saveBusinessNameSharedPreference(
      String businessName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessNameKey, businessName);
  }

  static Future<bool> saveUserEmailSharedPreference2(String userEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceUserEmailKey2, userEmail);
  }

  static Future<bool> saveUserCellSharedPreference(String userCell) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceCellKey, userCell);
  }

  // New save methods for additional user profile data
  static Future<bool> saveAuthTokenPreference(String token) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceAuthTokenKey, token);
  }

  static Future<bool> saveUserTypePreference(String userType) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserTypeKey, userType);
  }

  static Future<bool> saveJobTitlePreference(String jobTitle) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceJobTitleKey, jobTitle);
  }

  static Future<bool> saveDepartmentPreference(String department) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceDepartmentKey, department);
  }

  static Future<bool> saveCellphoneNumberPreference(
      String cellphoneNumber) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceCellphoneNumberKey, cellphoneNumber);
  }

  static Future<bool> saveWorkPhonePreference(String workPhone) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceWorkPhoneKey, workPhone);
  }

  static Future<bool> saveAddressPreference(String address) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceAddressKey, address);
  }

  static Future<bool> saveCityPreference(String city) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceCityKey, city);
  }

  static Future<bool> saveProvincePreference(String province) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceProvinceKey, province);
  }

  static Future<bool> savePostalCodePreference(String postalCode) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferencePostalCodeKey, postalCode);
  }

  static Future<bool> saveCountryPreference(String country) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceCountryKey, country);
  }

  static Future<bool> saveGenderPreference(String gender) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceGenderKey, gender);
  }

  static Future<bool> saveDateOfBirthPreference(String dateOfBirth) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceDateOfBirthKey, dateOfBirth);
  }

  static Future<bool> saveIdNumberPreference(String idNumber) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceIdNumberKey, idNumber);
  }

  static Future<bool> saveEmployeeIdPreference(String employeeId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceEmployeeIdKey, employeeId);
  }

  static Future<bool> saveEmploymentStatusPreference(
      String employmentStatus) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceEmploymentStatusKey, employmentStatus);
  }

  static Future<bool> saveStartDatePreference(String startDate) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceStartDateKey, startDate);
  }

  static Future<bool> saveEndDatePreference(String endDate) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceEndDateKey, endDate);
  }

  static Future<bool> saveTimezonePreference(String timezone) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceTimezoneKey, timezone);
  }

  static Future<bool> saveLanguagePreference(String language) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceLanguageKey, language);
  }

  static Future<bool> saveDateFormatPreference(String dateFormat) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceDateFormatKey, dateFormat);
  }

  // Contact preferences
  static Future<bool> saveIsPrimaryContactPreference(
      bool isPrimaryContact) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceIsPrimaryContactKey, isPrimaryContact);
  }

  static Future<bool> saveIsSecondaryContactPreference(
      bool isSecondaryContact) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceIsSecondaryContactKey, isSecondaryContact);
  }

  static Future<bool> saveBusinessDataPreference(Business business) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String businessJson = jsonEncode(business.toJson());
    return await preferences.setString(
        sharedPreferenceBusinessDataKey, businessJson);
  }

  static Future<bool> saveIsEmergencyContactPreference(
      bool isEmergencyContact) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceIsEmergencyContactKey, isEmergencyContact);
  }

  // Communication preferences
  static Future<bool> saveEmailNotificationsPreference(
      bool emailNotifications) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceEmailNotificationsKey, emailNotifications);
  }

  static Future<bool> saveSmsNotificationsPreference(
      bool smsNotifications) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceSmsNotificationsKey, smsNotifications);
  }

  static Future<bool> saveEmergencyNotificationsPreference(
      bool emergencyNotifications) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceEmergencyNotificationsKey, emergencyNotifications);
  }

  static Future<bool> saveMarketingEmailsPreference(
      bool marketingEmails) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceMarketingEmailsKey, marketingEmails);
  }

  // Security preferences
  static Future<bool> saveTwoFactorEnabledPreference(
      bool twoFactorEnabled) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceTwoFactorEnabledKey, twoFactorEnabled);
  }

  static Future<bool> saveBackupEmailPreference(String backupEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBackupEmailKey, backupEmail);
  }

  static Future<bool> saveIsVerifiedPreference(bool isVerified) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(sharedPreferenceIsVerifiedKey, isVerified);
  }

  // Business contact information
  static Future<bool> saveBusinessContactPersonPreference(
      String contactPerson) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessContactPersonKey, contactPerson);
  }

  static Future<bool> saveBusinessEmailPreference(String businessEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessEmailKey, businessEmail);
  }

  static Future<bool> saveBusinessPhonePreference(String businessPhone) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessPhoneKey, businessPhone);
  }

  static Future<bool> saveBusinessAddressPreference(
      String businessAddress) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessAddressKey, businessAddress);
  }

  static Future<bool> saveBusinessCityPreference(String businessCity) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessCityKey, businessCity);
  }

  static Future<bool> saveBusinessProvincePreference(
      String businessProvince) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessProvinceKey, businessProvince);
  }

  static Future<bool> saveBusinessPostalCodePreference(
      String businessPostalCode) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessPostalCodeKey, businessPostalCode);
  }

  static Future<bool> saveBusinessCountryPreference(
      String businessCountry) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBusinessCountryKey, businessCountry);
  }

  static Future<bool> saveRegistrationNumberPreference(
      String registrationNumber) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceRegistrationNumberKey, registrationNumber);
  }

  static Future<bool> saveBillingEmailPreference(String billingEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceBillingEmailKey, billingEmail);
  }

  static Future<bool> saveSupportEmailPreference(String supportEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceSupportEmailKey, supportEmail);
  }

  static Future<bool> saveEmergencyContactPreference(
      String emergencyContact) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceEmergencyContactKey, emergencyContact);
  }

  // Profile picture and dates
  static Future<bool> saveProfilePictureUrlPreference(
      String profilePictureUrl) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceProfilePictureUrlKey, profilePictureUrl);
  }

  static Future<bool> saveDateJoinedPreference(String dateJoined) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceDateJoinedKey, dateJoined);
  }

  static Future<bool> saveLastLoginPreference(String lastLogin) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceLastLoginKey, lastLogin);
  }

  static Future<bool> saveProfileCreatedPreference(
      String profileCreated) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceProfileCreatedKey, profileCreated);
  }

  static Future<bool> saveProfileModifiedPreference(
      String profileModified) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceProfileModifiedKey, profileModified);
  }

  // Existing getter methods
  static Future<bool?> getUserLoggedInSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceUserLoggedInKey);
  }

  static Future<String?> getUserNameSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserNameKey);
  }

  static Future<int?> getEmpIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceEmpIdKey);
  }

  static Future<int?> getCecClientIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceCecClientIdKey);
  }

  static Future<String?> getUserEmailSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserEmailKey);
  }

  static Future<String?> getUserEmailSharedPreference2() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserEmailKey2);
  }

  static Future<String?> getUserCellSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCellKey);
  }

  static Future<int?> getUserUidSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceUidKey);
  }

  static Future<int?> getBusinessUidSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceBusinessUidKey);
  }

  static Future<String?> getBusinessNameSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessNameKey);
  }

  static Future<String?> getUserBarcodeSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBarcodeKey);
  }

  static Future<String?> getUserPasswordPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPasswordPrefKey);
  }

  // New getter methods for additional user profile data
  static Future<String?> getAuthTokenPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceAuthTokenKey);
  }

  static Future<String?> getUserTypePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserTypeKey);
  }

  static Future<String?> getJobTitlePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceJobTitleKey);
  }

  static Future<String?> getDepartmentPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceDepartmentKey);
  }

  static Future<String?> getCellphoneNumberPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCellphoneNumberKey);
  }

  static Future<String?> getWorkPhonePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceWorkPhoneKey);
  }

  static Future<String?> getAddressPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceAddressKey);
  }

  static Future<String?> getCityPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCityKey);
  }

  static Future<String?> getProvincePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceProvinceKey);
  }

  static Future<String?> getPostalCodePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferencePostalCodeKey);
  }

  static Future<String?> getCountryPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCountryKey);
  }

  static Future<String?> getGenderPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceGenderKey);
  }

  static Future<String?> getDateOfBirthPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceDateOfBirthKey);
  }

  static Future<String?> getIdNumberPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceIdNumberKey);
  }

  static Future<String?> getEmployeeIdPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceEmployeeIdKey);
  }

  static Future<String?> getEmploymentStatusPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceEmploymentStatusKey);
  }

  static Future<String?> getStartDatePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceStartDateKey);
  }

  static Future<String?> getEndDatePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceEndDateKey);
  }

  static Future<String?> getTimezonePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceTimezoneKey);
  }

  static Future<String?> getLanguagePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceLanguageKey);
  }

  static Future<String?> getDateFormatPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceDateFormatKey);
  }

  // Contact preferences getters
  static Future<bool?> getIsPrimaryContactPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceIsPrimaryContactKey);
  }

  static Future<bool?> getIsSecondaryContactPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceIsSecondaryContactKey);
  }

  static Future<bool?> getIsEmergencyContactPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceIsEmergencyContactKey);
  }

  // Communication preferences getters
  static Future<bool?> getEmailNotificationsPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceEmailNotificationsKey);
  }

  static Future<bool?> getSmsNotificationsPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceSmsNotificationsKey);
  }

  static Future<bool?> getEmergencyNotificationsPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceEmergencyNotificationsKey);
  }

  static Future<bool?> getMarketingEmailsPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceMarketingEmailsKey);
  }

  // Security preferences getters
  static Future<bool?> getTwoFactorEnabledPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceTwoFactorEnabledKey);
  }

  static Future<String?> getBackupEmailPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBackupEmailKey);
  }

  static Future<bool?> getIsVerifiedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceIsVerifiedKey);
  }

  // Business contact information getters
  static Future<String?> getBusinessContactPersonPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences
        .getString(sharedPreferenceBusinessContactPersonKey);
  }

  static Future<String?> getBusinessEmailPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessEmailKey);
  }

  static Future<String?> getBusinessPhonePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessPhoneKey);
  }

  static Future<String?> getBusinessAddressPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessAddressKey);
  }

  static Future<String?> getBusinessCityPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessCityKey);
  }

  static Future<String?> getBusinessProvincePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessProvinceKey);
  }

  static Future<String?> getBusinessPostalCodePreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessPostalCodeKey);
  }

  static Future<String?> getBusinessCountryPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessCountryKey);
  }

  static Future<String?> getRegistrationNumberPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceRegistrationNumberKey);
  }

  static Future<String?> getBillingEmailPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBillingEmailKey);
  }

  static Future<String?> getSupportEmailPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceSupportEmailKey);
  }

  static Future<String?> getEmergencyContactPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceEmergencyContactKey);
  }

  static Future<Business?> getBusinessDataPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? businessJsonString =
        preferences.getString(sharedPreferenceBusinessDataKey);
    if (businessJsonString != null && businessJsonString.isNotEmpty) {
      try {
        Map<String, dynamic> businessJson = jsonDecode(businessJsonString);
        return Business.fromJson(businessJson);
      } catch (e) {
        print('Error parsing business data: $e');
        return null;
      }
    }
    return null;
  }
}
