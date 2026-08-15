import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/shipping_card.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_location_details_section.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/widgets/shipping_company_widgets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ShippingAdFormView extends StatefulWidget {
  const ShippingAdFormView({
    super.key,
    this.existingPost,
    this.embedded = false,
    this.onPublishSuccess,
    this.onCancel,
  });

  final ShippingCompanyPostModel? existingPost;
  final bool embedded;
  final VoidCallback? onPublishSuccess;
  final VoidCallback? onCancel;

  bool get isEdit => existingPost != null;

  @override
  State<ShippingAdFormView> createState() => _ShippingAdFormViewState();
}

class _ShippingAdFormViewState extends State<ShippingAdFormView> {
  final _formKey = GlobalKey<FormState>();
  final _getGeoPortsByCountryUseCase = sl<GetGeoPortsByCountryUseCase>();

  String? _fromCountry;
  String? _fromPort;
  String? _toCountry;
  String? _toPort;
  List<String> _fromPorts = const [];
  List<String> _toPorts = const [];
  bool _isLoadingFromPorts = false;
  bool _isLoadingToPorts = false;

  final Map<String, ({String country, List<String> ports})> _portsCache = {};

  final _minDays = TextEditingController();
  final _maxDays = TextEditingController();
  final _price20 = TextEditingController();
  final _price40 = TextEditingController();
  final _details = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    if (post != null) {
      _fromCountry =
          post.fromCountry.trim().isNotEmpty ? post.fromCountry.trim() : null;
      _fromPort = post.fromPort.trim().isNotEmpty ? post.fromPort.trim() : null;
      _toCountry =
          post.toCountry.trim().isNotEmpty ? post.toCountry.trim() : null;
      _toPort = post.toPort.trim().isNotEmpty ? post.toPort.trim() : null;
      _minDays.text = post.minDurationDays?.toString() ?? '';
      _maxDays.text = post.maxDurationDays?.toString() ?? '';
      if (post.container20ftPriceUsd != null) {
        _price20.text = ThousandsNumberInput.format(
          post.container20ftPriceUsd!,
          allowDecimal: true,
        );
      }
      if (post.container40ftPriceUsd != null) {
        _price40.text = ThousandsNumberInput.format(
          post.container40ftPriceUsd!,
          allowDecimal: true,
        );
      }
      _details.text = post.details;

      if (_fromCountry != null) {
        _loadPorts(
          country: _fromCountry!,
          isFrom: true,
          preselectPort: _fromPort,
        );
      }
      if (_toCountry != null) {
        _loadPorts(
          country: _toCountry!,
          isFrom: false,
          preselectPort: _toPort,
        );
      }
    }
  }

  @override
  void dispose() {
    _minDays.dispose();
    _maxDays.dispose();
    _price20.dispose();
    _price40.dispose();
    _details.dispose();
    super.dispose();
  }

  void _onFromCountryChanged(String? country) {
    setState(() {
      _fromCountry = country;
      _fromPort = null;
      _fromPorts = const [];
      _isLoadingFromPorts = country != null && country.isNotEmpty;
    });
    if (country != null && country.isNotEmpty) {
      _loadPorts(country: country, isFrom: true);
    }
  }

  void _onToCountryChanged(String? country) {
    setState(() {
      _toCountry = country;
      _toPort = null;
      _toPorts = const [];
      _isLoadingToPorts = country != null && country.isNotEmpty;
    });
    if (country != null && country.isNotEmpty) {
      _loadPorts(country: country, isFrom: false);
    }
  }

  Future<void> _loadPorts({
    required String country,
    required bool isFrom,
    String? preselectPort,
  }) async {
    final cacheKey = country.trim().toLowerCase();
    if (_portsCache.containsKey(cacheKey)) {
      final cached = _portsCache[cacheKey]!;
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _fromCountry = cached.country;
          _fromPorts = cached.ports;
          _fromPort = _resolvePortSelection(cached.ports, preselectPort);
          _isLoadingFromPorts = false;
        } else {
          _toCountry = cached.country;
          _toPorts = cached.ports;
          _toPort = _resolvePortSelection(cached.ports, preselectPort);
          _isLoadingToPorts = false;
        }
      });
      return;
    }

    final result = await _getGeoPortsByCountryUseCase(country);
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        if (isFrom) {
          _isLoadingFromPorts = false;
        } else {
          _isLoadingToPorts = false;
        }
      }),
      (response) {
        final portNames =
            response.ports.map((port) => port.displayName).toList();
        final normalizedCountry =
            response.country.isNotEmpty ? response.country : country;
        _portsCache[cacheKey] = (
          country: normalizedCountry,
          ports: portNames,
        );

        setState(() {
          if (isFrom) {
            _fromCountry = normalizedCountry;
            _fromPorts = portNames;
            _fromPort = _resolvePortSelection(portNames, preselectPort);
            _isLoadingFromPorts = false;
          } else {
            _toCountry = normalizedCountry;
            _toPorts = portNames;
            _toPort = _resolvePortSelection(portNames, preselectPort);
            _isLoadingToPorts = false;
          }
        });
      },
    );
  }

  String? _resolvePortSelection(List<String> ports, String? preferredPort) {
    final trimmed = preferredPort?.trim() ?? '';
    if (trimmed.isNotEmpty && ports.contains(trimmed)) {
      return trimmed;
    }
    return null;
  }

  Map<String, dynamic> _buildPayload(String phone) {
    return {
      'fromCountryName': _fromCountry?.trim() ?? '',
      'fromPortName': _fromPort?.trim() ?? '',
      'toCountryName': _toCountry?.trim() ?? '',
      'toPortName': _toPort?.trim() ?? '',
      'phoneNumber': phone,
      'container20ftPriceUsd':
          ThousandsNumberInput.parseDouble(_price20.text.trim()),
      'container40ftPriceUsd':
          ThousandsNumberInput.parseDouble(_price40.text.trim()),
      'minDurationDays': int.tryParse(_minDays.text.trim()),
      'maxDurationDays': int.tryParse(_maxDays.text.trim()),
      'details': _details.text.trim(),
    };
  }

  Future<void> _submit() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price20 = ThousandsNumberInput.parseDouble(_price20.text.trim());
    final price40 = ThousandsNumberInput.parseDouble(_price40.text.trim());
    if ((price20 != null && price20 <= 0) ||
        (price40 != null && price40 <= 0)) {
      AppToast.showError(context, s.enterPrice);
      return;
    }

    final cubit = context.read<ShippingCompanyCubit>();
    final phone = cubit.dashboard?.phoneNumber ?? '';
    if (phone.isEmpty) {
      AppToast.showError(context, s.thisFieldIsRequired);
      return;
    }

    setState(() => _submitting = true);
    final payload = _buildPayload(phone);
    final ok = widget.isEdit
        ? await cubit.updatePost(widget.existingPost!.id, payload)
        : await cubit.createPost(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      if (widget.embedded) {
        AppToast.showSuccess(context, s.savedSuccessfully);
        widget.onPublishSuccess?.call();
      } else {
        AppToast.showSuccess(context, s.savedSuccessfully);
        context.pop();
      }
    }
  }

  Widget _buildFormFields(S s) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              ShippingFormSectionLabel(label: s.fromLabel),
              CreateAdLocationDetailsSection(
                countryLabel: s.enterCountry,
                portLabel: s.loadingPort,
                selectedCountry: _fromCountry,
                ports: _fromPorts,
                selectedPort: _fromPort,
                isPortsLoading: _isLoadingFromPorts,
                onCountryChanged: _onFromCountryChanged,
                onPortChanged: (value) => setState(() => _fromPort = value),
              ),
              SizedBox(height: 16.h),
              ShippingFormSectionLabel(label: s.toLabel),
              CreateAdLocationDetailsSection(
                countryLabel: s.destinationCountry,
                portLabel: s.destinationPort,
                selectedCountry: _toCountry,
                ports: _toPorts,
                selectedPort: _toPort,
                isPortsLoading: _isLoadingToPorts,
                onCountryChanged: _onToCountryChanged,
                onPortChanged: (value) => setState(() => _toPort = value),
              ),
              SizedBox(height: 8.h),
              ShippingFormSectionLabel(label: s.shippingDurationDays),
              Row(
                children: [
                  Expanded(
                    child: ShippingFormField(
                      hint: s.fromDay,
                      controller: _minDays,
                      suffix: s.dayUnit,
                      icon: Icons.schedule_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ShippingFormField(
                      hint: s.toDay,
                      controller: _maxDays,
                      suffix: s.dayUnit,
                      icon: Icons.schedule_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              ShippingFormSectionLabel(label: s.price20ftLabel),
              ShippingFormField(
                hint: s.enterPrice,
                controller: _price20,
                prefix: s.dollar,
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s٬]')),
                  ThousandsSeparatorInputFormatter.price(),
                ],
              ),
              ShippingFormSectionLabel(label: s.price40ftLabel),
              ShippingFormField(
                hint: s.enterPrice,
                controller: _price40,
                prefix: s.dollar,
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s٬]')),
                  ThousandsSeparatorInputFormatter.price(),
                ],
              ),
              ShippingFormSectionLabel(label: s.details),
              ShippingFormField(
                hint: s.enterDetails,
                controller: _details,
                icon: Icons.notes_outlined,
                maxLines: 4,
              ),
              SizedBox(height: 12.h),
          ShippingPrimaryButton(
            label: s.publish,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final form = _buildFormFields(s);

    if (widget.embedded) {
      return form;
    }

    final companyName = context.read<ShippingCompanyCubit>().dashboard?.companyName ??
        s.shippingCompany;

    return ShippingCompanyShell(
      companyName: companyName,
      title: widget.isEdit ? s.editShippingAd : s.addShippingAd,
      showBack: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        child: form,
      ),
    );
  }
}

class ManageShippingOffersView extends StatelessWidget {
  const ManageShippingOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cubit = context.read<ShippingCompanyCubit>();
    final dashboard = cubit.dashboard;
    final posts = dashboard?.posts ?? const [];

    return ShippingCompanyShell(
      companyName: dashboard?.companyName ?? s.shippingCompany,
      title: s.manageShippingOffers,
      showBack: true,
      child: posts.isEmpty
          ? Center(child: Text(s.noShippingOffers))
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              itemCount: posts.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _ManageOfferCard(post: post);
              },
            ),
    );
  }
}

class _ManageOfferCard extends StatefulWidget {
  const _ManageOfferCard({required this.post});

  final ShippingCompanyPostModel post;

  @override
  State<_ManageOfferCard> createState() => _ManageOfferCardState();
}

class _ManageOfferCardState extends State<_ManageOfferCard> {
  bool _showPhone = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final post = widget.post;
    final cardData = ShippingCardData(
      carrierName: post.publisherName.isNotEmpty
          ? post.publisherName
          : (context.read<ShippingCompanyCubit>().dashboard?.companyName ?? ''),
      details: post.details,
      onTap: () => context.push(
        AppRoutes.kShippingPostDetailsView,
        extra: InternationalShippingPostModel.fromShippingCompany(
          post,
          publisherName: context.read<ShippingCompanyCubit>().dashboard?.companyName ??
              post.publisherName,
        ),
      ),
      routeCountryFrom: post.fromCountry,
      routeCountryTo: post.toCountry,
      routePortFrom: post.fromPort,
      routePortTo: post.toPort,
      daysMin: post.minDurationDays?.toString() ?? '—',
      daysMax: post.maxDurationDays?.toString() ?? '—',
      phoneMasked: _showPhone
          ? post.phoneNumber
          : _maskPhone(post.phoneNumber),
      price40f: ShippingCardHelpers.formatUsdPrice(post.container40ftPriceUsd),
      price20f: ShippingCardHelpers.formatUsdPrice(post.container20ftPriceUsd),
      onShowNumber: () => setState(() => _showPhone = true),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
            child: ShippingCard(data: cardData, compact: true),
          ),
          if (post.details.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Text('${s.details}: ${post.details}'),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Text('${s.details}: ${s.noDetailsAvailable}'),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(s.delete),
                          content: Text(s.deleteShippingAdConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(s.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(s.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final ok = await context
                          .read<ShippingCompanyCubit>()
                          .deletePost(post.id);
                      if (ok && context.mounted) {
                        AppToast.showSuccess(context, s.deletedSuccessfully);
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: Text(s.delete),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(
                        AppRoutes.kShippingEditAdView,
                        extra: post,
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: Text(s.edit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kShippingGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length <= 6) return phone;
    return '${phone.substring(0, phone.length - 6)}*** ***';
  }
}
