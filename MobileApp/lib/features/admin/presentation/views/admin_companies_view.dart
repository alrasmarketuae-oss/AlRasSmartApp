import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/admin/data/admin_companies_remote.dart';
import 'package:alrasmarket/features/admin/data/admin_company_model.dart';
import 'package:alrasmarket/core/widgets/app_search_field.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AdminCompaniesView extends StatefulWidget {
  const AdminCompaniesView({super.key});

  @override
  State<AdminCompaniesView> createState() => _AdminCompaniesViewState();
}

class _AdminCompaniesViewState extends State<AdminCompaniesView> {
  final _remote = AdminCompaniesRemote();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final List<AdminCompanyModel> _companies = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_loadMore());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _search) return;
      _search = next;
      unawaited(_reload());
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final token = AuthService.instance.currentToken ?? '';
      final page = await _remote.fetchCompanies(
        token: token,
        page: 1,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _companies
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() {
        _loading = false;
        _error = isAr ? 'تعذر تحميل الشركات.' : 'Could not load companies.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final token = AuthService.instance.currentToken ?? '';
      final page = await _remote.fetchCompanies(
        token: token,
        page: _page + 1,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _companies.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _openCompany(AdminCompanyModel company) {
    context.push(
      AppRoutes.kMyAdsView,
      extra: {
        'actingOwnerId': company.id,
        'companyName': company.displayName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        SearchHeader(
          title: isAr ? 'الشركات' : 'Companies',
          isBackButton: false,
          isSearch: true,
          showImageSearch: false,
          searchMode: AppSearchMode.local,
          searchController: _searchController,
          searchHint: isAr ? 'ابحث باسم الشركة' : 'Search company name',
          onLocalSearchChanged: _onSearchChanged,
          onSearchSubmitted: (value) {
            _debounce?.cancel();
            _search = value.trim();
            unawaited(_reload());
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            color: LightColor.defaultColor,
            child: _buildBody(isAr),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isAr) {
    if (_loading && _companies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _companies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.subtitle(context),
            ),
          ),
          TextButton(
            onPressed: _reload,
            child: Text(S.of(context).retry),
          ),
        ],
      );
    }
    if (_companies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          Text(
            isAr ? 'لا توجد شركات مطابقة.' : 'No matching companies.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.subtitle(context),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: _companies.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        if (index >= _companies.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        final company = _companies[index];
        return _CompanyTile(
          company: company,
          onTap: () => _openCompany(company),
        );
      },
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company, required this.onTap});

  final AdminCompanyModel company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final imageUrl = ApiConstants.resolveMediaUrl(company.imagePath);
    final typeLabel = company.isShipping
        ? (isAr ? 'شركة شحن' : 'Shipping')
        : company.isCustomer
            ? (isAr ? 'عميل شركة' : 'Company customer')
            : (isAr ? 'مورد' : 'Supplier');

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 48.w,
                        height: 48.w,
                        color: LightColor.defaultColor.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: LightColor.defaultColor,
                          size: 24.sp,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 48.w,
                        height: 48.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48.w,
                          height: 48.w,
                          color: LightColor.defaultColor.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: LightColor.defaultColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.subtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtitle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
