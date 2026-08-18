abstract class Failure {
  const Failure({this.message = 'An unexpected error occurred'});
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server communication failed'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local cache operation failed'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation checks failed'});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message});
}
