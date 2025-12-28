import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/clockin_provider.dart';
import '../models/workday_model.dart';
import 'clockin_dashboard_page.dart';

// Temporary localization class
class _TempLocalizations {
  static const setupWorkday = 'Setup Workday';
  static const entryTime = 'Entry Time';
  static const selectDate = 'Select Date';
  static const selectTime = 'Select Time';
  static const temperature = 'Temperature';
  static const temperatureHint = 'Enter temperature in °F';
  static const automaticClocking = 'Automatic Clock-In';
  static const automaticClockingDesc = 'Do you want to enable automatic clock-in for this workday?';
  static const yes = 'Yes';
  static const no = 'No';
  static const startClocking = 'Start Clock-In';
  static const cancel = 'Cancel';
  static const pleaseSelectDate = 'Please select a date';
  static const pleaseSelectTime = 'Please select a time';
  static const pleaseEnterTemperature = 'Please enter temperature';
  static const temperatureTooHigh = 'Temperature too high (max 110°F)';
  static const temperatureTooLow = 'Temperature too low (min 90°F)';
}

class ClockinSetupPage extends ConsumerStatefulWidget {
  final int contractId;
  final WorkdayModel? existingWorkday;

  const ClockinSetupPage({
    super.key,
    required this.contractId,
    this.existingWorkday,
  });

  @override
  ConsumerState<ClockinSetupPage> createState() => _ClockinSetupPageState();
}

class _ClockinSetupPageState extends ConsumerState<ClockinSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isAutomaticMode = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    // Inicializar sesión con el contractId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clockinProvider.notifier).initializeSession(widget.contractId);
    });
  }

  bool _hasActiveWorkday() {
    final session = ref.read(clockinProvider).session;
    return session?.workday != null && 
           session!.workday!.id != null &&
           !session.workday!.isNotStarted;
  }

  void _initializeDefaults() {
    // Inicializar con valores por defecto o existentes
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);
    
    if (widget.existingWorkday != null) {
      final workday = widget.existingWorkday!;
      if (workday.defaultEntryTime != null) {
        final entryTime = DateTime.parse(workday.defaultEntryTime!);
        _selectedDate = entryTime;
        _selectedTime = TimeOfDay.fromDateTime(entryTime);
      }
      if (workday.temperature != null) {
        _temperatureController.text = workday.temperature!;
      }
      _isAutomaticMode = workday.supervisorClock;
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clockinState = ref.watch(clockinProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          _TempLocalizations.setupWorkday,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(clockinState),
    );
  }

  Widget _buildBody(ClockinState clockinState) {
    final session = clockinState.session;
    final hasActiveWorkday = session?.workday != null && 
                             session!.workday!.id != null &&
                             !session.workday!.isNotStarted;

    // Estado 1: Sin workday activo - Mostrar formulario de setup
    if (!hasActiveWorkday) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildEntryTimeSection(),
              const SizedBox(height: 24),
              _buildAutomaticClockingSection(),
              const SizedBox(height: 40),
              _buildActionButtons(clockinState),
            ],
          ),
        ),
      );
    }

    // Estado 2 y 3: Hay workday activo - Mostrar información y opciones
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveWorkdayInfo(session!),
          const SizedBox(height: 30),
          _buildSupervisorStatusMessage(session),
          const SizedBox(height: 40),
          _buildActiveWorkdayActions(clockinState, session),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Configure Workday Settings',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up the entry time, temperature, and clock-in preferences for this workday.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTimeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _TempLocalizations.entryTime,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Date Selector
          _buildDateSelector(),
          const SizedBox(height: 12),
          
          // Time Selector
          _buildTimeSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderMedium),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _TempLocalizations.selectDate,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDate != null 
                        ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                        : 'No date selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderMedium),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _TempLocalizations.selectTime,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTime != null 
                        ? _selectedTime!.format(context)
                        : 'No time selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.thermostat,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _TempLocalizations.temperature,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: _TempLocalizations.temperatureHint,
              suffixText: '°F',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            validator: _validateTemperature,
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticClockingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _TempLocalizations.automaticClocking,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _TempLocalizations.automaticClockingDesc,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  label: _TempLocalizations.yes,
                  isSelected: _isAutomaticMode,
                  onTap: () => setState(() => _isAutomaticMode = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionButton(
                  label: _TempLocalizations.no,
                  isSelected: !_isAutomaticMode,
                  onTap: () => setState(() => _isAutomaticMode = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderMedium,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ClockinState clockinState) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: clockinState.isLoading ? null : _handleStartClocking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: clockinState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _TempLocalizations.startClocking,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: clockinState.isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _TempLocalizations.cancel,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String? _validateTemperature(String? value) {
    if (value == null || value.isEmpty) {
      return _TempLocalizations.pleaseEnterTemperature;
    }
    
    final temperature = double.tryParse(value);
    if (temperature == null) {
      return 'Please enter a valid number';
    }
    
    if (temperature < 90) {
      return _TempLocalizations.temperatureTooLow;
    }
    
    if (temperature > 110) {
      return _TempLocalizations.temperatureTooHigh;
    }
    
    return null;
  }

  Future<void> _handleStartClocking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDate == null) {
      _showError(_TempLocalizations.pleaseSelectDate);
      return;
    }
    
    if (_selectedTime == null) {
      _showError(_TempLocalizations.pleaseSelectTime);
      return;
    }

    // Combinar fecha y hora
    final entryTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    try {
      await ref.read(clockinProvider.notifier).setupWorkday(
        entryTime: entryTime,
        temperature: '90', // Temperatura hardcodeada
        isAutomaticMode: _isAutomaticMode,
      );

      // Verificar si hubo error en el provider
      final clockinState = ref.read(clockinProvider);
      if (clockinState.error != null) {
        _showError(clockinState.error!);
        return;
      }

      // Verificar que el workday se creó correctamente
      if (clockinState.session?.workday?.id == null) {
        _showError('Failed to create workday. Please try again.');
        return;
      }

      // Navegar al dashboard si fue exitoso
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClockinDashboardPage(
              contractId: widget.contractId,
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Failed to create workday:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar información del workday activo
  Widget _buildActiveWorkdayInfo(session) {
    final workday = session.workday;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Active Workday',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Contract ID', session.contractId ?? 'N/A'),
          _buildInfoRow('Workday ID', workday?.id?.toString() ?? 'N/A'),
          if (workday?.clockInInit != null)
            _buildInfoRow('Inicio', _formatDateTime(workday!.clockInInit!)),
          _buildInfoRow('Total Workers', session.totalWorkers.toString()),
        ],
      ),
    );
  }

  // Mostrar mensaje según estado del supervisor
  Widget _buildSupervisorStatusMessage(session) {
    final supervisorHasClockin = session.supervisorHasClockin;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: supervisorHasClockin ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: supervisorHasClockin ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                supervisorHasClockin ? Icons.check_circle : Icons.warning,
                color: supervisorHasClockin ? AppColors.success : AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supervisorHasClockin 
                      ? 'Process in Progress'
                      : 'Do Your Clock-In to Start',
                  style: AppTextStyles.h3.copyWith(
                    color: supervisorHasClockin ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            supervisorHasClockin
                ? 'You have already registered your entry. You can continue with the worker scanning process.'
                : 'You must register your entry before starting to scan workers, or you can go directly to the process.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // Botones de acción según estado
  Widget _buildActiveWorkdayActions(ClockinState clockinState, session) {
    final supervisorHasClockin = session.supervisorHasClockin;
    
    return Column(
      children: [
        // Si supervisor NO ha hecho clock-in, mostrar botón para hacerlo
        if (!supervisorHasClockin) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: clockinState.isLoading ? null : () async {
                await ref.read(clockinProvider.notifier).doSupervisorClockin();
                if (mounted && !clockinState.isLoading) {
                  // Ir al dashboard después de hacer clock-in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClockinDashboardPage(
                        contractId: widget.contractId,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add),
              label: Text(
                'Do My Clock-In',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Botón para ir al proceso (siempre visible)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: clockinState.isLoading ? null : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClockinDashboardPage(
                    contractId: widget.contractId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              'Go to Process',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
