import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AppStarted>(_onAppStarted);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasSession = await authRepository.checkSession();
      if (hasSession) {
        // If session exists, token is already loaded in repository
        emit(AuthSuccess(token: AuthRepository.token ?? ''));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.login(event.username, event.password);
      emit(AuthSuccess(token: token));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await authRepository.loginWithGoogle();
      emit(AuthSuccess(token: token));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(AuthInitial());
    } catch (e) {
      // Even if logout fails on server, we reset state to initial on client
      emit(AuthInitial());
    }
  }
}
