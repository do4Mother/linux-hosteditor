import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum Env { dev, staging, prod }

extension EnvX on Env {
  String get label => switch (this) {
    Env.dev => 'Development',
    Env.staging => 'Staging',
    Env.prod => 'Production',
  };
  String get short => switch (this) {
    Env.dev => 'DEV',
    Env.staging => 'STG',
    Env.prod => 'PROD',
  };
  Color get accent => switch (this) {
    Env.dev => AppColors.envDev,
    Env.staging => AppColors.envStaging,
    Env.prod => AppColors.envProd,
  };
  Color get container => switch (this) {
    Env.dev => AppColors.envDevContainer,
    Env.staging => AppColors.envStagingContainer,
    Env.prod => AppColors.envProdContainer,
  };
}

class Host {
  final int id;
  final String hostname;
  final String target;
  final Env env;
  final bool active;
  final String note;
  final String updated;
  const Host({
    required this.id,
    required this.hostname,
    required this.target,
    required this.env,
    required this.active,
    this.note = '',
    required this.updated,
  });
  Host copyWith({String? hostname, String? target, Env? env, bool? active, String? note, String? updated}) => Host(
    id: id,
    hostname: hostname ?? this.hostname,
    target: target ?? this.target,
    env: env ?? this.env,
    active: active ?? this.active,
    note: note ?? this.note,
    updated: updated ?? this.updated,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'hostname': hostname,
    'target': target,
    'env': env.name,
    'active': active,
    'note': note,
    'updated': updated,
  };

  factory Host.fromJson(Map<String, dynamic> j) => Host(
    id: j['id'] as int,
    hostname: j['hostname'] as String,
    target: j['target'] as String,
    env: Env.values.firstWhere((e) => e.name == j['env']),
    active: j['active'] as bool,
    note: (j['note'] as String?) ?? '',
    updated: j['updated'] as String,
  );
}
