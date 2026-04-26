import 'package:flutter/material.dart';

class TokenPair {
  final String accessToken;
  final String refreshToken;
  TokenPair({required this.accessToken, required this.refreshToken});
  factory TokenPair.fromJson(Map<String, dynamic> j) =>
      TokenPair(accessToken: j['access_token'] as String, refreshToken: j['refresh_token'] as String);
}

class UserMe {
  final String id;
  final String email;
  final String displayName;
  final String? avatarColor;
  final String locale;
  final String timezone;
  final String preferredLlm;
  UserMe({
    required this.id,
    required this.email,
    required this.displayName,
    required this.preferredLlm,
    required this.locale,
    required this.timezone,
    this.avatarColor,
  });
  factory UserMe.fromJson(Map<String, dynamic> j) => UserMe(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['display_name'] as String,
        avatarColor: j['avatar_color'] as String?,
        locale: (j['locale'] as String?) ?? 'tr-TR',
        timezone: (j['timezone'] as String?) ?? 'Europe/Istanbul',
        preferredLlm: (j['preferred_llm'] as String?) ?? 'qwen3-coder-next',
      );
}

class Household {
  final String id;
  final String name;
  final String currency;
  final double? monthlyBudget;
  Household({required this.id, required this.name, required this.currency, this.monthlyBudget});
  factory Household.fromJson(Map<String, dynamic> j) => Household(
        id: j['id'] as String,
        name: j['name'] as String,
        currency: j['currency'] as String,
        monthlyBudget: j['monthly_budget'] == null ? null : double.parse(j['monthly_budget'].toString()),
      );
}

class HouseholdMember {
  final String userId;
  final String displayName;
  final String? nickname;
  final String role;
  final Color avatarColor;
  HouseholdMember({
    required this.userId,
    required this.displayName,
    required this.role,
    this.nickname,
    Color? avatarColor,
  }) : avatarColor = avatarColor ?? const Color(0xFFE8B5A0);

  String get short => (nickname ?? displayName).split(' ').first;

  factory HouseholdMember.fromJson(Map<String, dynamic> j) => HouseholdMember(
        userId: j['user_id'] as String,
        displayName: j['display_name'] as String,
        nickname: j['nickname'] as String?,
        role: j['role'] as String,
        avatarColor: _parseColor(j['avatar_color']),
      );
}

Color? _parseColor(dynamic v) {
  if (v is! String) return null;
  final h = v.replaceFirst('#', '');
  if (h.length != 6) return null;
  return Color(int.parse('FF$h', radix: 16));
}

class Category {
  final String id;
  final String slug;
  final String label;
  final String kind;       // 'expense' | 'income'
  final String icon;
  final Color color;
  final Color tint;
  final double? monthlyBudget;
  final int sortOrder;
  Category({
    required this.id,
    required this.slug,
    required this.label,
    required this.kind,
    required this.icon,
    required this.color,
    required this.tint,
    required this.sortOrder,
    this.monthlyBudget,
  });
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        slug: j['slug'] as String,
        label: j['label'] as String,
        kind: j['kind'] as String,
        icon: j['icon'] as String,
        color: _parseColor(j['color']) ?? const Color(0xFF7A6F65),
        tint: _parseColor(j['tint']) ?? const Color(0xFFEFE8DA),
        monthlyBudget: j['monthly_budget'] == null ? null : double.parse(j['monthly_budget'].toString()),
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class Transaction {
  final String id;
  final String kind;
  final double amount;
  final String currency;
  final String? merchant;
  final String? note;
  final DateTime occurredAt;
  final String source;
  final String status;
  final String? categoryId;
  final String? actorUserId;
  final double? aiConfidence;
  Transaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.source,
    required this.status,
    this.merchant,
    this.note,
    this.categoryId,
    this.actorUserId,
    this.aiConfidence,
  });
  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        kind: j['kind'] as String,
        amount: double.parse(j['amount'].toString()),
        currency: j['currency'] as String,
        merchant: j['merchant'] as String?,
        note: j['note'] as String?,
        occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
        source: j['source'] as String,
        status: j['status'] as String,
        categoryId: j['category_id'] as String?,
        actorUserId: j['actor_user_id'] as String?,
        aiConfidence: j['ai_confidence'] == null ? null : double.parse(j['ai_confidence'].toString()),
      );
}

class AIExtractedLine {
  final String? merchant;
  final double amount;
  final String currency;
  final String kind;
  final String? categorySlug;
  final String? actorNickname;
  final String? note;
  final double? confidence;
  AIExtractedLine({
    required this.amount,
    required this.currency,
    required this.kind,
    this.merchant,
    this.categorySlug,
    this.actorNickname,
    this.note,
    this.confidence,
  });
  factory AIExtractedLine.fromJson(Map<String, dynamic> j) => AIExtractedLine(
        merchant: j['merchant'] as String?,
        amount: double.parse(j['amount'].toString()),
        currency: (j['currency'] as String?) ?? 'TRY',
        kind: (j['kind'] as String?) ?? 'expense',
        categorySlug: j['category_slug'] as String?,
        actorNickname: j['actor_nickname'] as String?,
        note: j['note'] as String?,
        confidence: j['confidence'] == null ? null : double.parse(j['confidence'].toString()),
      );

  Map<String, dynamic> toCreatePayload({String? categoryId, String? actorUserId, String? aiJobId}) => {
        'kind': kind,
        'amount': amount,
        'currency': currency,
        if (merchant != null) 'merchant': merchant,
        if (note != null) 'note': note,
        if (categoryId != null) 'category_id': categoryId,
        if (actorUserId != null) 'actor_user_id': actorUserId,
        if (aiJobId != null) 'ai_job_id': aiJobId,
        if (confidence != null) 'ai_confidence': confidence,
        'source': 'voice',
      };
}

class AIExtractedReceipt {
  final String jobId;
  final String model;
  final List<AIExtractedLine> lines;
  final String? rawText;
  final String? summary;
  AIExtractedReceipt({
    required this.jobId,
    required this.model,
    required this.lines,
    this.rawText,
    this.summary,
  });
  factory AIExtractedReceipt.fromJson(Map<String, dynamic> j) => AIExtractedReceipt(
        jobId: j['job_id'] as String,
        model: j['model'] as String,
        lines: ((j['lines'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(AIExtractedLine.fromJson)
            .toList(),
        rawText: j['raw_text'] as String?,
        summary: j['summary'] as String?,
      );
}

class CategoryAggregate {
  final String? categorySlug;
  final String? categoryLabel;
  final Color? color;
  final String kind;
  final double total;
  final int count;
  CategoryAggregate({
    required this.kind,
    required this.total,
    required this.count,
    this.categorySlug,
    this.categoryLabel,
    this.color,
  });
  factory CategoryAggregate.fromJson(Map<String, dynamic> j) => CategoryAggregate(
        categorySlug: j['category_slug'] as String?,
        categoryLabel: j['category_label'] as String?,
        color: _parseColor(j['color']),
        kind: j['kind'] as String,
        total: double.parse(j['total'].toString()),
        count: (j['count'] as num).toInt(),
      );
}

class MemberAggregate {
  final String userId;
  final String? nickname;
  final Color? avatarColor;
  final double expense;
  final double income;
  MemberAggregate({
    required this.userId,
    required this.expense,
    required this.income,
    this.nickname,
    this.avatarColor,
  });
  factory MemberAggregate.fromJson(Map<String, dynamic> j) => MemberAggregate(
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String?,
        avatarColor: _parseColor(j['avatar_color']),
        expense: double.parse(j['expense'].toString()),
        income: double.parse(j['income'].toString()),
      );
}

class DailyPoint {
  final DateTime date;
  final double expense;
  final double income;
  DailyPoint({required this.date, required this.expense, required this.income});
  factory DailyPoint.fromJson(Map<String, dynamic> j) => DailyPoint(
        date: DateTime.parse(j['date'] as String),
        expense: double.parse(j['expense'].toString()),
        income: double.parse(j['income'].toString()),
      );
}

class Account {
  final String id;
  final String name;
  final String type;
  final String currency;
  final double startingBalance;
  final bool isArchived;
  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.startingBalance,
    required this.isArchived,
  });
  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        currency: j['currency'] as String,
        startingBalance: double.parse(j['starting_balance'].toString()),
        isArchived: j['is_archived'] as bool,
      );
}

class RecurringTemplate {
  final String id;
  final String label;
  final String kind;
  final double amount;
  final String currency;
  final String cadence;
  final int? dayOfPeriod;
  final String? categoryId;
  final String? actorUserId;
  final String? accountId;
  final String? note;
  final bool isPaused;
  RecurringTemplate({
    required this.id,
    required this.label,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.cadence,
    required this.isPaused,
    this.dayOfPeriod,
    this.categoryId,
    this.actorUserId,
    this.accountId,
    this.note,
  });
  factory RecurringTemplate.fromJson(Map<String, dynamic> j) => RecurringTemplate(
        id: j['id'] as String,
        label: j['label'] as String,
        kind: j['kind'] as String,
        amount: double.parse(j['amount'].toString()),
        currency: j['currency'] as String,
        cadence: j['cadence'] as String,
        dayOfPeriod: j['day_of_period'] as int?,
        categoryId: j['category_id'] as String?,
        actorUserId: j['actor_user_id'] as String?,
        accountId: j['account_id'] as String?,
        note: j['note'] as String?,
        isPaused: j['is_paused'] as bool,
      );
}

class AppNotification {
  final String id;
  final String kind;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;
  AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.body,
  });
  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        isRead: j['is_read'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class Report {
  final DateTime start;
  final DateTime end;
  final double totalExpense;
  final double totalIncome;
  final double balance;
  final List<CategoryAggregate> byCategory;
  final List<MemberAggregate> byMember;
  final List<DailyPoint> daily;
  Report({
    required this.start,
    required this.end,
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.byCategory,
    required this.byMember,
    required this.daily,
  });
  factory Report.fromJson(Map<String, dynamic> j) => Report(
        start: DateTime.parse(j['period']['start'] as String).toLocal(),
        end: DateTime.parse(j['period']['end'] as String).toLocal(),
        totalExpense: double.parse(j['total_expense'].toString()),
        totalIncome: double.parse(j['total_income'].toString()),
        balance: double.parse(j['balance'].toString()),
        byCategory: ((j['by_category'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(CategoryAggregate.fromJson)
            .toList(),
        byMember: ((j['by_member'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(MemberAggregate.fromJson)
            .toList(),
        daily: ((j['daily'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(DailyPoint.fromJson)
            .toList(),
      );
}
