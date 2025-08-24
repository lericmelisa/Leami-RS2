import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? username;
  UserRole? role;

  @JsonKey(fromJson: _fromJsonDate, toJson: _toJsonDate)
  DateTime? createdAt;

  @JsonKey(fromJson: _fromJsonDate, toJson: _toJsonDate)
  DateTime? lastLoginAt;

  String? phoneNumber;
  String? token;

  @JsonKey(fromJson: _fromJsonDate, toJson: _toJsonDate)
  DateTime? expiration;

  String? jobTitle;

  @JsonKey(fromJson: _fromJsonDate, toJson: _toJsonDate)
  DateTime? hireDate;

  String? note;

  /// Može biti null ako nema slike
  String? userImage;

  User({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
    this.role,
    this.createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    this.token,
    this.expiration,
    this.userImage,
    this.jobTitle,
    this.hireDate,
    this.note,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // 🔹 Helperi za konverziju
  static DateTime? _fromJsonDate(Object? date) {
    if (date == null) return null;
    if (date is String && date.isNotEmpty) {
      return DateTime.tryParse(date);
    }
    return null;
  }

  static String? _toJsonDate(DateTime? date) => date?.toIso8601String();
}
