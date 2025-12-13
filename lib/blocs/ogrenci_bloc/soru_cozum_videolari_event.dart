import 'package:equatable/equatable.dart';

abstract class SoruCozumVideolariEvent extends Equatable {
  const SoruCozumVideolariEvent();

  @override
  List<Object?> get props => [];
}

class LoadSolutionVideosEvent extends SoruCozumVideolariEvent {
  const LoadSolutionVideosEvent();
}

