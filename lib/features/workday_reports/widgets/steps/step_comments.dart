import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/workday_reports_provider.dart';

class StepComments extends ConsumerStatefulWidget {
  const StepComments({Key? key}) : super(key: key);

  @override
  ConsumerState<StepComments> createState() => _StepCommentsState();
}

// Key global para acceder al state desde el form_page
final stepCommentsKey = GlobalKey<_StepCommentsState>();

class _StepCommentsState extends ConsumerState<StepComments> {
  final _commentsController = TextEditingController();

  // Getter público
  String get comments => _commentsController.text.trim();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(workdayReportsProvider).draftReport;
    if (draft != null && draft.comments != null) {
      _commentsController.text = draft.comments!;
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.comment_outlined,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Text(
              'Additional Comments',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Add any additional information about this workday',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _commentsController,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Comments (Optional)',
              hintText: 'Enter any additional comments or observations...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderMedium),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) {
              // Auto-save comments
            },
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is the final step. Review your information and submit the report.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Validar que el step esté completo (comments son opcionales)
  bool isValid() {
    return true; // Comments son opcionales, siempre válido
  }

  // Actualizar comments en el reporte
  Future<bool> updateReportComments() async {
    final reportId = ref.read(workdayReportsProvider).reportId;
    if (reportId == null) return false;

    final commentsText = comments.isEmpty ? null : comments;
    
    final success = await ref.read(workdayReportsProvider.notifier)
        .updateReportComments(reportId, commentsText);
    
    return success;
  }
}
