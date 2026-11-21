/// Applies a successful /api/login/ (or /api/auth/google/) response to the
/// app session: Constants + SharedPreferences + push registration. Shared by
/// the login screen, the sign-up flow's auto-login and Google sign-in, so a
/// user signed in by any path is stored identically.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/Constants.dart';
import '../models/business.dart';
import 'push_notifications.dart';
import 'shared_preferences.dart';
import 'secure_session_store.dart';
import 'biometric_lock.dart';
import 'offline_read_client.dart';

class AuthSession {
  AuthSession._();

  static Future<void> signOut() async {
    try {
      await PushNotifications.instance
          .unregister()
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Local sign-out must still finish when notification services are offline.
    }
    try {
      await SecureSessionStore.instance
          .clear()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // clear() invalidates the preference flag before platform deletion.
    }
    try {
      await OfflineReadClient.clearAllSnapshots();
    } catch (_) {
      // Failure to delete a cached file must not leave a session signed in.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Sharedprefs.sharedPreferenceUserLoggedInKey, false);
    for (final key in [
      Sharedprefs.sharedPreferenceAuthTokenKey,
      Sharedprefs.sharedPasswordPrefKey,
      Sharedprefs.sharedPreferenceUidKey,
      Sharedprefs.sharedPreferenceBusinessUidKey,
      Sharedprefs.sharedPreferenceUserNameKey,
      Sharedprefs.sharedPreferenceUserEmailKey,
      Sharedprefs.sharedPreferenceBusinessNameKey,
      Sharedprefs.sharedPreferenceBusinessDataKey,
    ]) {
      await prefs.remove(key);
    }
    Constants.authToken = '';
    Constants.user_uid = 0;
    Constants.business_uid = 0;
    Constants.myEmail = '';
    Constants.myDisplayname = '';
    Constants.myUsername = '';
    Constants.cellphoneNumber = '';
    Constants.business_name = '';
    Constants.myBusiness = Business.empty();
    BiometricLock.instance.sessionCleared();
  }

  static Future<void> applyLoginResponse(Map<String, dynamic> body,
      {String password = ''}) async {
    final user = body['user'] as Map<String, dynamic>;
    final primaryBusiness = body['primary_business'] as Map<String, dynamic>?;
    final token = body['token'] as String;
    final previousUser = await Sharedprefs.getUserUidSharedPreference();
    if (previousUser != null && previousUser != user['user_uid']) {
      await signOut();
    }

    if (body['business'] != null) {
      Constants.myBusiness =
          Business.fromJson(body['business'] as Map<String, dynamic>);
      await Sharedprefs.saveBusinessDataPreference(Constants.myBusiness);
    } else {
      Constants.myBusiness = Business.empty();
      await Sharedprefs.saveBusinessDataPreference(Constants.myBusiness);
    }

    Constants.myEmail = user['email'];
    Constants.user_uid = user['user_uid'];
    Constants.myDisplayname = '${user['firstname']} ${user['lastname']}';
    Constants.userType = user['user_type'] ?? '';
    Constants.jobTitle = user['job_title'] ?? '';
    Constants.department = user['department'] ?? '';
    Constants.cellphoneNumber = user['cellphone_number'] ?? '';
    Constants.isPrimaryContact = user['is_primary_contact'] ?? false;
    Constants.emailNotifications = user['email_notifications'] ?? true;
    Constants.smsNotifications = user['sms_notifications'] ?? false;
    Constants.timezone = user['timezone'] ?? 'Africa/Johannesburg';
    Constants.language = user['language'] ?? 'en';

    if (primaryBusiness != null) {
      Constants.business_uid = primaryBusiness['business_uid'] ?? 0;
      Constants.business_name = primaryBusiness['business_name'] ?? '';
      Constants.businessContactPerson = primaryBusiness['contact_person'] ?? '';
      Constants.businessEmail = primaryBusiness['email'] ?? '';
      Constants.businessPhone = primaryBusiness['phone'] ?? '';
      Constants.businessAddress = primaryBusiness['address'] ?? '';
      Constants.businessCity = primaryBusiness['city'] ?? '';
      Constants.businessProvince = primaryBusiness['province'] ?? '';
      Constants.registrationNumber =
          primaryBusiness['registration_number'] ?? '';
      Constants.billingEmail = primaryBusiness['billing_email'] ?? '';
      Constants.supportEmail = primaryBusiness['support_email'] ?? '';
      Constants.emergencyContact = primaryBusiness['emergency_contact'] ?? '';
    } else {
      Constants.business_uid = 0;
      Constants.business_name = '';
      await Sharedprefs.saveBusinessUidSharedPreference(0);
      await Sharedprefs.saveBusinessNameSharedPreference('');
    }

    Constants.secondaryBusinesses = body['secondary_businesses'] ?? [];
    Constants.totalBusinesses = body['total_businesses'] ?? 0;

    await Sharedprefs.saveUserNameSharedPreference(Constants.myDisplayname);
    await Sharedprefs.saveUserEmailSharedPreference(user['email']);
    await Sharedprefs.saveUserUidSharedPreference(user['user_uid']);

    if (primaryBusiness != null) {
      await Sharedprefs.saveBusinessUidSharedPreference(
          primaryBusiness['business_uid'] ?? 0);
      await Sharedprefs.saveBusinessNameSharedPreference(
          primaryBusiness['business_name'] ?? '');
    }

    await Sharedprefs.saveUserTypePreference(user['user_type'] ?? '');
    await Sharedprefs.saveJobTitlePreference(user['job_title'] ?? '');
    await Sharedprefs.saveCellphoneNumberPreference(
        user['cellphone_number'] ?? '');
    await Sharedprefs.saveTimezonePreference(
        user['timezone'] ?? 'Africa/Johannesburg');
    await Sharedprefs.saveLanguagePreference(user['language'] ?? 'en');
    await Sharedprefs.saveEmailNotificationsPreference(
        user['email_notifications'] ?? true);
    await Sharedprefs.saveSmsNotificationsPreference(
        user['sms_notifications'] ?? false);
    if (primaryBusiness != null) {
      await Sharedprefs.saveBusinessContactPersonPreference(
          primaryBusiness['contact_person'] ?? '');
      await Sharedprefs.saveBusinessEmailPreference(
          primaryBusiness['email'] ?? '');
      await Sharedprefs.saveBusinessPhonePreference(
          primaryBusiness['phone'] ?? '');
    }
    // Save the account scope first, then publish its secure session.
    await Sharedprefs.saveAuthTokenPreference(token);
    Constants.authToken = token;
    await Sharedprefs.saveUserLoggedInSharedPreference(true);
    await BiometricLock.instance.sessionAuthenticated();
    // Registration requires the saved user and business scope.
    await PushNotifications.instance.initialize();
    await PushNotifications.instance.sync();
  }
}
