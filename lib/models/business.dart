class Business {
  final int businessUid;
  final String businessName;
  final String? registrationNumber;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? country;
  final String? billingEmail;
  final String? supportEmail;
  final String? emergencyContact;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int activeDevicesCount;
  final bool isPrimary;

  Business({
    required this.businessUid,
    required this.businessName,
    this.registrationNumber,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.country,
    this.billingEmail,
    this.supportEmail,
    this.emergencyContact,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.activeDevicesCount,
    required this.isPrimary,
  });

  /// Creates an empty Business model.
  /// Useful for initializing a variable before it has data.
  factory Business.empty() {
    return Business(
      businessUid: 0,
      businessName: '',
      registrationNumber: '',
      contactPerson: '',
      email: '',
      phone: '',
      address: '',
      city: '',
      province: '',
      postalCode: '',
      country: '',
      billingEmail: '',
      supportEmail: '',
      emergencyContact: '',
      isActive: false,
      createdAt: null,
      updatedAt: null,
      activeDevicesCount: 0,
      isPrimary: false,
    );
  }

  /// Creates a Business model from a JSON map.
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessUid: json['business_uid'] as int,
      businessName: json['business_name'] as String,
      registrationNumber: json['registration_number'] as String?,
      contactPerson: json['contact_person'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      billingEmail: json['billing_email'] as String?,
      supportEmail: json['support_email'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      isActive: json['is_active'] as bool,
      // Safely parse DateTime strings
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      activeDevicesCount: json['active_devices_count'] as int,
      isPrimary: json['is_primary'] as bool,
    );
  }

  /// Converts the Business model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'business_uid': businessUid,
      'business_name': businessName,
      'registration_number': registrationNumber,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'country': country,
      'billing_email': billingEmail,
      'support_email': supportEmail,
      'emergency_contact': emergencyContact,
      'is_active': isActive,
      // Convert DateTime to ISO 8601 string format
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'active_devices_count': activeDevicesCount,
      'is_primary': isPrimary,
    };
  }
}
