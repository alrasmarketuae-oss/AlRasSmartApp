import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:alrasmarket/features/shipping_company/data/repository/shipping_company_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'shipping_company_states.dart';

class ShippingCompanyCubit extends Cubit<ShippingCompanyStates> {
  ShippingCompanyCubit({
    required this.authService,
    required this.repository,
  }) : super(ShippingCompanyInitialState());

  final AuthService authService;
  final ShippingCompanyRepository repository;

  int tabIndex = 0;
  int get currentIndex => tabIndex;
  ShippingCompanyDashboardModel? dashboard;

  static ShippingCompanyCubit get(context) => BlocProvider.of(context);

  void setTab(int index) {
    tabIndex = index;
    final current = dashboard;
    if (current != null) {
      emit(ShippingCompanyLoadedState(dashboard: current, tabIndex: index));
    } else {
      emit(ShippingCompanyTabState(index));
    }
  }

  Future<void> loadDashboard({bool force = false}) async {
    if (!force && dashboard != null) {
      emit(ShippingCompanyLoadedState(dashboard: dashboard!, tabIndex: tabIndex));
      return;
    }

    emit(ShippingCompanyLoadingState());
    final result = await repository.getDashboard();
    result.fold(
      (failure) => emit(ShippingCompanyErrorState(failure.message)),
      (data) {
        dashboard = data;
        emit(ShippingCompanyLoadedState(dashboard: data, tabIndex: tabIndex));
      },
    );
  }

  Future<bool> saveProfile({
    required String companyName,
    required String phoneNumber,
    required String commercialRegister,
    required String taxNumber,
  }) async {
    emit(ShippingCompanyActionLoadingState(tabIndex, dashboard: dashboard));
    final result = await repository.updateProfile({
      'companyName': companyName,
      'fullName': companyName,
      'phoneNumber': phoneNumber,
      'commercialRegister': commercialRegister,
      'taxNumber': taxNumber,
    });

    return result.fold(
      (failure) {
        emit(ShippingCompanyErrorState(failure.message));
        return false;
      },
      (profile) async {
        await authService.updateProfileData(fullName: companyName);
        authService.phone = phoneNumber;
        await loadDashboard(force: true);
        return true;
      },
    );
  }

  Future<bool> createPost(Map<String, dynamic> payload) async {
    emit(ShippingCompanyActionLoadingState(tabIndex, dashboard: dashboard));
    final result = await repository.createPost(payload);
    return result.fold(
      (failure) {
        emit(ShippingCompanyErrorState(failure.message));
        return false;
      },
      (_) async {
        await loadDashboard(force: true);
        return true;
      },
    );
  }

  Future<bool> updatePost(int postId, Map<String, dynamic> payload) async {
    emit(ShippingCompanyActionLoadingState(tabIndex, dashboard: dashboard));
    final result = await repository.updatePost(postId, payload);
    return result.fold(
      (failure) {
        emit(ShippingCompanyErrorState(failure.message));
        return false;
      },
      (_) async {
        await loadDashboard(force: true);
        return true;
      },
    );
  }

  Future<bool> deletePost(int postId) async {
    emit(ShippingCompanyActionLoadingState(tabIndex, dashboard: dashboard));
    final result = await repository.deletePost(postId);
    return result.fold(
      (failure) {
        emit(ShippingCompanyErrorState(failure.message));
        return false;
      },
      (_) async {
        await loadDashboard(force: true);
        return true;
      },
    );
  }
}
