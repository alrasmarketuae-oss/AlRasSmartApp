import 'package:equatable/equatable.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';

abstract class ShippingCompanyStates extends Equatable {
  const ShippingCompanyStates();

  @override
  List<Object?> get props => [];
}

class ShippingCompanyInitialState extends ShippingCompanyStates {}

class ShippingCompanyTabState extends ShippingCompanyStates {
  const ShippingCompanyTabState(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class ShippingCompanyLoadingState extends ShippingCompanyStates {}

class ShippingCompanyLoadedState extends ShippingCompanyStates {
  const ShippingCompanyLoadedState({
    required this.dashboard,
    required this.tabIndex,
  });

  final ShippingCompanyDashboardModel dashboard;
  final int tabIndex;

  @override
  List<Object?> get props => [dashboard, tabIndex];
}

class ShippingCompanyActionLoadingState extends ShippingCompanyStates {
  const ShippingCompanyActionLoadingState(this.tabIndex, {this.dashboard});

  final int tabIndex;
  final ShippingCompanyDashboardModel? dashboard;

  @override
  List<Object?> get props => [tabIndex, dashboard];
}

class ShippingCompanyErrorState extends ShippingCompanyStates {
  const ShippingCompanyErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ShippingCompanyPostSavedState extends ShippingCompanyStates {
  const ShippingCompanyPostSavedState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
