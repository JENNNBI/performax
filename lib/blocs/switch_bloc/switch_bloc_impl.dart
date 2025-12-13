import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'switch_event.dart';
import 'switch_state.dart';

class SwitchBloc extends HydratedBloc<SwitchEvent, SwitchState> {
  SwitchBloc() : super(const SwitchState(switchValue: false)) {
    on<SwitchOnEvent>(_onSwitchOn);
    on<SwitchOffEvent>(_onSwitchOff);
  }

  void _onSwitchOn(SwitchOnEvent event, Emitter<SwitchState> emit) {
    emit(state.copyWith(switchValue: true));
  }

  void _onSwitchOff(SwitchOffEvent event, Emitter<SwitchState> emit) {
    emit(state.copyWith(switchValue: false));
  }

  @override
  SwitchState? fromJson(Map<String, dynamic> json) {
    return SwitchState(
      switchValue: json['switchValue'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic>? toJson(SwitchState state) {
    return {
      'switchValue': state.switchValue,
    };
  }
}

