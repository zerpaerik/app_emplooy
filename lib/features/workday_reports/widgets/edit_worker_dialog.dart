import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/worker_report_model.dart';
import '../providers/worker_report_provider.dart';

class EditWorkerDialog extends ConsumerStatefulWidget {
  final WorkerReportModel worker;
  final WorkerReportParams params;

  const EditWorkerDialog({
    Key? key,
    required this.worker,
    required this.params,
  }) : super(key: key);

  @override
  ConsumerState<EditWorkerDialog> createState() => _EditWorkerDialogState();
}

class _EditWorkerDialogState extends ConsumerState<EditWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _clockInTime;
  late TimeOfDay _clockOutTime;
  late TimeOfDay _lunchStart;
  late TimeOfDay _lunchEnd;
  late TimeOfDay _standbyStart;
  late TimeOfDay _standbyEnd;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clockInTime = TimeOfDay.fromDateTime(widget.worker.clockIn);
    _clockOutTime = TimeOfDay.fromDateTime(widget.worker.clockOut);
    
    // Parse lunch times
    final lunchParts = widget.worker.lunchDuration.split(':');
    _lunchStart = const TimeOfDay(hour: 12, minute: 0);
    _lunchEnd = TimeOfDay(
      hour: 12 + int.parse(lunchParts[0]),
      minute: int.parse(lunchParts[1]),
    );
    
    // Parse standby times
    final standbyParts = widget.worker.standbyDuration.split(':');
    _standbyStart = const TimeOfDay(hour: 0, minute: 0);
    _standbyEnd = TimeOfDay(
      hour: int.parse(standbyParts[0]),
      minute: int.parse(standbyParts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWorkerInfo(),
                      const SizedBox(height: 20),
                      _buildClockTimesSection(),
                      const SizedBox(height: 20),
                      _buildLunchSection(),
                      const SizedBox(height: 20),
                      _buildStandbySection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Worker',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.worker.fullName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ID#${widget.worker.btnId} - ${widget.worker.roleName}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clock Times',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                label: 'Clock-In',
                time: _clockInTime,
                onTap: () => _selectTime(context, true),
                icon: Icons.login,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                label: 'Clock-Out',
                time: _clockOutTime,
                onTap: () => _selectTime(context, false),
                icon: Icons.logout,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLunchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lunch Break',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                label: 'Start',
                time: _lunchStart,
                onTap: () => _selectLunchTime(context, true),
                icon: Icons.restaurant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                label: 'End',
                time: _lunchEnd,
                onTap: () => _selectLunchTime(context, false),
                icon: Icons.restaurant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStandbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Standby Time',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                label: 'Start',
                time: _standbyStart,
                onTap: () => _selectStandbyTime(context, true),
                icon: Icons.pause_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                label: 'End',
                time: _standbyEnd,
                onTap: () => _selectStandbyTime(context, false),
                icon: Icons.pause_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isClockIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isClockIn ? _clockInTime : _clockOutTime,
    );

    if (picked != null) {
      setState(() {
        if (isClockIn) {
          _clockInTime = picked;
        } else {
          _clockOutTime = picked;
        }
      });
    }
  }

  Future<void> _selectLunchTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _lunchStart : _lunchEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _lunchStart = picked;
        } else {
          _lunchEnd = picked;
        }
      });
    }
  }

  Future<void> _selectStandbyTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _standbyStart : _standbyEnd,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _standbyStart = picked;
        } else {
          _standbyEnd = picked;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir fecha completa para clock-in y clock-out
      final date = widget.worker.clockIn;
      final clockIn = DateTime(
        date.year,
        date.month,
        date.day,
        _clockInTime.hour,
        _clockInTime.minute,
      );
      final clockOut = DateTime(
        date.year,
        date.month,
        date.day,
        _clockOutTime.hour,
        _clockOutTime.minute,
      );

      // Calcular duraciones
      final lunchDuration = Duration(
        hours: _lunchEnd.hour - _lunchStart.hour,
        minutes: _lunchEnd.minute - _lunchStart.minute,
      );
      final standbyDuration = Duration(
        hours: _standbyEnd.hour - _standbyStart.hour,
        minutes: _standbyEnd.minute - _standbyStart.minute,
      );

      final updates = {
        'clock_in': clockIn.toIso8601String(),
        'clock_out': clockOut.toIso8601String(),
        'lunch_duration': '${lunchDuration.inHours.toString().padLeft(2, '0')}:${(lunchDuration.inMinutes % 60).toString().padLeft(2, '0')}:00',
        'standby_duration': '${standbyDuration.inHours.toString().padLeft(2, '0')}:${(standbyDuration.inMinutes % 60).toString().padLeft(2, '0')}:00',
      };

      final success = await ref
          .read(workerReportProvider(widget.params).notifier)
          .editWorker(
            workerId: widget.worker.workerId,
            updates: updates,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Worker updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update worker'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
