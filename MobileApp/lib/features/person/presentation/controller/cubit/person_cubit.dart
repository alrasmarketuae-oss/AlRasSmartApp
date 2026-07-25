import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'person_states.dart';

class PersonCubit extends Cubit<PersonStates> {
  PersonCubit({
    required this.authService,
  }) : super(PersonInitialState());

  final AuthService authService;

  static PersonCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  void setTab(int index) {
    currentIndex = index;
    emit(PersonTabState(index));
    if (index == 0) {
      CatalogSyncService.instance.onHomeTabSelected();
    }
  }
}
