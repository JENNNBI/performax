import 'package:equatable/equatable.dart';
import '../../models/task.dart';

class TasksState extends Equatable {
  final List<Task> pendingTasks;
  final List<Task> completedTasks;
  final List<Task> favoriteTasks;

  const TasksState({
    this.pendingTasks = const [],
    this.completedTasks = const [],
    this.favoriteTasks = const [],
  });

  TasksState copyWith({
    List<Task>? pendingTasks,
    List<Task>? completedTasks,
    List<Task>? favoriteTasks,
  }) {
    return TasksState(
      pendingTasks: pendingTasks ?? this.pendingTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      favoriteTasks: favoriteTasks ?? this.favoriteTasks,
    );
  }

  @override
  List<Object?> get props => [pendingTasks, completedTasks, favoriteTasks];
}

