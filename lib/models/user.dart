import 'package:flutter/material.dart';

class User {
  final String nickname;
  final String role;
  final String group;
  final String email;
  final String phone;
  final Widget avatar;

  User(
      {required this.nickname,
      required this.role,
      required this.group,
      required this.email,
      required this.phone,
      required this.avatar});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nickname: json['nickname'],
      role: json['rol'],
      group: json['group'],
      email: json['email'],
      phone: json['phone'],
      avatar: Image.network(json['picture']),
    );
  }
}
