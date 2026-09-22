// lib/shared/models/extraction_field.dart
// Mirrors the Supabase `extraction_fields` table.
// Carries confidence + bounding_box provenance so the UI can
// highlight source regions on the original image.

class ExtractionFieldModel {
  const ExtractionFieldModel({
    required this.id,
    required this.billId,
    required this.fieldName,
    required this.rawValue,
    this.parsedValue,
    required this.confidence,
    this.boundingBox,
    this.sourcePage = 0,
  });

  final String id;
  final String billId;
  final String fieldName;   // "amount_due", "kwh_used", "due_date", ...
  final String rawValue;    // verbatim OCR text
  final double? parsedValue;
  final double confidence;  // 0.0–1.0
  final BoundingBox? boundingBox;
  final int sourcePage;

  factory ExtractionFieldModel.fromJson(Map<String, dynamic> j) =>
      ExtractionFieldModel(
        id:          j['id'] as String,
        billId:      j['bill_id'] as String,
        fieldName:   j['field_name'] as String,
        rawValue:    j['raw_value'] as String,
        parsedValue: (j['parsed_value'] as num?)?.toDouble(),
        confidence:  (j['confidence'] as num).toDouble(),
        boundingBox: j['bounding_box'] != null
            ? BoundingBox.fromJson(j['bounding_box'] as Map<String, dynamic>)
            : null,
        sourcePage: j['source_page'] as int? ?? 0,
      );
}

class BoundingBox {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.page = 0,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final int page;

  factory BoundingBox.fromJson(Map<String, dynamic> j) => BoundingBox(
        x:    (j['x'] as num).toDouble(),
        y:    (j['y'] as num).toDouble(),
        w:    (j['w'] as num).toDouble(),
        h:    (j['h'] as num).toDouble(),
        page: j['page'] as int? ?? 0,
      );
}
