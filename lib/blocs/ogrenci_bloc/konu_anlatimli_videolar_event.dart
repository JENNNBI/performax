import 'package:equatable/equatable.dart';

abstract class KonuAnlatimliVideolarEvent extends Equatable {
  const KonuAnlatimliVideolarEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideosEvent extends KonuAnlatimliVideolarEvent {
  const LoadVideosEvent();
}

