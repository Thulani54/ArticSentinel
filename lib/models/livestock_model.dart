import 'package:artic_sentinel/models/user.dart';

import '../constants/models/device.dart';
import 'client.dart';

class LivestockModel {
  int id;
  String name;
  String color;
  String species;
  String breed;
  DateTime birthDate;
  bool isPoisonous;
  bool isAlive;
  int age;
  double weight;
  String healthStatus;
  String vaccinationStatus;
  String medicalHistory;
  DateTime lastVetVisit;
  Client owner;
  User createdBy;
  DeviceModel device;

  LivestockModel({
    required this.id,
    required this.name,
    required this.color,
    required this.species,
    required this.breed,
    required this.birthDate,
    required this.isPoisonous,
    required this.isAlive,
    required this.age,
    required this.weight,
    required this.healthStatus,
    required this.vaccinationStatus,
    required this.medicalHistory,
    required this.lastVetVisit,
    required this.owner,
    required this.createdBy,
    required this.device,
  });

  // Factory method to parse data from JSON
  factory LivestockModel.fromJson(Map<String, dynamic> json) {
    return LivestockModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'] ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : DateTime(1970, 1, 1),
      isPoisonous: json['is_poisonous'] ?? false,
      isAlive: json['is_alive'] ?? true,
      age: json['age'] ?? 0,
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString()) ?? 0.0
          : 0.0,
      healthStatus: json['health_status'] ?? '',
      vaccinationStatus: json['vaccination_status'] ?? '',
      medicalHistory: json['medical_history'] ?? '',
      lastVetVisit: json['last_vet_visit'] != null
          ? DateTime.parse(json['last_vet_visit'])
          : DateTime(1970, 1, 1),
      owner: Client.fromJson(json['owner'] ?? {}),
      createdBy: User.fromJson(json['created_by'] ?? {}),
      device: DeviceModel.fromJson(json['device'] ?? {}),
    );
  }

  // Convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'species': species,
      'breed': breed,
      'birth_date': birthDate.toIso8601String(),
      'is_poisonous': isPoisonous,
      'is_alive': isAlive,
      'age': age,
      'weight': weight,
      'health_status': healthStatus,
      'vaccination_status': vaccinationStatus,
      'medical_history': medicalHistory,
      'last_vet_visit': lastVetVisit.toIso8601String(),
      'owner': owner.toJson(),
      'created_by': createdBy.toJson(),
      'device': device.toJson(),
    };
  }
}
