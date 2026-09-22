// ai_service_client.dart
// -----------------------
// Typed HTTP client for the Python FastAPI AI service.
// All endpoints mirror ai-service/routers/*.py.
//
// Environment:
//   AI_SERVICE_URL=http://localhost:8000  (dev)
//   AI_SERVICE_URL=https://ai.yourdomain.com  (prod)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Response types ────────────────────────────────────────────────────

class ExtractionField {
  const ExtractionField({
    required this.fieldName,
    required this.rawValue,
    this.parsedValue,
    required this.confidence,
    this.boundingBox,
  });

  final String fieldName;
  final String rawValue;
  final double? parsedValue;
  final double confidence;
  final Map<String, dynamic>? boundingBox;

  factory ExtractionField.fromJson(Map<String, dynamic> j) =>
      ExtractionField(
        fieldName:   j['field_name'] as String,
        rawValue:    j['raw_value'] as String,
        parsedValue: (j['parsed_value'] as num?)?.toDouble(),
        confidence:  (j['confidence'] as num).toDouble(),
        boundingBox: j['bounding_box'] as Map<String, dynamic>?,
      );
}

class ExtractedBill {
  const ExtractedBill({
    required this.fields,
    required this.lineItems,
    required this.validationPassed,
    this.amountDue,
    this.dueDate,
    this.provider,
    this.periodStart,
    this.periodEnd,
    this.totalUsage,
  });

  final List<ExtractionField> fields;
  final List<Map<String, dynamic>> lineItems;
  final bool validationPassed;
  final double? amountDue;
  final String? dueDate;
  final String? provider;
  final String? periodStart;
  final String? periodEnd;
  final double? totalUsage;

  factory ExtractedBill.fromJson(Map<String, dynamic> j) => ExtractedBill(
        fields: (j['fields'] as List)
            .map((e) => ExtractionField.fromJson(e as Map<String, dynamic>))
            .toList(),
        lineItems:
            List<Map<String, dynamic>>.from(j['line_items'] as List? ?? []),
        validationPassed: j['validation_passed'] as bool? ?? false,
        amountDue:   (j['amount_due'] as num?)?.toDouble(),
        dueDate:     j['due_date'] as String?,
        provider:    j['provider'] as String?,
        periodStart: j['period_start'] as String?,
        periodEnd:   j['period_end'] as String?,
        totalUsage:  (j['total_usage'] as num?)?.toDouble(),
      );
}

class ValidationResult {
  const ValidationResult({
    required this.passed,
    required this.failures,
  });

  final bool passed;
  final List<Map<String, dynamic>> failures;

  factory ValidationResult.fromJson(Map<String, dynamic> j) =>
      ValidationResult(
        passed:   j['passed'] as bool,
        failures: List<Map<String, dynamic>>.from(j['failures'] as List? ?? []),
      );
}

class NarrationResult {
  const NarrationResult({required this.sentence});
  final String sentence;

  factory NarrationResult.fromJson(Map<String, dynamic> j) =>
      NarrationResult(sentence: j['sentence'] as String);
}

// ── Client ────────────────────────────────────────────────────────────

class AiServiceClient {
  AiServiceClient._();
  static AiServiceClient? _instance;
  static AiServiceClient get instance => _instance ??= AiServiceClient._();

  String get _baseUrl {
    final url = dotenv.env['AI_SERVICE_URL'] ?? 'http://localhost:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<T> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw AiServiceException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return fromJson(data);
  }

  // ── Health check ─────────────────────────────────────────────────────

  Future<bool> isHealthy() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Extract (image → structured bill) ────────────────────────────────
  // Sends a signed Supabase Storage URL to FastAPI.
  // FastAPI fetches the image, runs OCR, returns ExtractedBill.

  Future<ExtractedBill> extract({
    required String imageUrl,
    required String billId,
  }) async {
    return _post(
      '/extract',
      {'image_url': imageUrl, 'bill_id': billId},
      ExtractedBill.fromJson,
    );
  }

  // ── Validate (deterministic arithmetic check) ─────────────────────────

  Future<ValidationResult> validate(Map<String, dynamic> extractedBill) async {
    return _post('/validate', extractedBill, ValidationResult.fromJson);
  }

  // ── Narrate (structured data → one sentence) ──────────────────────────
  // register: "brief" | "explained" | "full"

  Future<NarrationResult> narrate({
    required Map<String, dynamic> analysis,
    required String register, // "brief" | "explained" | "full"
  }) async {
    return _post(
      '/narrate',
      {'analysis': analysis, 'register': register},
      NarrationResult.fromJson,
    );
  }

  // ── Analyse (deterministic spend decomposition) ────────────────────────

  Future<Map<String, dynamic>> analyse({
    required Map<String, dynamic> bill,
    Map<String, dynamic>? priorBill,
  }) async {
    final uri  = Uri.parse('$_baseUrl/analyse');
    final body = <String, dynamic>{'bill': bill};
    if (priorBill != null) body['prior_bill'] = priorBill;
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw AiServiceException(statusCode: response.statusCode, message: response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
class AiServiceException implements Exception {
  const AiServiceException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  @override
  String toString() => 'AiServiceException($statusCode): $message';
}
