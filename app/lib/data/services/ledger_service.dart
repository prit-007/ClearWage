import '../../core/api_client.dart';
import '../../core/helpers.dart';
import '../models/ledger_model.dart';

class LedgerService {
  final ApiClient _client;
  LedgerService(this._client);

  Future<List<LedgerEntry>> listByTenant({
    required String startDate,
    required String endDate,
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get('/api/v1/ledger', query: query);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LedgerEntry>> listByEmployee(
    String employeeId, {
    required String startDate,
    required String endDate,
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get('/api/v1/ledger/$employeeId', query: query);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LedgerEntry> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/ledger', body: body);
    return LedgerEntry.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LedgerSummary> getSummary({
    required String startDate,
    required String endDate,
  }) async {
    final res = await _client.get(
      '/api/v1/ledger/summary',
      query: {'start_date': startDate, 'end_date': endDate},
    );
    return LedgerSummary.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<double> getBalance(String employeeId) async {
    final res = await _client.get('/api/v1/ledger/$employeeId/balance');
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return safeToDouble(data['balance']);
  }

  Future<void> settleAccount(String employeeId) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _client.post(
      '/api/v1/ledger/$employeeId/settle',
      body: {'date': date},
    );
  }

  Future<List<Map<String, dynamic>>> getBalanceSummary() async {
    final now = DateTime.now();
    final startDate =
        '${now.year - 1}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final res = await _client.get(
      '/api/v1/ledger/balance-summary',
      query: {'start_date': startDate, 'end_date': endDate},
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<LedgerEntry> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/api/v1/ledger/$id/entry', body: body);
    return LedgerEntry.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/v1/ledger/$id/entry');
  }
}
