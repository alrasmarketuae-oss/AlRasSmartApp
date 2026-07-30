import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/clint/presentation/views/home_view.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/user_bottom_nav_bar.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../clint/presentation/views/my_orders_view.dart';
import '../../../clint/presentation/views/profile_view.dart' show ProfileView;
import '../controller/cubit/person_states.dart';

class PersonHomeLayout extends StatefulWidget {
  const PersonHomeLayout({super.key});

  @override
  State<PersonHomeLayout> createState() => _PersonHomeLayoutState();
}

class _PersonHomeLayoutState extends State<PersonHomeLayout> {
  @override
  void initState() {
    super.initState();
    NotificationsService.instance.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonStates>(
      buildWhen: (prev, curr) {
        if (curr is! PersonTabState) return false;
        if (prev is! PersonTabState) return true;
        return prev.index != curr.index;
      },
      builder: (context, state) {
        final cubit = PersonCubit.get(context);
        final screens = [
          HomeView(key: ValueKey('person_home'), isPerson: true),
          MyOrdersView(),
          ProfileView(),
        ];
        return ScrollAwareBottomNavScaffold(
          tabIndex: cubit.currentIndex,
          body: IndexedStack(
            index: cubit.currentIndex,
            children: screens,
          ),
          bottomNavigationBar: ListenableBuilder(
            listenable: NotificationsService.instance,
            builder: (context, _) {
              return UserBottomNavBar(
                currentIndex: cubit.currentIndex,
                onTap: (index) =>
                    context.read<PersonCubit>().setTab(index),
                context: context,
                isPerson: true,
                showMyAds: false,
                unreadBadgeCount:
                    NotificationsService.instance.unreadCount,
              );
            },
          ),
        );
      },
    );
  }
}
