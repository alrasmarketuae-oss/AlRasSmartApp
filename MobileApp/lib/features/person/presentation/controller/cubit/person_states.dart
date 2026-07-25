import 'package:equatable/equatable.dart';

abstract class PersonStates extends Equatable {
  const PersonStates();

  @override
  List<Object?> get props => [];
}

class PersonInitialState extends PersonStates {}

class PersonTabState extends PersonStates {
  final int index;

  const PersonTabState(this.index);

  @override
  List<Object?> get props => [index];
}

class PersonErrorState extends PersonStates {
  final String message;

  const PersonErrorState(this.message);

  @override
  List<Object?> get props => [message];
}