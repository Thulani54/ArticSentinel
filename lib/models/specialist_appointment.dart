class SpecialistAppointment {
  final int id; // Unique identifier for the appointment
  final String patientName; // Name of the patient
  final String patientImage; // URL or path of the patient's image
  final String doctorName; // Name of the doctor
  final String doctorImage;
  final double overallRating; // URL or path of the doctor's image
  final DateTime
      appointmentDate; // Date of the appointment// Time of the appointment
  final String
      status; // Status of the appointment (e.g., 'confirmed', 'canceled', 'completed')
  final String
      notes; // Optional notes for the appointment// Total number of patients for this appointment slot
  final int averagePatients; // Average number of patients for this time slot

  SpecialistAppointment({
    required this.id,
    required this.patientName,
    this.overallRating = 0.0,
    this.patientImage = '', // Default to an empty string if not specified
    required this.doctorName,
    this.doctorImage = '', // Default to an empty string if not specified
    required this.appointmentDate,
    required this.status,
    this.notes = '', // Default to 0 if not specified
    this.averagePatients = 0, // Default to 0.0 if not specified
  });

  // Method to convert Appointment to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'patientImage': patientImage,
      'doctorName': doctorName,
      'doctorImage': doctorImage,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'averagePatients': averagePatients,
      "overallRating": overallRating
    };
  }

  // Method to create an Appointment from a Map (for deserialization)
  factory SpecialistAppointment.fromMap(Map<String, dynamic> map) {
    return SpecialistAppointment(
      id: map['id'] ?? 0,

      patientName: map['patientName'] ?? "",
      patientImage: map['patientImage'] ??
          '', // Default to an empty string if not specified
      doctorName: map['doctorName'] ?? "",
      doctorImage: map['doctorImage'] ??
          '', // Default to an empty string if not specified
      appointmentDate: DateTime.parse(map['appointmentDate']),
      status: map['status'] ?? "",
      notes: map['notes'] ?? '', // Default to 0 if not specified
      averagePatients: (map['averagePatients'] ?? 0),
      overallRating: (map['overallRating'] ?? 0.0)
          .toDouble(), // Default to 0.0 if not specified
    );
  }
}
