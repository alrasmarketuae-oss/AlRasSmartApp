import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';

class SupplierBalanceStatement {
  final double balance;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<SupplierBalanceEntry> items;

  const SupplierBalanceStatement({
    required this.balance,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory SupplierBalanceStatement.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    final items = <SupplierBalanceEntry>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            SupplierBalanceEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return SupplierBalanceStatement(
      balance: _toDouble(json['balance'] ?? json['Balance']),
      page: _toInt(json['page'] ?? json['Page'], 1),
      pageSize: _toInt(json['pageSize'] ?? json['PageSize'], 20),
      totalCount: _toInt(json['totalCount'] ?? json['TotalCount'], 0),
      totalPages: _toInt(json['totalPages'] ?? json['TotalPages'], 0),
      items: items,
    );
  }
}

class SupplierBalanceEntry {
  final String id;
  final int? orderId;
  final double amount;
  final int entryType;
  final String entryTypeNameEn;
  final String entryTypeNameAr;
  final String? reasonEn;
  final String? reasonAr;
  final DateTime? createdAtUtc;

  const SupplierBalanceEntry({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.entryType,
    required this.entryTypeNameEn,
    required this.entryTypeNameAr,
    required this.reasonEn,
    required this.reasonAr,
    required this.createdAtUtc,
  });

  factory SupplierBalanceEntry.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['orderId'] ?? json['OrderId'];
    return SupplierBalanceEntry(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      orderId: orderRaw == null ? null : int.tryParse(orderRaw.toString()),
      amount: _toDouble(json['amount'] ?? json['Amount']),
      entryType: _toInt(json['entryType'] ?? json['EntryType'], 0),
      entryTypeNameEn:
          (json['entryTypeNameEn'] ?? json['EntryTypeNameEn'] ?? '').toString(),
      entryTypeNameAr:
          (json['entryTypeNameAr'] ?? json['EntryTypeNameAr'] ?? '').toString(),
      reasonEn: (json['reasonEn'] ?? json['ReasonEn'])?.toString(),
      reasonAr: (json['reasonAr'] ?? json['ReasonAr'])?.toString(),
      createdAtUtc: DateTime.tryParse(
        (json['createdAtUtc'] ?? json['CreatedAtUtc'] ?? '').toString(),
      ),
    );
  }

  bool get isDeposit => entryType == 1 || amount > 0;
}

class UserIbanModel {
  final String id;
  final String iban;
  final String? accountHolderName;
  final String? bankName;
  final bool isDefault;

  const UserIbanModel({
    required this.id,
    required this.iban,
    required this.accountHolderName,
    required this.bankName,
    required this.isDefault,
  });

  factory UserIbanModel.fromJson(Map<String, dynamic> json) {
    return UserIbanModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      iban: (json['iban'] ?? json['Iban'] ?? '').toString(),
      accountHolderName:
          (json['accountHolderName'] ?? json['AccountHolderName'])?.toString(),
      bankName: (json['bankName'] ?? json['BankName'])?.toString(),
      isDefault: (json['isDefault'] ?? json['IsDefault']) == true,
    );
  }
}

class WithdrawalRequestModel {
  final String id;
  final double amount;
  final int statusId;
  final String statusNameEn;
  final String statusNameAr;
  final String ibanSnapshot;
  final DateTime? requestedAtUtc;
  final DateTime? completedAtUtc;

  const WithdrawalRequestModel({
    required this.id,
    required this.amount,
    required this.statusId,
    required this.statusNameEn,
    required this.statusNameAr,
    required this.ibanSnapshot,
    required this.requestedAtUtc,
    required this.completedAtUtc,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      amount: _toDouble(json['amount'] ?? json['Amount']),
      statusId: _toInt(json['statusId'] ?? json['StatusId'], 0),
      statusNameEn:
          (json['statusNameEn'] ?? json['StatusNameEn'] ?? '').toString(),
      statusNameAr:
          (json['statusNameAr'] ?? json['StatusNameAr'] ?? '').toString(),
      ibanSnapshot:
          (json['ibanSnapshot'] ?? json['IbanSnapshot'] ?? '').toString(),
      requestedAtUtc: DateTime.tryParse(
        (json['requestedAtUtc'] ?? json['RequestedAtUtc'] ?? '').toString(),
      ),
      completedAtUtc: DateTime.tryParse(
        (json['completedAtUtc'] ?? json['CompletedAtUtc'] ?? '').toString(),
      ),
    );
  }
}

class SupplierBalanceService {
  SupplierBalanceService._();
  static final SupplierBalanceService instance = SupplierBalanceService._();

  Future<double> fetchBalance() async {
    final response = await DioHelper.getData(
      url: ApiConstants.supplierBalanceEndPoint,
      query: _cacheBustQuery(),
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception('Failed to load balance');
    }
    final data = Map<String, dynamic>.from(response!.data as Map);
    return _toDouble(data['balance'] ?? data['Balance']);
  }

  Future<SupplierBalanceStatement> fetchStatement({
    int page = 1,
    int pageSize = 30,
  }) async {
    final response = await DioHelper.getData(
      url: ApiConstants.supplierBalanceStatementEndPoint,
      query: {'page': page, 'pageSize': pageSize, ..._cacheBustQuery()},
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception('Failed to load balance statement');
    }
    return SupplierBalanceStatement.fromJson(
      Map<String, dynamic>.from(response!.data as Map),
    );
  }

  Future<List<UserIbanModel>> fetchIbans() async {
    final response = await DioHelper.getData(
      url: ApiConstants.supplierBalanceIbansEndPoint,
      query: _cacheBustQuery(),
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception('Failed to load IBANs');
    }
    final data = Map<String, dynamic>.from(response!.data as Map);
    final rawItems = data['items'] ?? data['Items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => UserIbanModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<UserIbanModel>> addIban({
    required String iban,
    String? accountHolderName,
    String? bankName,
    bool isDefault = true,
  }) async {
    final response = await DioHelper.postData(
      url: ApiConstants.supplierBalanceIbansEndPoint,
      token: AuthService.instance.currentToken,
      data: {
        'iban': iban,
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'isDefault': isDefault,
      },
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception(_extractErrorMessage(response?.data, 'Failed to add IBAN'));
    }
    final data = Map<String, dynamic>.from(response!.data as Map);
    final rawItems = data['items'] ?? data['Items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => UserIbanModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<WithdrawalRequestModel>> fetchWithdrawals() async {
    final response = await DioHelper.getData(
      url: ApiConstants.supplierBalanceWithdrawalsEndPoint,
      query: _cacheBustQuery(),
      token: AuthService.instance.currentToken,
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception('Failed to load withdrawals');
    }
    final data = Map<String, dynamic>.from(response!.data as Map);
    final rawItems = data['items'] ?? data['Items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map(
          (item) =>
              WithdrawalRequestModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<WithdrawalRequestModel>> createWithdrawal({
    required String userIbanId,
    required double amount,
    String? notes,
  }) async {
    final response = await DioHelper.postData(
      url: ApiConstants.supplierBalanceWithdrawalsEndPoint,
      token: AuthService.instance.currentToken,
      data: {'userIbanId': userIbanId, 'amount': amount, 'notes': notes},
    );
    if (response?.statusCode != 200 || response?.data is! Map) {
      throw Exception(
        _extractErrorMessage(response?.data, 'Failed to create withdrawal'),
      );
    }
    final data = Map<String, dynamic>.from(response!.data as Map);
    final rawItems = data['items'] ?? data['Items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map(
          (item) =>
              WithdrawalRequestModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _extractErrorMessage(dynamic raw, String fallback) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final message = map['message'] ?? map['Message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }
  }
  return fallback;
}

Map<String, dynamic> _cacheBustQuery() => {
  '_ts': DateTime.now().millisecondsSinceEpoch,
};
