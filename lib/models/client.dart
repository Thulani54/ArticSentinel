class ClientInformation {
  String business_uid;
  String user_uid;
  String business_name;
  String owner_name;
  String business_email;
  String business_phone_number;
  String address_line1;
  String address_line2;
  String city;
  String state;
  String postal_code;
  String country;
  String first_name;
  String last_name;
  String user_email;
  String password;
  String cellphone_number;
  String nationality;
  String role;
  bool is_primary_contact;
  bool is_secondary_contact;
  String gender;
  String id_number;
  String website;
  String registration_date;
  String registration_number;
  String vat_number;
  String industry_type;
  String logo;
  String description;

  ClientInformation(
      {required this.business_uid,
      required this.user_uid,
      required this.business_name,
      required this.owner_name,
      required this.business_email,
      required this.business_phone_number,
      required this.address_line1,
      required this.address_line2,
      required this.city,
      required this.state,
      required this.postal_code,
      required this.country,
      required this.first_name,
      required this.last_name,
      required this.user_email,
      required this.password,
      required this.cellphone_number,
      required this.nationality,
      required this.role,
      required this.is_primary_contact,
      required this.is_secondary_contact,
      required this.gender,
      required this.id_number,
      required this.website,
      required this.registration_date,
      required this.registration_number,
      required this.vat_number,
      required this.industry_type,
      required this.logo,
      required this.description});

  factory ClientInformation.fromJson(Map<String, dynamic> json) {
    return ClientInformation(
      business_uid: json['business_uid'] ?? '',
      user_uid: json['user_uid'] ?? '',
      business_name: json['business_name'] ?? '',
      owner_name: json['owner_name'] ?? '',
      business_email: json['email'] ?? '',
      business_phone_number: json['business_phone_number'] ?? '',
      address_line1: json['address_line1'] ?? '',
      address_line2: json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postal_code: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      website: json['website'] ?? '',
      registration_date: json['registration_date'] ?? "",
      registration_number: json['registration_number'] ?? '',
      vat_number: json['vat_number'] ?? '',
      industry_type: json['industry_type'] ?? '',
      logo: json['logo'] ?? '',
      description: json['description'] ?? '',
      first_name: json['first_name'] ?? '',
      last_name: json['last_name'] ?? '',
      user_email: json['user_email'] ?? '',
      password: json['password'] ?? '',
      cellphone_number: json['cellphone_number'] ?? '',
      nationality: json['nationality'] ?? '',
      role: json['role'] ?? '',
      is_primary_contact: json['is_primary_contact'] ?? false,
      is_secondary_contact: json['is_secondary_contact'] ?? false,
      gender: json['gender'] ?? "",
      id_number: json['id_number'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_uid': business_uid,
      'user_uid': user_uid,
      'business_name': business_name,
      'owner_name': owner_name,
      'email': business_email,
      'business_phone_number': business_phone_number,
      'address_line1': address_line1,
      'address_line2': address_line2,
      'city': city,
      'state': state,
      'postal_code': postal_code,
      'country': country,
      'website': website,
      'registration_date': registration_date,
      'registration_number': registration_number,
      'vat_number': vat_number,
      'industry_type': industry_type,
      'logo': logo,
      'description': description,
      'first_name': first_name,
      'last_name': last_name,
      'role': role,
      'id_number': id_number,
      'nationality': nationality,
      'cellphone_number': cellphone_number,
      'gender': gender,
      'is_primary_contact': is_primary_contact,
      'is_secondary_contact': is_secondary_contact,
      'password': password,
    };
  }
}

class Client {
  String businessUid;
  String businessName;
  String ownerName;
  String email;
  String phoneNumber;
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String postalCode;
  String country;
  String website;
  DateTime registrationDate;
  String registrationNumber;
  String vatNumber;
  String industryType;
  String logo;
  String description;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
  double rating;
  int reviewsCount;

  Client({
    required this.businessUid,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.website,
    required this.registrationDate,
    required this.registrationNumber,
    required this.vatNumber,
    required this.industryType,
    required this.logo,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.rating,
    required this.reviewsCount,
  });

  // Factory method to parse data from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      businessUid: json['business_uid'] ?? '',
      businessName: json['business_name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      website: json['website'] ?? '',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : DateTime(1970, 1, 1),
      registrationNumber: json['registration_number'] ?? '',
      vatNumber: json['vat_number'] ?? '',
      industryType: json['industry_type'] ?? '',
      logo: json['logo'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString()) ?? 0.0
          : 0.0,
      reviewsCount: json['reviews_count'] ?? 0,
    );
  }

  // Convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      'business_uid': businessUid,
      'business_name': businessName,
      'owner_name': ownerName,
      'email': email,
      'phone_number': phoneNumber,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'website': website,
      'registration_date': registrationDate.toIso8601String(),
      'registration_number': registrationNumber,
      'vat_number': vatNumber,
      'industry_type': industryType,
      'logo': logo,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'rating': rating,
      'reviews_count': reviewsCount,
    };
  }
}
