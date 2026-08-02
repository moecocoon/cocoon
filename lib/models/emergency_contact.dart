class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }
}