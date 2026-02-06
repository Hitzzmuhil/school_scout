class School {
  String id;
  String name;
  String? address;
  String? city;
  String? state;
  String? zip;
  String? phone;
  String? website;
  double? latitude;
  double? longitude;
  String? schoolType;
  String? grades;
  int? enrollment;
  String? ncesId;

  School({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.phone,
    this.website,
    this.latitude,
    this.longitude,
    this.schoolType,
    this.grades,
    this.enrollment,
    this.ncesId,
  });

  static School fromJson(Map<String, dynamic> json) {
    // print("Processing school: " + json['name']);

    return School(
      id: json['id'].toString(), 
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
      phone: json['phone'],
      website: json['website'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      schoolType: json['school_type'],
      grades: json['grades'],
      enrollment: json['enrollment'],
      ncesId: json['nces_id'],
    );
  }
  Map<String, dynamic> toJson() {
    // print("Converting school to JSON: " + name);
    return {
      'id': id,
      'nces_id': ncesId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'phone': phone,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'school_type': schoolType,
      'enrollment': enrollment,
    };
  }
}
