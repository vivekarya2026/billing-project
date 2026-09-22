// bill_capture_screen.dart
// -------------------------
// Guided bill capture (US-003, M3) + extraction + targeted confirmation (US-006, M6).
//
// Flow:
//   1. User picks image/PDF (camera or file picker)
//   2. Image saved (Supabase Storage when online; fake path when offline)
//   3. Bill extracted: offline → deterministic stub; online → /extract endpoint
//   4. Arithmetic validated: offline → always passes; online → /validate
//   5. If validation fails → show only failing fields (Hick's Law)
//   6. User confirms → write bill + extraction_fields
//   7. Narrate: offline → built-in sentence; online → /narrate
//   8. Navigate to /bill/:id  (Peak-End: end on the answer)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/data/bill_repository.dart';
import '../../../shared/data/fake_bill_repository.dart';
import '../../../shared/services/ai_service_client.dart';
import '../../../shared/services/supabase_client.dart';
import '../../../state/settings_state.dart';
import '../../../theme/tokens.dart';
import 'confirmation_screen.dart';

class BillCaptureScreen extends StatefulWidget {
  const BillCaptureScreen({super.key, this.mode = 'files'});
  final String mode; // 'camera' | 'files'

  @override
  State<BillCaptureScreen> createState() => _BillCaptureScreenState();
}

class _BillCaptureScreenState extends State<BillCaptureScreen> {
  final _picker = ImagePicker();
  XFile? _pickedFile;
  bool _processing = false;
  String? _status;
  String? _error;

  Future<void> _pickFile() async {
    try {
      XFile? file;
      if (widget.mode == 'camera' && !kIsWeb) {
        file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 2048,
        );
      } else {
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 2048,
        );
      }
      if (file != null) {
        setState(() { _pickedFile = file; _error = null; });
      }
    } catch (e) {
      setState(() => _error = 'Could not open file. Please try again.');
    }
  }

  /// True when the app is running with the offline fake repo (no Supabase).
  bool get _isOffline =>
      context.read<BillRepository>() is FakeBillRepository;

  Future<void> _processFile() async {
    if (_pickedFile == null) return;

    setState(() { _processing = true; _status = 'Uploading…'; _error = null; });

    try {
      final repo     = context.read<BillRepository>();
      final settings = context.read<SettingsState>();
      String? userId;
      try {
        userId = SupabaseService.instance.currentUser?.id;
      } catch (_) {}
      userId ??= '00000000-0000-0000-0000-000000000001';
      const uuid   = Uuid();
      final billId = uuid.v4();

      // ── 1. Upload / save image ─────────────────────────────────────
      final bytes    = await _pickedFile!.readAsBytes();
      const fileName = 'original.jpg';
      const mimeType = 'image/jpeg';

      setState(() => _status = 'Saving image…');
      final storagePath = await repo.uploadBillImage(
        userId:   userId,
        billId:   billId,
        fileName: fileName,
        bytes:    bytes,
        mimeType: mimeType,
      );

      // ── 2. Get URL (fake in offline mode) ─────────────────────────
      setState(() => _status = 'Analysing bill…');
      final signedUrl = await repo.getSignedImageUrl(storagePath);

      // ── 3. Extract — offline stub or live AI service ───────────────
      final ExtractedBill extracted;
      final ValidationResult validation;

      if (_isOffline) {
        // Deterministic stub: a plausible Ohio Edison electric bill.
        extracted = _offlineStubExtracted(billId);
        // Validation always passes in offline demo — no arithmetic to fail.
        validation = const ValidationResult(passed: true, failures: []);
      } else {
        setState(() => _status = 'Extracting bill data…');
        extracted = await AiServiceClient.instance.extract(
          imageUrl: signedUrl,
          billId: billId,
        );
        setState(() => _status = 'Checking the arithmetic…');
        final extractedMap = {
          'bill_id':      billId,
          'amount_due':   extracted.amountDue,
          'period_start': extracted.periodStart,
          'period_end':   extracted.periodEnd,
          'total_usage':  extracted.totalUsage,
          'fields': extracted.fields.map((f) => {
            'field_name':   f.fieldName,
            'raw_value':    f.rawValue,
            'parsed_value': f.parsedValue,
            'confidence':   f.confidence,
          }).toList(),
          'line_items': extracted.lineItems.map((li) => {
            'description': li['description'],
            'amount':      li['amount']?.toString() ?? '0',
            'item_type':   li['item_type'],
          }).toList(),
        };
        validation = await AiServiceClient.instance.validate(extractedMap);
      }

      if (mounted) {
        setState(() => _processing = false);

        // ── 4. Navigate to confirmation ────────────────────────────
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              billId:      billId,
              storagePath: storagePath,
              extracted:   extracted,
              validation:  validation,
              register:    settings.detailLevel.name,
              isOffline:   _isOffline,
            ),
          ),
        );

        if (mounted) context.go('/bills');
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _status = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Deterministic offline stub — a realistic Ohio Edison electric bill.
  ExtractedBill _offlineStubExtracted(String billId) {
    final now = DateTime.now();
    final periodEnd   = DateTime(now.year, now.month - 1, 26);
    final periodStart = DateTime(now.year, now.month - 1, 1);
    final dueDate     = periodEnd.add(const Duration(days: 20));

    return ExtractedBill(
      fields: [
        const ExtractionField(
          fieldName: 'amount_due',
          rawValue: r'$143.20',
          parsedValue: 143.20,
          confidence: 0.98,
          boundingBox: {'x': 412, 'y': 148, 'w': 120, 'h': 28},
        ),
        ExtractionField(
          fieldName: 'due_date',
          rawValue: '${dueDate.month}/${dueDate.day}/${dueDate.year}',
          parsedValue: null,
          confidence: 0.99,
        ),
        const ExtractionField(
          fieldName: 'kwh_used',
          rawValue: '760 kWh',
          parsedValue: 760.0,
          confidence: 0.96,
        ),
      ],
      lineItems: const [
        {'description': 'Distribution charge', 'amount': 42.50, 'item_type': 'charge'},
        {'description': 'Generation charge',   'amount': 74.60, 'item_type': 'charge'},
        {'description': 'Transmission charge', 'amount': 18.30, 'item_type': 'charge'},
        {'description': 'State taxes and fees', 'amount': 7.80, 'item_type': 'tax'},
      ],
      validationPassed: true,
      amountDue: 143.20,
      dueDate: '${dueDate.year}-${dueDate.month.toString().padLeft(2,'0')}-${dueDate.day.toString().padLeft(2,'0')}',
      provider: 'Ohio Edison',
      periodStart: '${periodStart.year}-${periodStart.month.toString().padLeft(2,'0')}-01',
      periodEnd: '${periodEnd.year}-${periodEnd.month.toString().padLeft(2,'0')}-26',
      totalUsage: 760.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Add a bill'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // ── Image preview / picker area ───────────────────────────
              GestureDetector(
                onTap: _processing ? null : _pickFile,
                child: Semantics(
                  label: 'Tap to ${widget.mode == 'camera' ? 'take a photo' : 'choose a file'}',
                  button: true,
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colours.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppTokens.radiusBox),
                      border: Border.all(color: colours.outline, width: 1),
                    ),
                    child: _pickedFile != null
                        ? _buildPreview(colours)
                        : _buildPickerPlaceholder(text, colours),
                  ),
                ),
              ),

              const SizedBox(height: AppTokens.space4),

              // ── Status / error ────────────────────────────────────────
              if (_status != null)
                Text(_status!, style: text.bodyMedium),
              if (_error != null)
                Text(_error!, style: text.bodyMedium),

              const Spacer(),

              // ── Primary action ────────────────────────────────────────
              if (_pickedFile == null)
                AppButton(
                  label: widget.mode == 'camera' ? 'Take photo' : 'Choose files',
                  onPressed: _pickFile,
                )
              else
                AppButton(
                  label: 'Process this bill',
                  loading: _processing,
                  onPressed: _processing ? null : _processFile,
                ),

              if (_pickedFile != null && !_processing) ...[
                const SizedBox(height: AppTokens.space3),
                AppButton(
                  label: 'Choose a different image',
                  variant: ButtonVariant.plain,
                  fullWidth: false,
                  onPressed: _pickFile,
                ),
              ],

              const SizedBox(height: AppTokens.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme colours) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Image.network(
        _pickedFile!.path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.image, size: 64, color: colours.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildPickerPlaceholder(TextTheme text, ColorScheme colours) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.mode == 'camera'
                ? Icons.camera_alt_outlined
                : Icons.file_present_outlined,
            size: 48,
            color: colours.onSurfaceVariant,
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            widget.mode == 'camera' ? 'Tap to take a photo' : 'Tap to choose a file',
            style: text.bodyMedium,
          ),
          Text('JPG, PNG, or PDF', style: text.bodySmall),
        ],
      ),
    );
  }
}
