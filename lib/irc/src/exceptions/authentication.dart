class IrcAuthenticationException {
  final String message;

  IrcAuthenticationException(this.message);

  @override
  String toString() => 'IrcAuthenticationException: $message';
}
