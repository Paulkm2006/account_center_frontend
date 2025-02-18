import 'package:account_center_frontend/models/user.dart';
import 'package:account_center_frontend/services/otp_service.dart';
import 'package:account_center_frontend/services/account_service.dart';
import 'package:flutter/material.dart';

import 'package:flutter_iconpicker/IconPicker/Packs/MaterialDefault.dart';


class ListAccount {
  final String name;
  final String id;
  final String avatar;
  final int updatedAt;

  ListAccount({required this.name, required this.id, required this.avatar, required this.updatedAt});

  factory ListAccount.fromJson(Map<String, dynamic> json) {
    return ListAccount(
      name: json['name'],
      id: json['id'],
      avatar: json['avatar'],
      updatedAt: json['updated_at'],
    );
  }

  Widget getAvatar() {
    if (avatar.startsWith('material:')) {
      final iconCodePoint = avatar.substring(9);
      return Icon(defaultIcons[iconCodePoint]!.data, size: 64,);
    } else if (avatar.startsWith('url:')) {
      final imageUrl = avatar.substring(4);
      return Image.network(imageUrl);
    }
    return const Icon(Icons.person);
  }
}

class Account {
  final String id;
  final String name;
  final String avatar;
  final int updatedAt;
  final String account;
  final String password;
  
  final int createdAt;
  final User creator;
  final User updator;
  final String? authType;
  final String? comment;
  final String? authId;
  final String? loginUrl;

  Account({required this.id, required this.name, required this.avatar, required this.updatedAt, required this.creator, required this.updator, required this.account, required this.password, required this.createdAt, required this.comment, required this.authId, required this.authType, required this.loginUrl});

  static Future<Account> fromJson(Map<String, dynamic> json) async {
    final int upd = int.parse(json['updated_at']['\$date']['\$numberLong']);
    final int cre = int.parse(json['created_at']['\$date']['\$numberLong']);
    String? authId, authType;
    try {
      final t = json['auth_id'];
      authId = t != null ? t['\$oid'] : null;
      authType = authId != null ? await TwoFactorAuthService().getAuthType(authId) : null;
    } catch (e) {
      authId = null;
      authType = null;
    }
    return Account(
      id: json['_id']["\$oid"],
      name: json['name'],
      avatar: json['avatar'],
      updatedAt: upd,
      creator: User.fromJson(json['created_by']),
      updator: User.fromJson(json['updated_by']),
      account: json['account'],
      password: json['password'],
      createdAt: cre,
      comment: json['comment'],
      authId: authId,
      authType: authType,
      loginUrl: json['login_url'],
    );
  }

  Widget getAvatar() {
    if (avatar.startsWith('material:')) {
      final iconCodePoint = avatar.substring(9);
      return Icon(defaultIcons[iconCodePoint]!.data, size: 100,);
    } else if (avatar.startsWith('url:')) {
      final imageUrl = avatar.substring(4);
      return Image.network(imageUrl);
    }
    return const Icon(Icons.person);
  }

  Future<bool> delete() async {
    return await AccountService().deleteAccount(id);
  }

}

