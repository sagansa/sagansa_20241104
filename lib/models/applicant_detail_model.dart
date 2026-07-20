class ApplicantDetail {
  final int? id;
  final int? userId;
  final String? nickname;
  final bool? isExperienced;
  final String? phone;
  final String? address;
  final String? birthPlace;
  final String? birthDate;
  final String? gender;
  final String? nik;
  final String? religion;
  final String? maritalStatus;
  final int? childrenCount;
  final String? educationLevel;
  final String? educationMajor;
  final String? fatherName;
  final String? motherName;
  final String? homeLocation;
  final String? emergencyPhone;
  final String? emergencyName;
  final String? driverLicense;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? status;
  final String? joinDate;
  final String? position;
  final String? ktpHtmlUrl;
  final String? selfieHtmlUrl;

  ApplicantDetail({
    this.id,
    this.userId,
    this.nickname,
    this.isExperienced,
    this.phone,
    this.address,
    this.birthPlace,
    this.birthDate,
    this.gender,
    this.nik,
    this.religion,
    this.maritalStatus,
    this.childrenCount,
    this.educationLevel,
    this.educationMajor,
    this.fatherName,
    this.motherName,
    this.homeLocation,
    this.emergencyPhone,
    this.emergencyName,
    this.driverLicense,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.status,
    this.joinDate,
    this.position,
    this.ktpHtmlUrl,
    this.selfieHtmlUrl,
  });

  factory ApplicantDetail.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return ApplicantDetail();
    }
    final rawExp = json['is_experienced'];
    final bool? isExp = rawExp is bool
        ? rawExp
        : (rawExp is int ? rawExp == 1 : null);
    return ApplicantDetail(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      nickname: json['nickname'] as String?,
      isExperienced: isExp,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      birthPlace: json['birth_place'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      nik: json['nik'] as String?,
      religion: json['religion'] as String?,
      maritalStatus: json['marital_status'] as String?,
      childrenCount: json['children_count'] as int?,
      educationLevel: json['education_level'] as String?,
      educationMajor: json['education_major'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      homeLocation: json['home_location'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      emergencyName: json['emergency_name'] as String?,
      driverLicense: json['driver_license'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankName: json['bank_name'] as String?,
      status: json['status'] as String?,
      joinDate: json['join_date'] as String?,
      position: json['position'] as String?,
      ktpHtmlUrl: json['ktp_image_url'] as String?,
      selfieHtmlUrl: json['selfie_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (nickname != null) 'nickname': nickname,
      if (isExperienced != null) 'is_experienced': isExperienced,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (nik != null) 'nik': nik,
      if (religion != null) 'religion': religion,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (childrenCount != null) 'children_count': childrenCount,
      if (educationLevel != null) 'education_level': educationLevel,
      if (educationMajor != null) 'education_major': educationMajor,
      if (fatherName != null) 'father_name': fatherName,
      if (motherName != null) 'mother_name': motherName,
      if (homeLocation != null) 'home_location': homeLocation,
      if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
      if (emergencyName != null) 'emergency_name': emergencyName,
      if (driverLicense != null) 'driver_license': driverLicense,
      if (bankAccountName != null) 'bank_account_name': bankAccountName,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (bankName != null) 'bank_name': bankName,
    };
  }

  /// True bila field non-rekening terkunci (hanya rekening yg bisa diubah).
  bool get isLocked =>
      status != null &&
      ['submitted', 'accepted', 'reviewed', 'rejected'].contains(status) &&
      joinDate != null &&
      joinDate!.isNotEmpty;
}
