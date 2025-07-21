import 'client.dart';

class User {
  Client client;
  String user_email;
  String password;
  String cellphone_number;
  String address;
  DateTime date_created;
  String role;
  bool is_primary_contact;
  bool is_secondary_contact;
  String gender;
  DateTime date_of_birth;
  String shipping_address_line1;
  String shipping_address_line2;
  String shipping_city;
  String shipping_state_province;
  String shipping_country;
  int user_height;
  int address_lat;
  int address_long;
  int postal_code;
  String profile_picture;
  bool is_admin;
  String billing_address_line1;
  String billing_address_line2;
  String billing_city;
  String billing_state_province;
  String billing_country;

  String first_name;
  String last_name;
  String id_number;
  String nationality;
  String uid;
  String referrer;

  User({
    required this.client,
    required this.user_email,
    required this.password,
    required this.cellphone_number,
    required this.address,
    required this.date_created,
    required this.role,
    required this.is_primary_contact,
    required this.is_secondary_contact,
    required this.gender,
    required this.date_of_birth,
    required this.shipping_address_line1,
    required this.shipping_address_line2,
    required this.shipping_city,
    required this.shipping_state_province,
    required this.shipping_country,
    required this.user_height,
    required this.address_lat,
    required this.address_long,
    required this.postal_code,
    required this.profile_picture,
    required this.is_admin,
    required this.billing_address_line1,
    required this.billing_address_line2,
    required this.billing_city,
    required this.billing_state_province,
    required this.billing_country,
    required this.first_name,
    required this.last_name,
    required this.id_number,
    required this.nationality,
    required this.uid,
    required this.referrer,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      client: Client.fromJson(json['client'] ?? {}),
      user_email: json['user_email'] ?? '',
      password: json['password'] ?? '',
      cellphone_number: json['cellphone_number'] ?? '',
      address: json['address'] ?? '',
      date_created: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : DateTime.now(),
      role: json['role'] ?? '',
      is_primary_contact: json['is_primary_contact'] ?? false,
      is_secondary_contact: json['is_secondary_contact'] ?? false,
      gender: json['gender'] ?? '',
      date_of_birth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : DateTime.now(),
      shipping_address_line1: json['shipping_address_line1'] ?? '',
      shipping_address_line2: json['shipping_address_line2'] ?? '',
      shipping_city: json['shipping_city'] ?? '',
      shipping_state_province: json['shipping_state_province'] ?? '',
      shipping_country: json['shipping_country'] ?? '',
      user_height: json['user_height'] ?? 0,
      address_lat: json['address_lat'] ?? 0,
      address_long: json['address_long'] ?? 0,
      postal_code: json['postal_code'] ?? 0,
      profile_picture: json['profile_picture'] ?? '',
      is_admin: json['is_admin'] ?? false,
      billing_address_line1: json['billing_address_line1'] ?? '',
      billing_address_line2: json['billing_address_line2'] ?? '',
      billing_city: json['billing_city'] ?? '',
      billing_state_province: json['billing_state_province'] ?? '',
      billing_country: json['billing_country'] ?? '',
      first_name: json['firstname'] ?? '',
      last_name: json['lastname'] ?? '',
      id_number: json['id_number'] ?? '',
      nationality: json['nationality'] ?? '',
      uid: json['uid'] ?? '',
      referrer: json['referrer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client': client,
      'user_email': user_email,
      'password': password,
      'cellphone_number': cellphone_number,
      'address': address,
      'date_created': date_created.toIso8601String(),
      'role': role,
      'is_primary_contact': is_primary_contact,
      'is_secondary_contact': is_secondary_contact,
      'gender': gender,
      'date_of_birth': date_of_birth.toIso8601String(),
      'shipping_address_line1': shipping_address_line1,
      'shipping_address_line2': shipping_address_line2,
      'shipping_city': shipping_city,
      'shipping_state_province': shipping_state_province,
      'shipping_country': shipping_country,
      'user_height': user_height,
      'address_lat': address_lat,
      'address_long': address_long,
      'postal_code': postal_code,
      'profile_picture': profile_picture,
      'is_admin': is_admin,
      'billing_address_line1': billing_address_line1,
      'billing_address_line2': billing_address_line2,
      'billing_city': billing_city,
      'billing_state_province': billing_state_province,
      'billing_country': billing_country,
      'firstname': first_name,
      'lastname': last_name,
      'id_number': id_number,
      'nationality': nationality,
      'uid': uid,
      'referrer': referrer,
    };
  }
}
