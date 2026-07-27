import '../core/api_client.dart';
import '../models/ledger_model.dart';

class LedgerService {
  final ApiClient _client;
  LedgerService(this._client);

  Future<List<LedgerEntry>> listByTenant({String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final res = await _client.get('/api/v1/ledger', query: query.isNotEmpty ? query : null);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LedgerEntry>> listByEmployee(String employeeId, {String? startDate, String? endDate}) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final res = await _client.get('/api/v1/ledger/$employeeId', query: query.isNotEmpty ? query : null);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LedgerEntry> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/ledger', body: body);
    return LedgerEntry.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LedgerSummary> getSummary() async {
    final res = await _client.get('/api/v1/ledger/total-outstanding');
    return LedgerSummary.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<double> getBalance(String employeeId) async {
    final res = await _client.get('/api/v1/ledger/$employeeId/balance');
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return (data['balance'] as num?)?.toDouble() ?? 0;
  }

  Future<void> settleAccount(String employeeId) async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _client.post('/api/v1/ledger/$employeeId/settle', body: {'date': date});
  }
}
