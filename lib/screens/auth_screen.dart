import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/account_controller.dart';
import '../theme/app_theme.dart';
import '../three_d/appliance_view.dart';
import '../three_d/appliances.dart';
import '../widgets/facet_logo.dart';
import '../widgets/product_form.dart' show describeError;
import '../widgets/theme_toggle.dart';

/// Log in and sign up. Signed-out visitors see only this screen: the
/// catalogue needs an account (and RLS gives signed-out users nothing).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _leavingForGoogle = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchMode() => setState(() {
        _signUp = !_signUp;
        _error = null;
        _notice = null;
        _formKey.currentState?.reset();
      });

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _leavingForGoogle = true;
      _error = null;
    });
    try {
      await ref.read(accountProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _leavingForGoogle = false;
        _error = describeError(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    final account = ref.read(accountProvider.notifier);
    try {
      if (_signUp) {
        final signedIn = await account.signUp(
          email: _email.text,
          password: _password.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
        );
        if (!signedIn && mounted) {
          setState(() {
            _busy = false;
            _signUp = false;
            _notice = 'Account created. Check ${_email.text.trim()} for a confirmation link, then log in.';
          });
        }
      } else {
        await account.signInWithEmail(email: _email.text, password: _password.text);
      }
      TextInput.finishAutofillContext();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // A Google sign-in that failed on the way back (cancelled, not set up…).
    ref.listen(accountProvider.select((a) => a.error), (_, error) {
      if (error == null) return;
      setState(() => _error = describeError(error));
      ref.read(accountProvider.notifier).clearError();
    });

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final form = _form();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _body(wide, form)),
            const Positioned(top: 8, right: 8, child: ThemeToggle()),
          ],
        ),
      ),
    );
  }

  Widget _body(bool wide, Widget form) {
    return wide
            ? Row(
                children: [
                  Expanded(child: _stage()),
                  SizedBox(
                    width: 480,
                    child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: form)),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [SizedBox(height: 220, child: _stage(compact: true)), form],
                ),
              );
  }

  Widget _stage({bool compact = false}) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: 0.14), Colors.transparent], radius: 0.6),
            ),
          ),
        ),
        const Positioned.fill(
          child: ApplianceView(
            kind: ApplianceKind.fridge,
            color: Color(0xFFF2F2F2),
            detail: MeshDetail.high,
            interactive: true,
            activateOnHover: true,
            speed: 0.3,
          ),
        ),
        Positioned(
          left: compact ? 4 : 40,
          top: compact ? 4 : 36,
          child: FacetLogo(size: compact ? 26 : 32),
        ),
      ],
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_signUp ? 'Create your account' : 'Welcome to FACET', style: displayStyle(38)),
            const SizedBox(height: 10),
            Text(
              _signUp
                  ? 'Shop 3D appliances, keep a cart and track your orders.'
                  : 'Log in or create an account to shop our 3D appliance catalogue and track your orders.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _google,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.bg,
                disabledBackgroundColor: AppColors.surfaceHigh,
              ),
              icon: _leavingForGoogle
                  ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted))
                  : const _GoogleMark(),
              label: Text(_leavingForGoogle ? 'Opening Google…' : 'Continue with Google'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(_signUp ? 'OR SIGN UP WITH EMAIL' : 'OR USE EMAIL', style: monoLabel(size: 9.5)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            if (_signUp) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: const InputDecoration(labelText: 'First name'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your first name' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your last name' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: _signUp ? TextInputAction.next : TextInputAction.done,
              autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: _signUp ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _signUp ? 'At least 6 characters' : null,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Enter a password';
                if (_signUp && v!.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            if (_signUp) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (v) => v == _password.text ? null : 'Passwords don’t match',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: AppColors.danger, height: 1.4)),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 14),
              Text(_notice!, style: TextStyle(color: AppColors.accent, height: 1.4)),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _busy ? null : _submit,
              child: _busy && !_leavingForGoogle
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_signUp ? 'Create account' : 'Log in'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _switchMode,
              child: Text(_signUp ? 'Already have an account? Log in' : 'New to FACET? Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple Google "G" badge, so no image asset is needed.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 14, height: 1),
      ),
    );
  }
}
