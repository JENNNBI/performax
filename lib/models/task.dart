import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final String date;
  final bool? isDone;
  final bool? isDeleted;
  final bool? isFavorite;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isDone = false,
    this.isDeleted = false,
    this.isFavorite = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    bool? isDone,
    bool? isDeleted,
    bool? isFavorite,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
      isDeleted: isDeleted ?? this.isDeleted,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'isDone': isDone ?? false,
      'isDeleted': isDeleted ?? false,
      'isFavorite': isFavorite ?? false,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      date: map['date'] as String,
      isDone: map['isDone'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, title, description, date, isDone, isDeleted, isFavorite];
}

