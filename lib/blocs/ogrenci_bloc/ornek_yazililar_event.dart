import 'package:equatable/equatable.dart';

abstract class OrnekYazililarEvent extends Equatable {
  const OrnekYazililarEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocumentsEvent extends OrnekYazililarEvent {
  const LoadDocumentsEvent();
}

