class MovieRate {
  static const notRated = 0;
  static const liked = 1;
  static const notLiked = 2;
  static const addedToWatchlist = 4;
  static const okay = 8;

  static bool isViewed(int movieRate) {
    return movieRate == liked || movieRate == notLiked || movieRate == okay;
  }

  static bool isPositiveVote(int movieRate) {
    return movieRate == liked;
  }

  static bool isNegativeVote(int movieRate) {
    return movieRate == notLiked;
  }

  static String opinionLabel(int movieRate) {
    switch (movieRate) {
      case liked:
        return 'Liked';
      case okay:
        return 'Okay';
      case notLiked:
        return 'Disliked';
      case addedToWatchlist:
        return 'Watchlist';
      default:
        return 'Not rated';
    }
  }
}
