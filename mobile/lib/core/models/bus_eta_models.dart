class NearbyStation {
  const NearbyStation({
    required this.name,
    required this.distanceMeters,
    required this.lines,
    required this.arrivals,
  });

  final String name;
  final int distanceMeters;
  final List<String> lines;
  final List<ArrivalInfo> arrivals;
}

class ArrivalInfo {
  const ArrivalInfo({
    required this.line,
    required this.arrivalMinutes,
    required this.remainingStops,
    required this.direction,
  });

  final String line;
  final int arrivalMinutes;
  final int remainingStops;
  final String direction;
}

class RouteSegment {
  const RouteSegment({
    required this.mode,
    required this.label,
    required this.durationMinutes,
    required this.detail,
  });

  final String mode;
  final String label;
  final int durationMinutes;
  final String detail;
}

class TripPlan {
  const TripPlan({
    required this.title,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalMinutes,
    required this.walkingMinutes,
    required this.transferCount,
    required this.riskLevel,
    required this.recommendation,
    required this.transferHint,
    required this.warning,
    required this.segments,
  });

  final String title;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final int totalMinutes;
  final int walkingMinutes;
  final int transferCount;
  final String riskLevel;
  final String recommendation;
  final String transferHint;
  final String warning;
  final List<RouteSegment> segments;
}

class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.nextDeparture,
    required this.summary,
    this.isPinned = false,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String origin;
  final String destination;
  final String nextDeparture;
  final String summary;
  final bool isPinned;
  final List<String> tags;

  SavedRoute copyWith({
    String? name,
    String? origin,
    String? destination,
    String? nextDeparture,
    String? summary,
    bool? isPinned,
    List<String>? tags,
  }) {
    return SavedRoute(
      id: id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      nextDeparture: nextDeparture ?? this.nextDeparture,
      summary: summary ?? this.summary,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  Map<String, String> toJson() => {
        'id': id,
        'name': name,
        'origin': origin,
        'destination': destination,
        'nextDeparture': nextDeparture,
        'summary': summary,
        'isPinned': '$isPinned',
        'tags': tags.join(','),
      };

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      nextDeparture: json['nextDeparture'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      isPinned: json['isPinned'] == 'true',
      tags: (json['tags'] as String? ?? '')
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
    );
  }
}

class SearchPair {
  const SearchPair({required this.origin, required this.destination});

  final String origin;
  final String destination;
}