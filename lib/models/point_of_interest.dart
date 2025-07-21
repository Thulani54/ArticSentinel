class PointOfInterest {
  final int id;
  final String poiName;
  final String areaName;
  bool isSelected;

  PointOfInterest({
    required this.id,
    required this.poiName,
    required this.areaName,
    this.isSelected = false, // Default value
  });

  // You can add a method to convert to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poiName': poiName,
      'areaName': areaName, // Storing color as an int
      'isSelected': isSelected,
    };
  }

  // You can add a factory constructor to create an instance from JSON
  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json['id'] ?? 0,
      poiName: json['poiName'] ?? "",
      areaName: json['areaName'] ?? "",
      isSelected: json['isSelected'] ?? false,
    );
  }
}
