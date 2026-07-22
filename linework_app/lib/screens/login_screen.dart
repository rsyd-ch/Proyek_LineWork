import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linework_app/services/auth_service.dart';

const _brandColor = Color(0xFF0B4778);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _showPassword = false;
  int _registerStep = 0;
  String? _errorMessage;

  String? _validatePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.isEmpty) return 'Nomor HP wajib diisi.';
    if (digits.length < 10) return 'Nomor HP minimal 10 digit.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password wajib diisi.';
    if (password.length < 6) return 'Password minimal 6 karakter.';
    return null;
  }

  String? _validateName(String? value) {
    if (!_isRegistering || _registerStep < 1) return null;
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama wajib diisi.';
    if (name.length < 3) return 'Nama minimal 3 karakter.';
    return null;
  }

  String? _validateNik(String? value) {
    if (!_isRegistering || _registerStep < 1) return null;
    final nik = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (nik.isEmpty) return 'NIK wajib diisi.';
    if (nik.length < 16) return 'NIK minimal 16 digit.';
    return null;
  }

  bool _validateInputs() {
    FocusScope.of(context).unfocus();
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _signIn() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.signInWithPhonePassword(
        _phoneController.text,
        _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.errorMessage(error, isRegistering: false);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.registerWithContact(
        contact: _phoneController.text,
        isEmail: false,
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nik: _nikController.text.trim(),
        publicBio: _bioController.text.trim(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.errorMessage(error, isRegistering: true);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _nextRegisterStep() {
    if (!_validateInputs()) return;
    setState(() {
      _errorMessage = null;
      _registerStep = 1;
    });
  }

  void _previousRegisterStep() {
    setState(() {
      _errorMessage = null;
      _registerStep = 0;
    });
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _registerStep = 0;
      _errorMessage = null;
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nikController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Image.asset('assets/images/nametag.png', height: 74),
            const SizedBox(height: 18),
            Text(
              _isRegistering ? 'Daftar akun baru' : 'Masuk ke LineWork',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isRegistering
                  ? 'Gunakan nomor HP aktif dan buat password akun.'
                  : 'Masuk memakai nomor HP dan password yang sudah terdaftar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isRegistering) ...[
                    _StepHeader(currentStep: _registerStep),
                    const SizedBox(height: 14),
                  ],
                  if (!_isRegistering || _registerStep == 0) ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        hintText: 'Contoh: 081234567890',
                        prefixIcon: Icon(Icons.phone_iphone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      ],
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Sembunyikan password'
                              : 'Lihat password',
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: !_showPassword,
                      textInputAction: _isRegistering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: _validatePassword,
                      onFieldSubmitted: (_) =>
                          _isRegistering ? _nextRegisterStep() : _signIn(),
                    ),
                  ],
                  if (_isRegistering && _registerStep == 1) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nikController,
                      decoration: const InputDecoration(
                        labelText: 'NIK',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      validator: _validateNik,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio publik',
                        hintText: 'Contoh: siap bantu angkut area sekitar.',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_errorMessage != null) ...[
                    _ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  if (_isRegistering)
                    _RegisterActions(
                      step: _registerStep,
                      isLoading: _isLoading,
                      onBack: _previousRegisterStep,
                      onNext: _nextRegisterStep,
                      onSubmit: _register,
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signIn,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Memproses...' : 'Masuk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB7C7D8),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandColor,
                      side: const BorderSide(color: _brandColor),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(
                      _isRegistering
                          ? 'Sudah punya akun? Masuk'
                          : 'Daftar Akun Baru',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int currentStep;

  const _StepHeader({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = ['Akun', 'Profil'];

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: _StepItem(
              label: labels[index],
              active: index == currentStep,
              done: index < currentStep,
            ),
          ),
          if (index != labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;

  const _StepItem({
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = active || done
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active || done
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RegisterActions extends StatelessWidget {
  final int step;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _RegisterActions({
    required this.step,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (step > 0) ...[
          SizedBox(
            width: 52,
            height: 50,
            child: OutlinedButton(
              onPressed: isLoading ? null : onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : (step == 1 ? onSubmit : onNext),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB7C7D8),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(step == 1 ? 'Buat Akun' : 'Lanjut'),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
