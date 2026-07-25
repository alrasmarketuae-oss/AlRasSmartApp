enum NegotiationType {
  negotiable,
  nonNegotiable;

  bool get isNegotiable => this == NegotiationType.negotiable;
}
