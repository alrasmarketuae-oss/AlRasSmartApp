import 'package:alrasmarket/core/cache/api_cache_keys.dart';
import 'package:alrasmarket/core/cache/api_cache_store.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class SavedAddressesView extends StatefulWidget {
  const SavedAddressesView({super.key});

  @override
  State<SavedAddressesView> createState() => _SavedAddressesViewState();
}

class _SavedAddressesViewState extends State<SavedAddressesView> {
  final _getAddressesUseCase = sl<GetClientAddressesUseCase>();
  final _deleteAddressUseCase = sl<DeleteClientAddressUseCase>();
  List<ClientAddressModel> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses(forceRefresh: true);
  }

  Future<void> _loadAddresses({bool forceRefresh = false}) async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    if (forceRefresh) {
      final userId = AuthService.instance.currentUserID;
      if (userId != null && userId.isNotEmpty) {
        await ApiCacheStore.instance.remove(ApiCacheKeys.userAddresses(userId));
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _getAddressesUseCase(token: token);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _addresses = [];
        _error = failure.message;
        _loading = false;
      }),
      (items) => setState(() {
        _addresses = items;
        _error = null;
        _loading = false;
      }),
    );
  }

  /// Saved addresses are not tied to retail shipping, so any country is allowed.
  Future<void> _addAddress() async {
    final created = await AddAddressDialog.show(context);
    if (created == true) {
      await _loadAddresses(forceRefresh: true);
    }
  }

  Future<void> _editAddress(ClientAddressModel address) async {
    final updated = await AddAddressDialog.show(context, existing: address);
    if (updated == true) {
      await _loadAddresses(forceRefresh: true);
    }
  }

  Future<void> _deleteAddress(ClientAddressModel address) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(s.deleteAddress),
        content: Text(s.deleteAddressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    final result = await _deleteAddressUseCase(
      addressId: address.addressId,
      token: token,
    );
    if (!mounted) return;

    result.fold(
      (failure) => AppToast.showError(context, failure.message),
      (_) => _loadAddresses(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchHeader(title: S.of(context).savedAddresses),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadAddresses(forceRefresh: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAddress,
        backgroundColor: LightColor.defaultColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          Center(
            child: TextButton(
              onPressed: () => _loadAddresses(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Center(
            child: Text(
              S.of(context).noSavedAddresses,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: LightColor.greyTextColor,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final headline = [address.cityName, address.countryDisplayName(isArabic)]
            .where((e) => e.trim().isNotEmpty)
            .join(', ');
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                AppAssets.profileLocationIcon,
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  LightColor.defaultColor,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headline.isNotEmpty)
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (address.typeDisplayName(isArabic).isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        address.typeDisplayName(isArabic),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: LightColor.defaultColor,
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      address.formattedAddressLine,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: LightColor.greyTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editAddress(address),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20.sp,
                  color: LightColor.greyTextColor,
                ),
                tooltip: S.of(context).edit,
              ),
              IconButton(
                onPressed: () => _deleteAddress(address),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20.sp,
                  color: Colors.red.shade400,
                ),
                tooltip: S.of(context).delete,
              ),
            ],
          ),
        );
      },
    );
  }
}
