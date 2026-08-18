import 'failures.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  });
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => ok(value);
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => err(failure);
}
