import 'package:flutter_test/flutter_test.dart';
import 'package:vietnam_geo_dashboard/models/incident_model.dart';

void main() {
  test('incident payload keeps createdBy for user-scoped incidents', () {
    final incident = Incident(
      incidentCode: 'SV-001',
      title: 'Sự vụ thử',
      createdBy: 7,
    );

    expect(incident.toDbMap()['created_by'], 7);
  });
}
