enum UserType { passenger, driver, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserType userType;
  final DateTime createdAt;
  final DateTime? lastActive;
  final Map<String, dynamic>? preferences;
  final String? profileImageUrl;
  
  // Driver specific fields
  final String? licenseNumber;
  final String? busId;
  final bool? isOnDuty;
  
  // Passenger specific fields
  final List<String>? favoriteRoutes;
  final Map<String, dynamic>? notificationPreferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.createdAt,
    this.lastActive,
    this.preferences,
    this.profileImageUrl,
    this.licenseNumber,
    this.busId,
    this.isOnDuty,
    this.favoriteRoutes,
    this.notificationPreferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      userType: UserType.values.firstWhere(
        (type) => type.toString() == 'UserType.${json['userType']}',
        orElse: () => UserType.passenger,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      lastActive: json['lastActive'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActive'])
          : null,
      preferences: json['preferences'],
      profileImageUrl: json['profileImageUrl'],
      licenseNumber: json['licenseNumber'],
      busId: json['busId'],
      isOnDuty: json['isOnDuty'],
      favoriteRoutes: json['favoriteRoutes'] != null 
          ? List<String>.from(json['favoriteRoutes'])
          : null,
      notificationPreferences: json['notificationPreferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'preferences': preferences,
      'profileImageUrl': profileImageUrl,
      'licenseNumber': licenseNumber,
      'busId': busId,
      'isOnDuty': isOnDuty,
      'favoriteRoutes': favoriteRoutes,
      'notificationPreferences': notificationPreferences,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    UserType? userType,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
    String? profileImageUrl,
    String? licenseNumber,
    String? busId,
    bool? isOnDuty,
    List<String>? favoriteRoutes,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      busId: busId ?? this.busId,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  bool get isDriver => userType == UserType.driver;
  bool get isPassenger => userType == UserType.passenger;
  bool get isAdmin => userType == UserType.admin;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
