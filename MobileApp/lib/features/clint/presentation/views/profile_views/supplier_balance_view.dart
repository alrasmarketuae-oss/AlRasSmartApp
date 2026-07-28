import 'dart:async';

import 'package:alrasmarket/core/serveses/supplier_balance_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/widgets/app_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class SupplierBalanceView extends StatefulWidget {
  const SupplierBalanceView({super.key});

  @override
  State<SupplierBalanceView> createState() => _SupplierBalanceViewState();
}

class _SupplierBalanceViewState extends State<SupplierBalanceView>
    with WidgetsBindingObserver {
  static const _liveRefreshInterval = Duration(seconds: 1);
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  SupplierBalanceStatement? _statement;
  List<UserIbanModel> _ibans = const [];
  List<WithdrawalRequestModel> _withdrawals = const [];
  Timer? _liveRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startLiveRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveRefresh();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLiveRefresh();
      unawaited(_refreshLiveData());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopLiveRefresh();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _statement = null;
      _ibans = const [];
      _withdrawals = const [];
    });
    try {
      final results = await Future.wait([
        SupplierBalanceService.instance.fetchStatement(),
        SupplierBalanceService.instance.fetchIbans(),
        SupplierBalanceService.instance.fetchWithdrawals(),
      ]);
      if (!mounted) return;
      setState(() {
        _statement = results[0] as SupplierBalanceStatement;
        _ibans = results[1] as List<UserIbanModel>;
        _withdrawals = results[2] as List<WithdrawalRequestModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = S.of(context).failedToLoadBalance;
        _loading = false;
      });
    }
  }

  void _startLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(_liveRefreshInterval, (_) {
      unawaited(_refreshLiveData());
    });
  }

  void _stopLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
  }

  Future<void> _refreshLiveData() async {
    if (!mounted || _loading || _submitting) return;

    try {
      final results = await Future.wait([
        SupplierBalanceService.instance.fetchStatement(),
        SupplierBalanceService.instance.fetchIbans(),
        SupplierBalanceService.instance.fetchWithdrawals(),
      ]);
      if (!mounted) return;

      final statement = results[0] as SupplierBalanceStatement;
      final ibans = results[1] as List<UserIbanModel>;
      final withdrawals = results[2] as List<WithdrawalRequestModel>;
      final balanceChanged = _statement?.balance != statement.balance;
      final withdrawalCountChanged = _withdrawals.length != withdrawals.length;

      setState(() {
        _statement = statement;
        _ibans = ibans;
        _withdrawals = withdrawals;
        _error = null;
      });

      if (balanceChanged || withdrawalCountChanged) {
        // Force the visible balance/requests to reflect admin actions immediately.
      }
    } catch (_) {
      // Keep the last visible state; next tick will retry.
    }
  }

  Future<void> _addIbanFlow() async {
    final result = await showModalBottomSheet<_IbanFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddIbanSheet(),
    );
    if (result == null) return;

    setState(() => _submitting = true);
    try {
      final ibans = await SupplierBalanceService.instance.addIban(
        iban: result.iban,
        accountHolderName: result.accountHolderName,
        bankName: result.bankName,
      );
      if (!mounted) return;
      setState(() {
        _ibans = ibans;
      });
      await _load();
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        Localizations.localeOf(context).languageCode.startsWith('ar')
            ? 'تمت إضافة الآيبان'
            : 'IBAN added successfully',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _withdrawFlow() async {
    if (_statement == null) return;
    if (_ibans.isEmpty) {
      await _addIbanFlow();
      if (!mounted) return;
      if (_ibans.isEmpty) return;
    }

    final result = await showModalBottomSheet<_WithdrawFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WithdrawSheet(
        balance: _statement!.balance,
        ibans: _ibans,
      ),
    );
    if (result == null) return;

    setState(() => _submitting = true);
    try {
      final withdrawals = await SupplierBalanceService.instance.createWithdrawal(
        userIbanId: result.userIbanId,
        amount: result.amount,
        notes: result.notes,
      );
      if (!mounted) return;
      setState(() {
        _withdrawals = withdrawals;
      });
      await _load();
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        Localizations.localeOf(context).languageCode.startsWith('ar')
            ? 'تم إرسال طلب السحب'
            : 'Withdrawal request sent',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final currency = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              const AppHeader(),
              SizedBox(height: 20.h),
              Stack(
                children: [
                  Center(
                    child: Text(
                      S.of(context).accountStatement,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: LightColor.defaultColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          isAr ? AppAssets.backIconAR : AppAssets.backIconEN,
                          width: 24.w,
                          height: 24.h,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                SizedBox(height: 12.h),
                                TextButton(
                                  onPressed: _load,
                                  child: Text(S.of(context).refresh),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF5F5F5),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        S.of(context).currentBalance,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        currency
                                            .format(_statement?.balance ?? 0),
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: LightColor.defaultColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _submitting ? null : _addIbanFlow,
                                        child: Text(isAr ? 'إضافة IBAN' : 'Add IBAN'),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _submitting ? null : _withdrawFlow,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: LightColor.defaultColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          isAr ? 'طلب سحب' : 'Request withdrawal',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_ibans.isNotEmpty) ...[
                                  SizedBox(height: 20.h),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      isAr ? 'الحسابات البنكية' : 'IBANs',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ..._ibans.map(
                                    (iban) => Container(
                                      margin: EdgeInsets.only(bottom: 8.h),
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.r),
                                        color: const Color(0xffF8F8F8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  iban.iban,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (iban.isDefault)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8.w,
                                                    vertical: 4.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: LightColor.defaultColor,
                                                    borderRadius:
                                                        BorderRadius.circular(20.r),
                                                  ),
                                                  child: Text(
                                                    isAr ? 'الافتراضي' : 'Default',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if ((iban.accountHolderName ?? '')
                                                  .isNotEmpty ||
                                              (iban.bankName ?? '').isNotEmpty)
                                            Text(
                                              [
                                                if ((iban.accountHolderName ?? '')
                                                    .isNotEmpty)
                                                  iban.accountHolderName!,
                                                if ((iban.bankName ?? '').isNotEmpty)
                                                  iban.bankName!,
                                              ].join(' - '),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 20.h),
                                if (_withdrawals.isNotEmpty) ...[
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      isAr ? 'طلبات السحب' : 'Withdrawal requests',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ..._withdrawals.map((request) {
                                    final dateText = request.requestedAtUtc == null
                                        ? ''
                                        : DateFormat.yMMMd().add_jm().format(
                                            request.requestedAtUtc!.toLocal(),
                                          );
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 10.h),
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xffE8E8E8),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  request.ibanSnapshot,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  isAr
                                                      ? request.statusNameAr
                                                      : request.statusNameEn,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                if (dateText.isNotEmpty)
                                                  Text(
                                                    dateText,
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            currency.format(request.amount),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 8.h),
                                ],
                                if ((_statement?.items.isEmpty ?? true))
                                  Padding(
                                    padding: EdgeInsets.only(top: 40.h),
                                    child: Center(
                                      child: Text(
                                        S.of(context).noBalanceTransactions,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ..._statement!.items.map((entry) {
                                    final positive = entry.isDeposit;
                                    final typeLabel = isAr
                                        ? (entry.entryTypeNameAr.isNotEmpty
                                            ? entry.entryTypeNameAr
                                            : (positive
                                                ? S.of(context).balanceDeposit
                                                : S
                                                    .of(context)
                                                    .balanceWithdrawal))
                                        : (entry.entryTypeNameEn.isNotEmpty
                                            ? entry.entryTypeNameEn
                                            : (positive
                                                ? S.of(context).balanceDeposit
                                                : S
                                                    .of(context)
                                                    .balanceWithdrawal));
                                    final reason = isAr
                                        ? (entry.reasonAr ?? entry.reasonEn)
                                        : (entry.reasonEn ?? entry.reasonAr);
                                    final dateText = entry.createdAtUtc == null
                                        ? ''
                                        : DateFormat.yMMMd().add_jm().format(
                                            entry.createdAtUtc!.toLocal(),
                                          );
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xffE8E8E8),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  typeLabel,
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${positive ? '+' : ''}${currency.format(entry.amount)}',
                                                style: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: positive
                                                      ? const Color(0xff1B7F3A)
                                                      : const Color(0xffC62828),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (entry.orderId != null) ...[
                                            SizedBox(height: 6.h),
                                            Text(
                                              S.of(context).balanceOrderLabel(
                                                entry.orderId.toString(),
                                              ),
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                          if (reason != null &&
                                              reason.trim().isNotEmpty) ...[
                                            SizedBox(height: 4.h),
                                            Text(
                                              reason,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                          if (dateText.isNotEmpty) ...[
                                            SizedBox(height: 6.h),
                                            Text(
                                              dateText,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IbanFormResult {
  final String iban;
  final String? accountHolderName;
  final String? bankName;

  const _IbanFormResult({
    required this.iban,
    required this.accountHolderName,
    required this.bankName,
  });
}

class _WithdrawFormResult {
  final String userIbanId;
  final double amount;
  final String? notes;

  const _WithdrawFormResult({
    required this.userIbanId,
    required this.amount,
    required this.notes,
  });
}

class _AddIbanSheet extends StatefulWidget {
  const _AddIbanSheet();

  @override
  State<_AddIbanSheet> createState() => _AddIbanSheetState();
}

class _AddIbanSheetState extends State<_AddIbanSheet> {
  final _ibanController = TextEditingController();
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAr ? 'إضافة IBAN' : 'Add IBAN',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          TextField(controller: _ibanController, decoration: InputDecoration(labelText: isAr ? 'IBAN' : 'IBAN')),
          TextField(controller: _nameController, decoration: InputDecoration(labelText: isAr ? 'اسم صاحب الحساب' : 'Account holder name')),
          TextField(controller: _bankController, decoration: InputDecoration(labelText: isAr ? 'اسم البنك' : 'Bank name')),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LightColor.defaultColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  _IbanFormResult(
                    iban: _ibanController.text.trim(),
                    accountHolderName: _nameController.text.trim().isEmpty
                        ? null
                        : _nameController.text.trim(),
                    bankName: _bankController.text.trim().isEmpty
                        ? null
                        : _bankController.text.trim(),
                  ),
                );
              },
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  final double balance;
  final List<UserIbanModel> ibans;

  const _WithdrawSheet({required this.balance, required this.ibans});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  late String _selectedIbanId;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIbanId = widget.ibans.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAr ? 'طلب سحب' : 'Request withdrawal',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedIbanId,
            items: widget.ibans
                .map(
                  (iban) => DropdownMenuItem<String>(
                    value: iban.id,
                    child: Text(iban.iban),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedIbanId = value);
              }
            },
            decoration: InputDecoration(labelText: isAr ? 'اختر IBAN' : 'Select IBAN'),
          ),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isAr ? 'المبلغ' : 'Amount',
              helperText:
                  '${isAr ? 'المتاح' : 'Available'}: ${widget.balance.toStringAsFixed(2)} AED',
            ),
          ),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: isAr ? 'ملاحظات' : 'Notes'),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LightColor.defaultColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amount = double.tryParse(_amountController.text.trim());
                if (amount == null || amount <= 0) return;
                Navigator.pop(
                  context,
                  _WithdrawFormResult(
                    userIbanId: _selectedIbanId,
                    amount: amount,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  ),
                );
              },
              child: Text(isAr ? 'إرسال الطلب' : 'Submit request'),
            ),
          ),
        ],
      ),
    );
  }
}
