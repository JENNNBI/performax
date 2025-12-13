import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../models/task.dart';
import 'tasks_event.dart';
import 'tasks_state.dart';

class TasksBloc extends HydratedBloc<TasksEvent, TasksState> {
  TasksBloc() : super(const TasksState()) {
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<RemoveTask>(_onRemoveTask);
    on<MarkFavoriteOrUnfavoriteTask>(_onMarkFavoriteOrUnfavoriteTask);
    on<RestoreTask>(_onRestoreTask);
    on<EditTask>(_onEditTask);
  }

  void _onAddTask(AddTask event, Emitter<TasksState> emit) {
    final task = event.task.copyWith(isDone: false, isDeleted: false);
    final updatedPendingTasks = List<Task>.from(state.pendingTasks)..add(task);
    emit(state.copyWith(pendingTasks: updatedPendingTasks));
  }

  void _onUpdateTask(UpdateTask event, Emitter<TasksState> emit) {
    final task = event.task.copyWith(isDone: !(event.task.isDone ?? false));
    
    List<Task> updatedPendingTasks = List<Task>.from(state.pendingTasks);
    List<Task> updatedCompletedTasks = List<Task>.from(state.completedTasks);

    if (task.isDone == true) {
      updatedPendingTasks.removeWhere((t) => t.id == task.id);
      if (!updatedCompletedTasks.any((t) => t.id == task.id)) {
        updatedCompletedTasks.add(task);
      }
    } else {
      updatedCompletedTasks.removeWhere((t) => t.id == task.id);
      if (!updatedPendingTasks.any((t) => t.id == task.id)) {
        updatedPendingTasks.add(task);
      }
    }

    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
    ));
  }

  void _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) {
    final updatedPendingTasks = state.pendingTasks.where((t) => t.id != event.task.id).toList();
    final updatedCompletedTasks = state.completedTasks.where((t) => t.id != event.task.id).toList();
    final updatedFavoriteTasks = state.favoriteTasks.where((t) => t.id != event.task.id).toList();
    
    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
      favoriteTasks: updatedFavoriteTasks,
    ));
  }

  void _onRemoveTask(RemoveTask event, Emitter<TasksState> emit) {
    final task = event.task.copyWith(isDeleted: true);
    final updatedPendingTasks = state.pendingTasks.map((t) => t.id == task.id ? task : t).toList();
    final updatedCompletedTasks = state.completedTasks.map((t) => t.id == task.id ? task : t).toList();
    
    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
    ));
  }

  void _onMarkFavoriteOrUnfavoriteTask(
    MarkFavoriteOrUnfavoriteTask event,
    Emitter<TasksState> emit,
  ) {
    final task = event.task.copyWith(isFavorite: !(event.task.isFavorite ?? false));
    
    List<Task> updatedFavoriteTasks = List<Task>.from(state.favoriteTasks);
    
    if (task.isFavorite == true) {
      if (!updatedFavoriteTasks.any((t) => t.id == task.id)) {
        updatedFavoriteTasks.add(task);
      }
    } else {
      updatedFavoriteTasks.removeWhere((t) => t.id == task.id);
    }

    // Update task in pending and completed lists
    final updatedPendingTasks = state.pendingTasks.map((t) => t.id == task.id ? task : t).toList();
    final updatedCompletedTasks = state.completedTasks.map((t) => t.id == task.id ? task : t).toList();

    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
      favoriteTasks: updatedFavoriteTasks,
    ));
  }

  void _onRestoreTask(RestoreTask event, Emitter<TasksState> emit) {
    final task = event.task.copyWith(isDeleted: false);
    final updatedPendingTasks = state.pendingTasks.map((t) => t.id == task.id ? task : t).toList();
    final updatedCompletedTasks = state.completedTasks.map((t) => t.id == task.id ? task : t).toList();
    
    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
    ));
  }

  void _onEditTask(EditTask event, Emitter<TasksState> emit) {
    final updatedPendingTasks = state.pendingTasks.map((t) => t.id == event.oldTask.id ? event.newTask : t).toList();
    final updatedCompletedTasks = state.completedTasks.map((t) => t.id == event.oldTask.id ? event.newTask : t).toList();
    final updatedFavoriteTasks = state.favoriteTasks.map((t) => t.id == event.oldTask.id ? event.newTask : t).toList();
    
    emit(state.copyWith(
      pendingTasks: updatedPendingTasks,
      completedTasks: updatedCompletedTasks,
      favoriteTasks: updatedFavoriteTasks,
    ));
  }

  @override
  TasksState? fromJson(Map<String, dynamic> json) {
    try {
      final pendingTasks = (json['pendingTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];
      final completedTasks = (json['completedTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];
      final favoriteTasks = (json['favoriteTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];

      return TasksState(
        pendingTasks: pendingTasks,
        completedTasks: completedTasks,
        favoriteTasks: favoriteTasks,
      );
    } catch (e) {
      return const TasksState();
    }
  }

  @override
  Map<String, dynamic>? toJson(TasksState state) {
    return {
      'pendingTasks': state.pendingTasks.map((t) => t.toMap()).toList(),
      'completedTasks': state.completedTasks.map((t) => t.toMap()).toList(),
      'favoriteTasks': state.favoriteTasks.map((t) => t.toMap()).toList(),
    };
  }
}

