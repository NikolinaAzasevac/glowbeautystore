class SavedAddressModel {
  const SavedAddressModel({
    required this.addressId,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
    required this.zipCode,
    required this.isPrimary,
  });

  final String addressId;
  final String fullName;
  final String phoneNumber;
  final String addressLine;
  final String city;
  final String zipCode;
  final bool isPrimary;

  factory SavedAddressModel.fromMap(Map<String, dynamic> data) {
    return SavedAddressModel(
      addressId: (data['addressId'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      addressLine: (data['addressLine'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      zipCode: (data['zipCode'] ?? '').toString(),
      isPrimary: data['isPrimary'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'city': city,
      'zipCode': zipCode,
      'isPrimary': isPrimary,
    };
  }
}
