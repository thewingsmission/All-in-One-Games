/// Leaderboard entry model
class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime timestamp;
  final int rank;
  
  const LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.timestamp,
    required this.rank,
  });
  
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerName: json['playerName'] ?? 'Anonymous',
      score: json['score'] ?? 0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      rank: json['rank'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
      'rank': rank,
    };
  }
}
