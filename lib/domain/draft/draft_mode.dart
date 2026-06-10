/// The reveal formats. Three are "auto-reveal" (race/cards/lottery): the
/// result is generated first, then the UI dramatizes it. [bidding] is live and
/// interactive.
enum DraftMode {
  race,
  cards,
  lottery,
  bidding;

  /// Whether this mode reveals a generated order rather than collecting live
  /// bids.
  bool get isAutoReveal => this != DraftMode.bidding;

  String get code => name;

  String get label => switch (this) {
    DraftMode.race => 'The Race',
    DraftMode.cards => 'Card Flip',
    DraftMode.lottery => 'Lottery',
    DraftMode.bidding => 'Auction',
  };

  String get blurb => switch (this) {
    DraftMode.race =>
      'Runners sprint the field. First to the end zone picks first.',
    DraftMode.cards => 'Flip the cards to reveal each pick.',
    DraftMode.lottery => 'Weighted ping-pong ball draw.',
    DraftMode.bidding => 'Bid ColemanBucks for each slot.',
  };

  static DraftMode fromCode(String c) =>
      values.firstWhere((m) => m.code == c, orElse: () => DraftMode.race);
}
