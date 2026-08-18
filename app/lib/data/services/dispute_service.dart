import '../models/dispute_model.dart';
import '../../core/api_client.dart';

class DisputeService {
  final ApiClient _client;

  DisputeService(this._client);

  Future<Dispute> create({
    required String ledgerId,
    required String employeeId,
    required String reason,
  }) async {
    final res = await _client.post(
      '/api/v1/disputes',
      body: {
        'ledger_id': ledgerId,
        'employee_id': employeeId,
        'reason': reason,
      },
    );
    return Dispute.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<Dispute>> list({String status = 'open'}) async {
    final res = await _client.get(
      '/api/v1/disputes',
      query: {'status': status},
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Dispute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Dispute> resolve({
    required String disputeId,
    String? resolutionNote,
  }) async {
    final res = await _client.post(
      '/api/v1/disputes/resolve',
      body: {'dispute_id': disputeId, 'resolution_note': ?resolutionNote},
    );
    return Dispute.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Dispute> reject({
    required String disputeId,
    String? resolutionNote,
  }) async {
    final res = await _client.post(
      '/api/v1/disputes/reject',
      body: {'dispute_id': disputeId, 'resolution_note': ?resolutionNote},
    );
    return Dispute.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
