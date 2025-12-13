import 'package:equatable/equatable.dart';

class SwitchState extends Equatable {
  final bool switchValue;

  const SwitchState({this.switchValue = false});

  SwitchState copyWith({bool? switchValue}) {
    return SwitchState(
      switchValue: switchValue ?? this.switchValue,
    );
  }

  @override
  List<Object?> get props => [switchValue];
}

