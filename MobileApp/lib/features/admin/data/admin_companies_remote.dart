import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/features/admin/data/admin_company_model.dart';

class AdminCompaniesPage {
  const AdminCompaniesPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AdminCompanyModel> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class AdminCompaniesRemote {
  Future<AdminCompaniesPage> fetchCompanies({
    required String token,
    required int page,
    String? search,
    int pageSize = 30,
  }) async {
    final response = await DioHelper.getData(
      url: ApiConstants.adminUsersEndPoint,
      token: token,
      query: {
        'page': page,
        'pageSize': pageSize,
        'companiesOnly': true,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final data = response?.data;
    if (data is! Map) {
      throw Exception('Invalid companies response');
    }

    final rawItems = data['items'] ?? data['Items'];
    final items = <AdminCompanyModel>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          final company = AdminCompanyModel.fromJson(row);
          if (company.id.isNotEmpty && company.displayName.isNotEmpty) {
            items.add(company);
          }
        } else if (row is Map) {
          final company = AdminCompanyModel.fromJson(
            Map<String, dynamic>.from(row),
          );
          if (company.id.isNotEmpty && company.displayName.isNotEmpty) {
            items.add(company);
          }
        }
      }
    }

    final currentPage = _asInt(data['page'] ?? data['Page']) ?? page;
    final totalPages = _asInt(data['totalPages'] ?? data['TotalPages']) ?? 1;
    return AdminCompaniesPage(
      items: items,
      page: currentPage,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
