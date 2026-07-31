import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/data/models/client_address_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/add_address_dialog.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_type.dart';
import 'package:alrasmarket/features/company/presentation/models/negotiation_type.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_product_images_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_requests_fields_widget.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddOrderView extends StatefulWidget {
  const AddOrderView({super.key});

  @override
  State<AddOrderView> createState() => _AddOrderViewState();
}

class _AddOrderViewState extends State<AddOrderView> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _notesController = TextEditingController();
  NegotiationType _negotiationType = NegotiationType.negotiable;
  final _getAddressesUseCase = sl<GetClientAddressesUseCase>();
  List<ClientAddressModel> _addresses = [];
  String? _selectedAddressId;
  String? _selectedAddressLabel;
  bool _isAddressesLoading = false;
  DateTime? _pickupDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CreateAdCubit>();
      cubit.setSelectedType(CreateAdType.requests.label);
      _loadAddresses();
    });
  }

  Future<void> _loadAddresses() async {
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) return;

    setState(() => _isAddressesLoading = true);

    final result = await _getAddressesUseCase(token: token);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isAddressesLoading = false);
        AppToast.showError(context, failure.message);
      },
      (addresses) {
        setState(() {
          _addresses = addresses;
          _isAddressesLoading = false;
          if (addresses.isEmpty) {
            _selectedAddressId = null;
            _selectedAddressLabel = null;
            return;
          }

          final stillSelected = addresses.any(
            (address) => address.addressId == _selectedAddressId,
          );
          if (!stillSelected) {
            _selectedAddressId = addresses.first.addressId;
            _selectedAddressLabel = addresses.first.label;
          }
        });
      },
    );
  }

  Future<void> _showAddAddressDialog() async {
    final created = await AddAddressDialog.show(context);
    if (created == true && mounted) {
      await _loadAddresses();
    }
  }

  Widget _buildAddressSelector() {
    if (_addresses.length > 1) {
      final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
      final ids = _addresses.map((address) => address.addressId).toList();

      return DropdownButtonFormField<String>(
        value: ids.contains(_selectedAddressId) ? _selectedAddressId : null,
        isExpanded: true,
        hint: Text(
          S.of(context).deliveryAddress,
          style: TextStyle(
            color: const Color(0xFF333333).withValues(alpha: 0.4),
            fontFamily: fontFamily,
            fontSize: 14.sp,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: LightColor.greyTextColor,
          size: 20.sp,
        ),
        dropdownColor: Colors.white,
        menuMaxHeight: 320.h,
        style: TextStyle(
          color: LightColor.greyTextColor,
          fontFamily: fontFamily,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: LightColor.defaultColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: LightColor.defaultColor,
              width: 1.5,
            ),
          ),
        ),
        items: _addresses
            .map(
              (address) => DropdownMenuItem(
                value: address.addressId,
                child: Text(
                  address.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          final selected = _addresses.firstWhere(
            (address) => address.addressId == value,
          );
          setState(() {
            _selectedAddressId = selected.addressId;
            _selectedAddressLabel = selected.label;
          });
        },
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
        border: Border.all(
          color: LightColor.defaultColor,
          width: 1.5,
        ),
      ),
      child: Text(
        _addresses.first.label,
        style: TextStyle(
          color: LightColor.defaultColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _specificationsController.dispose();
    _quantityController.dispose();
    _targetPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _publishRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedAddressLabel == null || _selectedAddressLabel!.isEmpty) {
      AppToast.showError(context, S.of(context).selectDeliveryAddress);
      if (_addresses.isEmpty) {
        await _showAddAddressDialog();
      }
      return;
    }

    await context.read<CreateAdCubit>().submitRequestOrder(
      productName: _productNameController.text,
      specifications: _specificationsController.text,
      quantity: _quantityController.text,
      unit: context.read<CreateAdCubit>().state.selectedUnit,
      targetPrice: _targetPriceController.text,
      negotiationType: _negotiationType,
      additionalNotes: _notesController.text,
      address: _selectedAddressLabel,
      addressId: _selectedAddressId,
      requiredDeliveryDate: _pickupDate,
    );
  }

  void _clearLocalForm() {
    _productNameController.clear();
    _specificationsController.clear();
    _quantityController.clear();
    _targetPriceController.clear();
    _notesController.clear();
    setState(() {
      _negotiationType = NegotiationType.negotiable;
      _selectedAddressId = _addresses.isNotEmpty ? _addresses.first.addressId : null;
      _selectedAddressLabel =
          _addresses.isNotEmpty ? _addresses.first.label : null;
      _pickupDate = null;
    });
    _formKey.currentState?.reset();
  }

  /// Same picker as Create Ad: files are persisted, compressed and uploaded to
  /// Cloudflare R2 as drafts right after selection, not on submit.
  Widget _buildMediaSection() {
    final cubit = context.read<CreateAdCubit>();
    return BlocBuilder<CreateAdCubit, CreateAdFormState>(
      buildWhen: (previous, current) =>
          previous.productImages != current.productImages ||
          previous.isCompressingMedia != current.isCompressingMedia ||
          previous.mediaCompressionProgress != current.mediaCompressionProgress ||
          previous.mediaCompressionLabel != current.mediaCompressionLabel,
      builder: (context, state) {
        return CreateAdProductImagesWidget(
          productImages: state.productImages,
          onPickTap: () => cubit.pickProductImages(context),
          onRemove: cubit.removeProductImage,
          isCompressingMedia: state.isCompressingMedia,
          mediaCompressionProgress: state.mediaCompressionProgress,
          mediaCompressionLabel: state.mediaCompressionLabel,
        );
      },
    );
  }

  Future<void> _pickPickupDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _pickupDate = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateAdCubit, CreateAdFormState>(
      listenWhen: (previous, current) =>
          previous.submitErrorMessage != current.submitErrorMessage ||
          previous.submitSuccessMessage != current.submitSuccessMessage,
      listener: (context, state) {
        final cubit = context.read<CreateAdCubit>();
        if (state.submitSuccessMessage != null) {
          final createdProductId = state.submitNavigateProductId;
          cubit.clearSubmitFeedback();
          // The cubit reset clears the type, so re-arm it for the next request.
          cubit.setSelectedType(CreateAdType.requests.label);
          _clearLocalForm();
          context.push(
            AppRoutes.kConfirmCircalView,
            extra: {'productId': createdProductId},
          );
        } else if (state.submitErrorMessage != null) {
          AppToast.showError(context, state.submitErrorMessage!);
          cubit.clearSubmitFeedback();
        }
      },
      child: BlocBuilder<ClintCubit, ClintStates>(
        builder: (context, state) {
          return Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SearchHeader(
                  title: S.of(context).createOrder,
                  isBackButton: false,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                        // Media first so the R2 upload runs while the rest of
                        // the form is filled in (same flow as Create Ad).
                        _buildMediaSection(),
                        SizedBox(height: 12.h),
                        Container(
                          decoration: const BoxDecoration(),
                          padding: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                S.of(context).productInformation,
                                style: TextStyle(
                                  fontSize: 16,
                                  letterSpacing: 0,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.15),
                                      offset: Offset(0, 0),
                                      blurRadius: 4,
                                    ),
                                  ],
                                  color: const Color.fromRGBO(255, 255, 255, 1),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      decoration: const BoxDecoration(),
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            decoration: const BoxDecoration(),
                                            padding: EdgeInsets.zero,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  S.of(context).productName,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    color: LightColor
                                                        .greyTextColor,
                                                    fontSize: 14,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                SizedBox(height: 12.h),
                                                Container(
                                                  height: 46.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          LightColor.lightGrey,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        _productNameController,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return S
                                                            .of(context)
                                                            .thisFieldIsRequired;
                                                      }
                                                      return null;
                                                    },
                                                    style: TextStyle(
                                                      color: LightColor
                                                          .greyTextColor,

                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      height: 1.5,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          S.of(context).examplePremiumIranianSaffron,
                                                      hintStyle: TextStyle(
                                                        color: LightColor
                                                            .hintColor,
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        height: 1.5,
                                                      ),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 8.h,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20.h),
                                          Container(
                                            decoration: const BoxDecoration(),
                                            padding: EdgeInsets.zero,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  S.of(context).requiredSpecifications,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    color: LightColor
                                                        .greyTextColor,

                                                    fontSize: 14,
                                                    letterSpacing: 0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                SizedBox(height: 12.h),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          LightColor.lightGrey,

                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                  ),
                                                  child: TextFormField(
                                                    controller:
                                                        _specificationsController,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value
                                                              .trim()
                                                              .isEmpty) {
                                                        return S
                                                            .of(context)
                                                            .thisFieldIsRequired;
                                                      }
                                                      return null;
                                                    },
                                                    maxLines: 4,
                                                    minLines: 3,
                                                    style: TextStyle(
                                                      color: LightColor
                                                          .greyTextColor,
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      height: 1.5,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          S.of(context).enterTheRequiredSpecificationsInDetail,
                                                      hintStyle: TextStyle(
                                                        color: LightColor
                                                            .hintColor,
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        height: 1.5,
                                                      ),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 12.h,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.15),
                                offset: Offset(0, 0),
                                blurRadius: 4,
                              ),
                            ],
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                S.of(context).requiredQuantity,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: LightColor.greyTextColor,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                height: 46.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: LightColor.lightGrey,
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                ),
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return S
                                          .of(context)
                                          .thisFieldIsRequired;
                                    }
                                    if (int.tryParse(value.trim()) ==
                                        null) {
                                      return S
                                          .of(context)
                                          .enterValidQuantity;
                                    }
                                    return null;
                                  },
                                  style: TextStyle(
                                    color: LightColor.greyTextColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: S.of(context).enterQuantity,
                                    hintStyle: TextStyle(
                                      color: LightColor.hintColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.normal,
                                      height: 1.5,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.15),
                                offset: Offset(0, 0),
                                blurRadius: 4,
                              ),
                            ],
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: CreateAdRequestsFieldsWidget(
                            quantityController: _quantityController,
                            priceController: _targetPriceController,
                            selectedNegotiationType: _negotiationType,
                            onNegotiationChanged: (type) {
                              setState(() => _negotiationType = type);
                            },
                            fromBuyer: true,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          decoration: const BoxDecoration(),
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).delivery,
                                style: TextStyle(
                                  color: LightColor.greyTextColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.normal,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.15),
                                      offset: Offset(0, 0),
                                      blurRadius: 4,
                                    ),
                                  ],
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.of(context).deliveryAddress,
                                      style: TextStyle(
                                        color: LightColor.greyTextColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.normal,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    if (_isAddressesLoading)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (_addresses.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: Text(
                                          S.of(context).noSavedAddresses,
                                          style: TextStyle(
                                            color: LightColor.hintColor,
                                            fontSize: 14.sp,
                                            height: 1.5,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: _buildAddressSelector(),
                                      ),
                                    InkWell(
                                      onTap: _showAddAddressDialog,
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: LightColor.defaultColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              size: 18.sp,
                                              color: LightColor.defaultColor,
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              S.of(context).addNewAddress,
                                              style: TextStyle(
                                                color: LightColor.defaultColor,
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.normal,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Text(
                                      S.of(context).pickupDateOptional,
                                      style: TextStyle(
                                        color: LightColor.greyTextColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.normal,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    InkWell(
                                      onTap: _pickPickupDate,
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          color: Colors.white,
                                          border: Border.all(
                                            color: LightColor.lightGrey,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _pickupDate == null
                                                  ? 'April 4'
                                                  : '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year}',
                                              style: TextStyle(
                                                color: LightColor.greyTextColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.normal,
                                                height: 1.5,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18.sp,
                                              color: LightColor.greyTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          decoration: const BoxDecoration(),
                          padding: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                S.of(context).additionalNotes,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: LightColor.greyTextColor,
                                  fontSize: 16.sp,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.normal,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: LightColor.lightGrey,
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: TextFormField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: 4,
                                  style: TextStyle(
                                    color: LightColor.greyTextColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        S.of(context).addAnyNotesOrSpecialRequirementsOptional,
                                    hintStyle: TextStyle(
                                      color: LightColor.hintColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.normal,
                                      height: 1.5,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: const Color.fromRGBO(224, 241, 255, 1),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                    S.of(context).yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: LightColor.greyTextColor,
                                    fontSize: 14.sp,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Icon(
                                Icons.info_outline_rounded,
                                color: LightColor.defaultColor,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        BlocBuilder<CreateAdCubit, CreateAdFormState>(
                          builder: (context, adState) {
                            return PrimaryButton(
                              isLoading: adState.isSubmitting,
                              onPressed: adState.isSubmitting
                                  ? null
                                  : _publishRequest,
                              text: S.of(context).publishRequest,
                            );
                          },
                        ),
                        SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
