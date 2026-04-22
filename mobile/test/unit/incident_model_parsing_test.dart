import 'package:disaster_response_mobile/features/incidents/models/incident_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UT-DART-03 IncidentModel null-safe handling', () {
    print('[UT-DART-03] Starting IncidentModel null-safe handling test');
    final json = {
      'incidentId': 5,
      'userId': 42,
      'locationId': 99,
      'title': 'Flood in area',
      'description': 'Water level rising quickly',
      'severity': 'HIGH',
      'status': 'REPORTED',
      'reportedAt': '2026-04-21T09:00:00.000Z',
      // Intentionally null/missing optional fields
      'imageUrl': null,
      'updatedAt': null,
      'location': {'locationId': 99, 'latitude': 27.7172, 'longitude': 85.3240},
      'incidentUpdates': null,
      'missions': [],
    };

    final incident = IncidentModel.fromJson(json);

    expect(incident.incidentId, 5);
    expect(incident.imageUrl, isNull);
    expect(incident.updatedAt, isNull);
    expect(incident.location?.address, isNull);
    expect(incident.location?.district, isNull);
    expect(incident.incidentUpdates, isNull);
    expect(incident.missionIds, isNull);
    print(
      '[UT-DART-03] Completed successfully with no errors ${incident.incidentId} ${incident.imageUrl} ${incident.updatedAt} ${incident.location?.address} ${incident.location?.district} ${incident.incidentUpdates} ${incident.missionIds}',
    );
  });
}
