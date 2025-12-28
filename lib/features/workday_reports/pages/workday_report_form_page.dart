import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/workday_reports_provider.dart';
import '../widgets/steps/step_general_info.dart';
import '../widgets/steps/step_lunch.dart';
import '../widgets/steps/step_standby.dart';
import '../widgets/steps/step_travel.dart';
import '../widgets/steps/step_comments.dart';
import '../../user/providers/user_provider.dart';
import '../../clockin/providers/clockin_provider.dart';

// Importar las keys de cada step
export '../widgets/steps/step_general_info.dart' show stepGeneralInfoKey;
export '../widgets/steps/step_lunch.dart' show stepLunchKey;
export '../widgets/steps/step_standby.dart' show stepStandbyKey;
export '../widgets/steps/step_travel.dart' show stepTravelKey;
export '../widgets/steps/step_comments.dart' show stepCommentsKey;

class WorkdayReportFormPage extends ConsumerStatefulWidget {
  final int workdayId;

  const WorkdayReportFormPage({
    Key? key,
    required this.workdayId,
  }) : super(key: key);

  @override
  ConsumerState<WorkdayReportFormPage> createState() => _WorkdayReportFormPageState();
}

class _WorkdayReportFormPageState extends ConsumerState<WorkdayReportFormPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workdayReportsProvider.notifier).initializeNewReport(widget.workdayId);
      ref.read(workdayReportsProvider.notifier).setWorkdayId(widget.workdayId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(workdayReportsProvider);
    final currentStep = reportsState.currentStep;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Workday Report',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step ${currentStep + 1} of 5',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _showExitDialog();
              if (shouldPop == true && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: reportsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressIndicator(currentStep),
                  Expanded(
                    child: _buildCurrentStep(currentStep),
                  ),
                  _buildNavigationButtons(currentStep),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.white,
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 4) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(int currentStep) {
    switch (currentStep) {
      case 0:
        return StepGeneralInfo(key: stepGeneralInfoKey);
      case 1:
        return StepLunch(key: stepLunchKey);
      case 2:
        return StepStandby(key: stepStandbyKey);
      case 3:
        return StepTravel(key: stepTravelKey);
      case 4:
        return StepComments(key: stepCommentsKey);
      default:
        return StepGeneralInfo(key: stepGeneralInfoKey);
    }
  }

  Widget _buildNavigationButtons(int currentStep) {
    final canGoBack = currentStep > 0;
    final canGoNext = currentStep < 4;
    final isLastStep = currentStep == 4;
    final reportsState = ref.watch(workdayReportsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoBack)
            Expanded(
              child: OutlinedButton(
                onPressed: reportsState.isLoading ? null : () {
                  ref.read(workdayReportsProvider.notifier).previousStep();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (canGoBack && canGoNext) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: reportsState.isLoading ? null : () async {
                if (isLastStep) {
                  await _handleSubmit();
                } else {
                  await _handleNext(currentStep);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: reportsState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLastStep ? 'Submit Report' : 'Next',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Form?'),
        content: const Text('Your progress will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Manejar navegación al siguiente step
  Future<void> _handleNext(int currentStep) async {
    bool success = false;
    
    switch (currentStep) {
      case 0: // Step 0: Crear reporte base
        final stepState = stepGeneralInfoKey.currentState;
        if (stepState == null) {
          _showError('Error: Step not initialized');
          return;
        }
        
        if (!stepState.isValid()) {
          _showError('Please select whether you had a workday');
          return;
        }
        
        success = await stepState.createReportBase();
        if (!success) {
          final error = ref.read(workdayReportsProvider).error;
          _showError(error ?? 'Failed to create report');
          return;
        }
        break;
        
      case 1: // Step 1: Actualizar lunch
        final lunchState = stepLunchKey.currentState;
        if (lunchState == null) {
          _showError('Error: Step not initialized');
          return;
        }
        
        if (!lunchState.isValid()) {
          _showError('Please select whether you had lunch');
          return;
        }
        
        success = await lunchState.updateReportLunch();
        if (!success) {
          final error = ref.read(workdayReportsProvider).error;
          _showError(error ?? 'Failed to update lunch');
          return;
        }
        break;
        
      case 2: // Step 2: Actualizar standby
        final standbyState = stepStandbyKey.currentState;
        if (standbyState == null) {
          _showError('Error: Step not initialized');
          return;
        }
        
        if (!standbyState.isValid()) {
          _showError('Please select whether you had standby time');
          return;
        }
        
        success = await standbyState.updateReportStandby();
        if (!success) {
          final error = ref.read(workdayReportsProvider).error;
          _showError(error ?? 'Failed to update standby');
          return;
        }
        break;
        
      case 3: // Step 3: Actualizar travel
        final travelState = stepTravelKey.currentState;
        if (travelState == null) {
          _showError('Error: Step not initialized');
          return;
        }
        
        if (!travelState.isValid()) {
          _showError('Please select whether you had travel time');
          return;
        }
        
        success = await travelState.updateReportTravel();
        if (!success) {
          final error = ref.read(workdayReportsProvider).error;
          _showError(error ?? 'Failed to update travel');
          return;
        }
        break;
    }
    
    // Avanzar al siguiente step
    ref.read(workdayReportsProvider.notifier).nextStep();
  }

  // Manejar submit final
  Future<void> _handleSubmit() async {
    final reportsState = ref.read(workdayReportsProvider);
    final reportId = reportsState.reportId;
    final workdayId = reportsState.workdayId;
    
    if (reportId == null) {
      _showError('No report ID found');
      return;
    }

    // Step 4: Actualizar comments
    final commentsState = stepCommentsKey.currentState;
    if (commentsState == null) {
      _showError('Error: Step not initialized');
      return;
    }
    
    final success = await commentsState.updateReportComments();
    if (!success) {
      final error = ref.read(workdayReportsProvider).error;
      _showError(error ?? 'Failed to update comments');
      return;
    }

    // Finalizar jornada después de completar el reporte
    if (workdayId != null) {
      final finalized = await ref.read(workdayReportsProvider.notifier)
          .finalizeWorkday(workdayId);
      
      if (!finalized) {
        final error = ref.read(workdayReportsProvider).error;
        _showError(error ?? 'Failed to finalize workday');
        return;
      }
    }

    // Mostrar mensaje de éxito y navegar
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report submitted and workday finalized successfully'),
        backgroundColor: AppColors.success,
      ),
    );
    
    // Refrescar el estado del workday en el dashboard antes de salir
    final user = ref.read(userProvider).user;
    if (user != null && user.contract != 0) {
      await ref.read(clockinProvider.notifier).initializeSession(user.contract);
    }
    
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
