// connected_unit.dart
class ConnectedUnit {
  final String id;
  final String name;
  final String modelNumber;
  final String serialNumber;
  final String status;
  final String refrigerantType;
  final String compressorType;
  final String compressorModel;
  final double? compressorHp;
  final double? compressorAmpRating;
  final String orificeSize;
  final String dryerSize;
  final String oilSeparator;
  final String liquidReceiver;
  final FanInfo condenserFan;
  final FanInfo evaporatorFan;
  final String evaporatorModel;
  final String evaporatorDimensions;
  final String accumulatorCapacity;
  final String? location;
  final bool isMaintenanceDue;

  ConnectedUnit({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.serialNumber,
    required this.status,
    required this.refrigerantType,
    required this.compressorType,
    required this.compressorModel,
    this.compressorHp,
    this.compressorAmpRating,
    required this.orificeSize,
    required this.dryerSize,
    required this.oilSeparator,
    required this.liquidReceiver,
    required this.condenserFan,
    required this.evaporatorFan,
    required this.evaporatorModel,
    required this.evaporatorDimensions,
    required this.accumulatorCapacity,
    this.location,
    required this.isMaintenanceDue,
  });

  factory ConnectedUnit.fromJson(Map<String, dynamic> json) {
    return ConnectedUnit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelNumber: json['model_number'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      status: json['status'] ?? '',
      refrigerantType: json['refrigerant_type'] ?? '',
      compressorType: json['compressor_type'] ?? '',
      compressorModel: json['compressor_model'] ?? '',
      compressorHp: json['compressor_hp']?.toDouble(),
      compressorAmpRating: json['compressor_amp_rating']?.toDouble(),
      orificeSize: json['orifice_size'] ?? '',
      dryerSize: json['dryer_size'] ?? '',
      oilSeparator: json['oil_separator'] ?? '',
      liquidReceiver: json['liquid_receiver'] ?? '',
      condenserFan: FanInfo.fromJson(json['condenser_fan'] ?? {}),
      evaporatorFan: FanInfo.fromJson(json['evaporator_fan'] ?? {}),
      evaporatorModel: json['evaporator_model'] ?? '',
      evaporatorDimensions: json['evaporator_dimensions'] ?? '',
      accumulatorCapacity: json['accumulator_capacity'] ?? '',
      location: json['location'],
      isMaintenanceDue: json['is_maintenance_due'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'status': status,
      'refrigerant_type': refrigerantType,
      'compressor_type': compressorType,
      'compressor_model': compressorModel,
      'compressor_hp': compressorHp,
      'compressor_amp_rating': compressorAmpRating,
      'orifice_size': orificeSize,
      'dryer_size': dryerSize,
      'oil_separator': oilSeparator,
      'liquid_receiver': liquidReceiver,
      'condenser_fan': condenserFan.toJson(),
      'evaporator_fan': evaporatorFan.toJson(),
      'evaporator_model': evaporatorModel,
      'evaporator_dimensions': evaporatorDimensions,
      'accumulator_capacity': accumulatorCapacity,
      'location': location,
      'is_maintenance_due': isMaintenanceDue,
    };
  }
}

class FanInfo {
  final String type;
  final int count;
  final String power;

  FanInfo({
    required this.type,
    required this.count,
    required this.power,
  });

  factory FanInfo.fromJson(Map<String, dynamic> json) {
    return FanInfo(
      type: json['type'] ?? '',
      count: json['count'] ?? 0,
      power: json['power'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'count': count,
      'power': power,
    };
  }
}

// unit.dart - Simple Unit model for selection

class Unit {
  final String id;
  final String name;
  final String modelNumber;
  final String serialNumber;
  final int year;
  final String? location;
  final String status;
  final String statusValue;
  final bool isMaintenanceDue;

  // Technical Specifications
  final String refrigerantType;
  final String refrigerantTypeValue;
  final String expansionValveType;
  final String expansionValveTypeValue;
  final String controlType;
  final String controlTypeValue;
  final String compressorType;
  final String compressorTypeValue;
  final String dryerType;
  final String dryerTypeValue;

  // Detailed Specifications
  final String orificeSize;
  final String dryerSize;
  final String oilSeparator;
  final String liquidReceiver;
  final String accumulatorCapacity;

  // Compressor Details
  final String compressorModel;
  final double? compressorHp;
  final double? compressorAmpRating;

  // Evaporator Details
  final String evaporatorModel;
  final double? evaporatorLength;
  final double? evaporatorWidth;
  final double? evaporatorHeight;
  final String evaporatorDimensionsDisplay;

  // Condenser Fan
  final String condenserFanType;
  final String condenserFanTypeValue;
  final int condenserFanCount;
  final String condenserFanPower;

  // Evaporator Fan
  final String evaporatorFanType;
  final String evaporatorFanTypeValue;
  final int evaporatorFanCount;
  final String evaporatorFanPower;

  // Calculated Properties
  final int totalFanCount;

  // Maintenance Data
  final String? lastMaintenanceDate;
  final String? lastRepairedDate;
  final String? nextScheduledMaintenance;
  final String? notes;

  // Timestamps
  final String dateCreated;
  final String dateUpdated;

  // Company Info
  final String companyName;
  final int companyId;

  // Location and Device Fields
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? buildingName;
  final String? floorLevel;
  final String? roomNumber;
  final String fullLocationDisplay;
  final bool hasCoordinates;
  final List<Map<String, dynamic>> connectedDevices;
  final int connectedDevicesCount;

  Unit({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.serialNumber,
    required this.year,
    this.location,
    required this.status,
    required this.statusValue,
    required this.isMaintenanceDue,

    // Technical Specifications
    required this.refrigerantType,
    required this.refrigerantTypeValue,
    required this.expansionValveType,
    required this.expansionValveTypeValue,
    required this.controlType,
    required this.controlTypeValue,
    required this.compressorType,
    required this.compressorTypeValue,
    required this.dryerType,
    required this.dryerTypeValue,

    // Detailed Specifications
    required this.orificeSize,
    required this.dryerSize,
    required this.oilSeparator,
    required this.liquidReceiver,
    required this.accumulatorCapacity,

    // Compressor Details
    required this.compressorModel,
    this.compressorHp,
    this.compressorAmpRating,

    // Evaporator Details
    required this.evaporatorModel,
    this.evaporatorLength,
    this.evaporatorWidth,
    this.evaporatorHeight,
    required this.evaporatorDimensionsDisplay,

    // Condenser Fan
    required this.condenserFanType,
    required this.condenserFanTypeValue,
    required this.condenserFanCount,
    required this.condenserFanPower,

    // Evaporator Fan
    required this.evaporatorFanType,
    required this.evaporatorFanTypeValue,
    required this.evaporatorFanCount,
    required this.evaporatorFanPower,

    // Calculated Properties
    required this.totalFanCount,

    // Maintenance Data
    this.lastMaintenanceDate,
    this.lastRepairedDate,
    this.nextScheduledMaintenance,
    this.notes,

    // Timestamps
    required this.dateCreated,
    required this.dateUpdated,

    // Company Info
    required this.companyName,
    required this.companyId,

    // Location and Device Fields
    this.latitude,
    this.longitude,
    this.address,
    this.buildingName,
    this.floorLevel,
    this.roomNumber,
    required this.fullLocationDisplay,
    required this.hasCoordinates,
    required this.connectedDevices,
    required this.connectedDevicesCount,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelNumber: json['model_number'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      year: json['year'] ?? 0,
      location: json['location'],
      status: json['status'] ?? '',
      statusValue: json['status_value'] ?? '',
      isMaintenanceDue: json['is_maintenance_due'] ?? false,

      // Technical Specifications
      refrigerantType: json['refrigerant_type'] ?? '',
      refrigerantTypeValue: json['refrigerant_type_value'] ?? '',
      expansionValveType: json['expansion_valve_type'] ?? '',
      expansionValveTypeValue: json['expansion_valve_type_value'] ?? '',
      controlType: json['control_type'] ?? '',
      controlTypeValue: json['control_type_value'] ?? '',
      compressorType: json['compressor_type'] ?? '',
      compressorTypeValue: json['compressor_type_value'] ?? '',
      dryerType: json['dryer_type'] ?? '',
      dryerTypeValue: json['dryer_type_value'] ?? '',

      // Detailed Specifications
      orificeSize: json['orifice_size'] ?? '',
      dryerSize: json['dryer_size'] ?? '',
      oilSeparator: json['oil_separator'] ?? '',
      liquidReceiver: json['liquid_receiver'] ?? '',
      accumulatorCapacity: json['accumulator_capacity'] ?? '',

      // Compressor Details
      compressorModel: json['compressor_model'] ?? '',
      compressorHp: json['compressor_hp']?.toDouble(),
      compressorAmpRating: json['compressor_amp_rating']?.toDouble(),

      // Evaporator Details
      evaporatorModel: json['evaporator_model'] ?? '',
      evaporatorLength: json['evaporator_length']?.toDouble(),
      evaporatorWidth: json['evaporator_width']?.toDouble(),
      evaporatorHeight: json['evaporator_height']?.toDouble(),
      evaporatorDimensionsDisplay: json['evaporator_dimensions_display'] ?? '',

      // Condenser Fan
      condenserFanType: json['condenser_fan_type'] ?? '',
      condenserFanTypeValue: json['condenser_fan_type_value'] ?? '',
      condenserFanCount: json['condenser_fan_count'] ?? 0,
      condenserFanPower: json['condenser_fan_power'] ?? '',

      // Evaporator Fan
      evaporatorFanType: json['evaporator_fan_type'] ?? '',
      evaporatorFanTypeValue: json['evaporator_fan_type_value'] ?? '',
      evaporatorFanCount: json['evaporator_fan_count'] ?? 0,
      evaporatorFanPower: json['evaporator_fan_power'] ?? '',

      // Calculated Properties
      totalFanCount: json['total_fan_count'] ?? 0,

      // Maintenance Data
      lastMaintenanceDate: json['last_maintenance_date'],
      lastRepairedDate: json['last_repaired_date'],
      nextScheduledMaintenance: json['next_scheduled_maintenance'],
      notes: json['notes'],

      // Timestamps
      dateCreated: json['date_created'] ?? '',
      dateUpdated: json['date_updated'] ?? '',

      // Company Info
      companyName: json['company_name'] ?? '',
      companyId: json['company_id'] ?? 0,

      // Location and Device Fields
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      buildingName: json['building_name'],
      floorLevel: json['floor_level'],
      roomNumber: json['room_number'],
      fullLocationDisplay: json['full_location_display'] ?? '',
      hasCoordinates: json['has_coordinates'] ?? false,
      connectedDevices:
          List<Map<String, dynamic>>.from(json['connected_devices'] ?? []),
      connectedDevicesCount: json['connected_devices_count'] ?? 0,
    );
  }

  // Empty constructor
  factory Unit.empty() {
    return Unit(
      id: '',
      name: '',
      modelNumber: '',
      serialNumber: '',
      year: 0,
      location: null,
      status: '',
      statusValue: '',
      isMaintenanceDue: false,

      // Technical Specifications
      refrigerantType: '',
      refrigerantTypeValue: '',
      expansionValveType: '',
      expansionValveTypeValue: '',
      controlType: '',
      controlTypeValue: '',
      compressorType: '',
      compressorTypeValue: '',
      dryerType: '',
      dryerTypeValue: '',

      // Detailed Specifications
      orificeSize: '',
      dryerSize: '',
      oilSeparator: '',
      liquidReceiver: '',
      accumulatorCapacity: '',

      // Compressor Details
      compressorModel: '',
      compressorHp: null,
      compressorAmpRating: null,

      // Evaporator Details
      evaporatorModel: '',
      evaporatorLength: null,
      evaporatorWidth: null,
      evaporatorHeight: null,
      evaporatorDimensionsDisplay: '',

      // Condenser Fan
      condenserFanType: '',
      condenserFanTypeValue: '',
      condenserFanCount: 0,
      condenserFanPower: '',

      // Evaporator Fan
      evaporatorFanType: '',
      evaporatorFanTypeValue: '',
      evaporatorFanCount: 0,
      evaporatorFanPower: '',

      // Calculated Properties
      totalFanCount: 0,

      // Maintenance Data
      lastMaintenanceDate: null,
      lastRepairedDate: null,
      nextScheduledMaintenance: null,
      notes: null,

      // Timestamps
      dateCreated: '',
      dateUpdated: '',

      // Company Info
      companyName: '',
      companyId: 0,

      // Location and Device Fields
      latitude: null,
      longitude: null,
      address: null,
      buildingName: null,
      floorLevel: null,
      roomNumber: null,
      fullLocationDisplay: '',
      hasCoordinates: false,
      connectedDevices: [],
      connectedDevicesCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'year': year,
      'location': location,
      'status': status,
      'status_value': statusValue,
      'is_maintenance_due': isMaintenanceDue,

      // Technical Specifications
      'refrigerant_type': refrigerantType,
      'refrigerant_type_value': refrigerantTypeValue,
      'expansion_valve_type': expansionValveType,
      'expansion_valve_type_value': expansionValveTypeValue,
      'control_type': controlType,
      'control_type_value': controlTypeValue,
      'compressor_type': compressorType,
      'compressor_type_value': compressorTypeValue,
      'dryer_type': dryerType,
      'dryer_type_value': dryerTypeValue,

      // Detailed Specifications
      'orifice_size': orificeSize,
      'dryer_size': dryerSize,
      'oil_separator': oilSeparator,
      'liquid_receiver': liquidReceiver,
      'accumulator_capacity': accumulatorCapacity,

      // Compressor Details
      'compressor_model': compressorModel,
      'compressor_hp': compressorHp,
      'compressor_amp_rating': compressorAmpRating,

      // Evaporator Details
      'evaporator_model': evaporatorModel,
      'evaporator_length': evaporatorLength,
      'evaporator_width': evaporatorWidth,
      'evaporator_height': evaporatorHeight,
      'evaporator_dimensions_display': evaporatorDimensionsDisplay,

      // Condenser Fan
      'condenser_fan_type': condenserFanType,
      'condenser_fan_type_value': condenserFanTypeValue,
      'condenser_fan_count': condenserFanCount,
      'condenser_fan_power': condenserFanPower,

      // Evaporator Fan
      'evaporator_fan_type': evaporatorFanType,
      'evaporator_fan_type_value': evaporatorFanTypeValue,
      'evaporator_fan_count': evaporatorFanCount,
      'evaporator_fan_power': evaporatorFanPower,

      // Calculated Properties
      'total_fan_count': totalFanCount,

      // Maintenance Data
      'last_maintenance_date': lastMaintenanceDate,
      'last_repaired_date': lastRepairedDate,
      'next_scheduled_maintenance': nextScheduledMaintenance,
      'notes': notes,

      // Timestamps
      'date_created': dateCreated,
      'date_updated': dateUpdated,

      // Company Info
      'company_name': companyName,
      'company_id': companyId,

      // Location and Device Fields
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'building_name': buildingName,
      'floor_level': floorLevel,
      'room_number': roomNumber,
      'full_location_display': fullLocationDisplay,
      'has_coordinates': hasCoordinates,
      'connected_devices': connectedDevices,
      'connected_devices_count': connectedDevicesCount,
    };
  }

  String get displayName {
    return '$name (${serialNumber})';
  }

  String get fullDisplayName {
    return '$name • $modelNumber • S/N: $serialNumber';
  }

  String get statusDisplay {
    return status;
  }

  String get maintenanceStatus {
    if (isMaintenanceDue) {
      return 'Maintenance Due';
    } else if (nextScheduledMaintenance != null) {
      return 'Scheduled: $nextScheduledMaintenance';
    }
    return 'No Schedule';
  }

  String get formattedYear {
    return year.toString();
  }

  String get compressorSpecs {
    List<String> specs = [];
    if (compressorModel.isNotEmpty &&
        compressorModel != 'Standard Compressor') {
      specs.add(compressorModel);
    }
    if (compressorHp != null) {
      specs.add('${compressorHp}HP');
    }
    if (compressorAmpRating != null) {
      specs.add('${compressorAmpRating}A');
    }
    return specs.isNotEmpty ? specs.join(' • ') : 'Standard';
  }

  String get fanConfiguration {
    return 'C: ${condenserFanCount}x ${condenserFanType} • E: ${evaporatorFanCount}x ${evaporatorFanType}';
  }

  bool get isOperational {
    return statusValue.toLowerCase() == 'operational';
  }

  bool get isUnderMaintenance {
    return statusValue.toLowerCase() == 'maintenance';
  }

  bool get isDecommissioned {
    return statusValue.toLowerCase() == 'decommissioned';
  }
}
