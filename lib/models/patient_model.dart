class PatientModel {
  int? id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  PatientModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'PatientModel(id: $id, firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber)';
  }
}
