import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

// Temporary localization class
class _TempLocalizations {
  static const recoverPassword = 'Recover Password';
  static const forgotPassword = 'Forgot Password?';
  static const enterEmailInstruction = 'Enter your email address and we\'ll send you a verification code to reset your password.';
  static const email = 'Email';
  static const emailHint = 'Enter your email';
  static const sendCode = 'Send Code';
  static const backToLogin = 'Back to Login';
  static const loading = 'Loading...';
  static const emailRequired = 'Email is required';
  static const emailInvalid = 'Please enter a valid email';
  static const verificationCode = 'Verification Code';
  static const enterCode = 'Enter the verification code sent to your email';
  static const codeHint = 'Enter verification code';
  static const verify = 'Verify';
  static const resendCode = 'Resend Code';
  static String _email = '';
  static String _code = '';
  static String _newPassword = '';
  static String _confirmPassword = '';
  static int? _userId;
  static const newPassword = 'New Password';
  static const confirmNewPassword = 'Confirm New Password';
  static const passwordHint = 'Enter your new password';
  static const confirmPasswordHint = 'Confirm your new password';
  static const resetPassword = 'Reset Password';
  static const passwordRequired = 'Password is required';
  static const passwordTooShort = 'Password must be at least 8 characters';
  static const passwordsNotMatch = 'Passwords do not match';
  static const codeRequired = 'Verification code is required';
  static const codeInvalid = 'Code must be at least 4 characters';
}

enum RecoveryStep { email, verification, newPassword }

class RecoverPasswordPage extends ConsumerStatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  ConsumerState<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends ConsumerState<RecoverPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  RecoveryStep _currentStep = RecoveryStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailValid = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final isValid = EmailValidator.validate(_emailController.text.trim());
    if (isValid != _isEmailValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  Future<void> _handleSendCode() async {
    ref.read(authProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await ref.read(authProvider.notifier).verifyEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _currentStep = RecoveryStep.verification;
        _userId = result['user_id'];
      });
      _showSuccessSnackBar('Verification code sent to your email');
    } else {
      final error = result['message'] ?? 'Email verification failed';
      _showErrorSnackBar(error);
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId == null) {
      _showErrorSnackBar('Invalid session. Please start over.');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authProvider.notifier).verifyCode(
      _codeController.text.trim(),
      _userId!,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _currentStep = RecoveryStep.newPassword);
      _showSuccessSnackBar('Code verified successfully');
    } else {
      final error = ref.read(authProvider).error;
      _showErrorSnackBar(error ?? 'Invalid verification code');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId == null) {
      _showErrorSnackBar('Invalid session. Please start over.');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authProvider.notifier).changePassword(
      _passwordController.text.trim(),
      _userId!,
    );
    
    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('Password reset successfully! Please login with your new password.');
      context.go('/login');
    } else {
      final error = ref.read(authProvider).error;
      _showErrorSnackBar(error ?? 'Failed to reset password');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _getStepTitle(),
                            style: AppTextStyles.displayLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Step indicator
                        _buildStepIndicator(),
                        const SizedBox(height: 32),

                        // Content based on current step
                        _buildStepContent(),

                        const SizedBox(height: 32),

                        // Action button
                        _buildActionButton(authState.isLoading),
                        const SizedBox(height: 24),

                        // Back to login link
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              _TempLocalizations.backToLogin,
                              style: AppTextStyles.linkLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _TempLocalizations.loading,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case RecoveryStep.email:
        return _TempLocalizations.recoverPassword;
      case RecoveryStep.verification:
        return _TempLocalizations.verificationCode;
      case RecoveryStep.newPassword:
        return _TempLocalizations.newPassword;
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, _currentStep.index >= 0),
        _buildStepLine(_currentStep.index >= 1),
        _buildStepCircle(2, _currentStep.index >= 1),
        _buildStepLine(_currentStep.index >= 2),
        _buildStepCircle(3, _currentStep.index >= 2),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.borderLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : AppColors.borderLight,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case RecoveryStep.email:
        return _buildEmailStep();
      case RecoveryStep.verification:
        return _buildVerificationStep();
      case RecoveryStep.newPassword:
        return _buildNewPasswordStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _TempLocalizations.forgotPassword,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 12),
        Text(
          _TempLocalizations.enterEmailInstruction,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildEmailField(),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _TempLocalizations.verificationCode,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 12),
        Text(
          _TempLocalizations.enterCode,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        _buildCodeField(),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _handleSendCode,
            child: Text(
              _TempLocalizations.resendCode,
              style: AppTextStyles.link,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _TempLocalizations.resetPassword,
          style: AppTextStyles.h1,
        ),
        const SizedBox(height: 24),
        _buildNewPasswordField(),
        const SizedBox(height: 16),
        _buildConfirmPasswordField(),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.email],
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: _TempLocalizations.email,
        hintText: _TempLocalizations.emailHint,
        labelStyle: AppTextStyles.inputLabel,
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
        suffixIcon: _isEmailValid
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundWhite,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _TempLocalizations.emailRequired;
        }
        if (!EmailValidator.validate(value.trim())) {
          return _TempLocalizations.emailInvalid;
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleSendCode(),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      focusNode: _codeFocusNode,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      maxLength: 20, // Permitir hasta 20 caracteres
      textAlign: TextAlign.center,
      style: AppTextStyles.inputText.copyWith(
        fontSize: 18, // Reducir tamaño para códigos más largos
        letterSpacing: 2, // Reducir espaciado
      ),
      decoration: InputDecoration(
        labelText: _TempLocalizations.verificationCode,
        hintText: _TempLocalizations.codeHint,
        labelStyle: AppTextStyles.inputLabel,
        hintStyle: AppTextStyles.inputHint,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundWhite,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _TempLocalizations.codeRequired;
        }
        if (value.length < 4) { // Mínimo 4 caracteres
          return 'Code must be at least 4 characters';
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleVerifyCode(),
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: _TempLocalizations.newPassword,
        hintText: _TempLocalizations.passwordHint,
        labelStyle: AppTextStyles.inputLabel,
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textGrey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundWhite,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _TempLocalizations.passwordRequired;
        }
        if (value.length < 8) {
          return _TempLocalizations.passwordTooShort;
        }
        return null;
      },
      onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        labelText: _TempLocalizations.confirmNewPassword,
        hintText: _TempLocalizations.confirmPasswordHint,
        labelStyle: AppTextStyles.inputLabel,
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textGrey,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.backgroundWhite,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _TempLocalizations.passwordRequired;
        }
        if (value != _passwordController.text) {
          return _TempLocalizations.passwordsNotMatch;
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleResetPassword(),
    );
  }

  Widget _buildActionButton(bool isLoading) {
    String buttonText;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case RecoveryStep.email:
        buttonText = _TempLocalizations.sendCode;
        onPressed = isLoading ? null : _handleSendCode;
        break;
      case RecoveryStep.verification:
        buttonText = _TempLocalizations.verify;
        onPressed = isLoading ? null : _handleVerifyCode;
        break;
      case RecoveryStep.newPassword:
        buttonText = _TempLocalizations.resetPassword;
        onPressed = isLoading ? null : _handleResetPassword;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          buttonText,
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}
