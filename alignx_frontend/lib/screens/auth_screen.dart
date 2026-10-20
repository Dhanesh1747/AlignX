import 'package:flutter/material.dart';
import '../models/auth_session.dart';
import '../services/auth_api_service.dart';

const _ink = Color(0xFF10233F);
const _muted = Color(0xFF65758B);
const _indigo = Color(0xFF4F46E5);

class AuthScreen extends StatefulWidget {
  final ValueChanged<AuthSession> onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _emailController.text.trim();

    try {
      final AuthSession session;
      if (_createAccount) {
        session = await AuthApiService.register(
          name: _nameController.text,
          email: email,
          password: _passwordController.text,
        );
      } else {
        session = await AuthApiService.login(
          email: email,
          password: _passwordController.text,
        );
      }
      widget.onAuthenticated(session);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not reach the AlignX server. Check that the backend and MySQL are running.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    _showMessage('Self-service email recovery is not configured. Contact the project administrator.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF183A61),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _createAccount = !_createAccount;
      _error = null;
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 18, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1040 : 480),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0x171B3150), blurRadius: 40, offset: Offset(0, 20)),
                  ],
                ),
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 5, child: _buildWelcomePanel()),
                          Expanded(flex: 6, child: _buildFormPanel()),
                        ],
                      )
                    : _buildFormPanel(showMobileBrand: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Container(
      constraints: const BoxConstraints(minHeight: 650),
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF192F54), Color(0xFF344F96), Color(0xFF5A4CE2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _brand(light: true),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 28),
              const Text(
                'Make everyday\nmovement count.',
                style: TextStyle(color: Colors.white, fontSize: 38, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Build better posture habits, take mindful breaks, and keep your progress in one place.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 16, height: 1.65),
              ),
              const SizedBox(height: 28),
              _featureRow(Icons.check_circle_outline, 'Simple daily habit tracking'),
              const SizedBox(height: 13),
              _featureRow(Icons.timer_outlined, 'Gentle focus and movement breaks'),
              const SizedBox(height: 13),
              _featureRow(Icons.storage_rounded, 'Your account and habits stored in MySQL'),
            ],
          ),
          Text(
            'Small, consistent steps add up.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String label) => Row(
        children: [
          Icon(icon, color: const Color(0xFFBFC8FF), size: 20),
          const SizedBox(width: 11),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14)),
        ],
      );

  Widget _brand({bool light = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: light ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.accessibility_new_rounded, color: light ? Colors.white : _indigo, size: 25),
          ),
          const SizedBox(width: 11),
          Text('AlignX', style: TextStyle(color: light ? Colors.white : _ink, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        ],
      );

  Widget _buildFormPanel({bool showMobileBrand = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showMobileBrand ? 24 : 52, 38, showMobileBrand ? 24 : 52, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMobileBrand) ...[_brand(), const SizedBox(height: 30)],
            Text(
              _createAccount ? 'Create your account' : 'Welcome back',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 29, letterSpacing: -0.8),
            ),
            const SizedBox(height: 8),
            Text(
              _createAccount ? 'Start building a healthier daily routine.' : 'Sign in to pick up where you left off.',
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 26),
            if (_createAccount) ...[
              _fieldLabel('Full name'),
              _textField(
                controller: _nameController,
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 17),
            ],
            _fieldLabel('Email address'),
            _textField(
              controller: _emailController,
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              validator: _validateEmail,
            ),
            const SizedBox(height: 17),
            _fieldLabel('Password'),
            _textField(
              controller: _passwordController,
              hint: _createAccount ? 'At least 8 characters' : 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _hidePassword,
              textCapitalization: TextCapitalization.none,
              suffix: IconButton(
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted, size: 20),
              ),
              validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null,
            ),
            if (_createAccount) ...[
              const SizedBox(height: 17),
              _fieldLabel('Confirm password'),
              _textField(
                controller: _confirmController,
                hint: 'Re-enter your password',
                icon: Icons.lock_reset_outlined,
                obscureText: _hideConfirm,
                textCapitalization: TextCapitalization.none,
                suffix: IconButton(
                  tooltip: _hideConfirm ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                  icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _muted, size: 20),
                ),
                validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
              ),
            ],
            if (!_createAccount)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
              onPressed: _busy ? null : _sendPasswordReset,
                  style: TextButton.styleFrom(foregroundColor: _indigo, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Forgot password?'),
                ),
              )
            else
              const SizedBox(height: 14),
            if (_error != null) ...[
              const SizedBox(height: 6),
              _errorNotice(_error!),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _indigo,
                  disabledBackgroundColor: const Color(0xFFB9C0D5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_createAccount ? 'Create account' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _createAccount ? 'Already have an account? ' : 'New to AlignX? ',
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _toggleMode,
                    style: TextButton.styleFrom(foregroundColor: _indigo, padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: Text(_createAccount ? 'Sign in' : 'Create an account', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Divider(color: Color(0xFFE8ECF2)),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF8A98AA), size: 16),
                SizedBox(width: 7),
                Flexible(child: Text('Passwords are securely hashed before storage.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      enabled: !_busy,
      style: const TextStyle(color: _ink, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA2ADBD), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8492A6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAFBFD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE3E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE3E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _indigo, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDC5360))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDC5360), width: 1.5)),
      ),
    );
  }

  Widget _errorNotice(String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(11)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFC83F4B), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF9E303A), fontSize: 12, height: 1.4))),
          ],
        ),
      );
}
