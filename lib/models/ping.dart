class Ping {
  final String status; // pending | ok | fail
  final int? ms;
  const Ping(this.status, [this.ms]);
}
