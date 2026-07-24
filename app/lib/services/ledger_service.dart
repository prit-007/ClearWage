import '../core/api_client.dart';
import '../models/ledger_model.dart';

class LedgerService {
  final ApiClient _client;
  LedgerService(this._client);

  Future<List<LedgerEntry>> listByTenant() async {
    final res = await _client.get('/api/v1/ledger');
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LedgerEntry>> listByEmployee(String employeeId) async {
    final res = await _client.get('/api/v1/ledger/$employeeId');
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
    return (res['data'] as num?)?.toDouble() ?? 0;
  }

  Future<void> settleAccount(String employeeId) async {
    await _client.post('/api/v1/ledger/$employeeId/settle');
  }
}
