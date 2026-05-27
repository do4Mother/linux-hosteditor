sealed class ApplyStatus {
  const ApplyStatus();
}

class Idle extends ApplyStatus {
  const Idle();
}

class Authenticating extends ApplyStatus {
  const Authenticating();
}

class Writing extends ApplyStatus {
  const Writing();
}

class ApplyError extends ApplyStatus {
  final String message;
  const ApplyError(this.message);
}
