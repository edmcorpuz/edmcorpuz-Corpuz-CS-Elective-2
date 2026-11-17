import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/account_controller.dart';
import '../theme/app_theme.dart';
import 'product_form.dart';

/// Returns true when someone signed in with email. A GitHub sign-in leaves
/// the page and comes back signed in, so it never returns true here.
Future<bool?> showSignInDialog(BuildContext context, {String? reason}) =>
    showDialog<bool>(context: context, builder: (_) => SignInDialog(reason: reason));

class SignInDialog extends ConsumerStatefulWidget {
  const SignInDialog({super.key, this.reason});

  /// Why we're asking, e.g. "Sign in to check out." Shown above the options.
  final String? reason;

  @override
  ConsumerState<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<SignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _leavingForGitHub = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _github() async {
    setState(() {
      _busy = true;
      _leavingForGitHub = true;
      _error = null;
    });
    try {
      await ref.read(accountProvider.notifier).signInWithGitHub();
      // On phones the browser opens on top; close the dialog behind it.
      if (mounted) Navigator.of(context).pop(false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _leavingForGitHub = false;
        _error = describeError(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountProvider.notifier).signInWithEmail(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text('Sign in to FACET', style: displayStyle(28)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.reason ?? 'Sign in to check out. Store admins also get the tools to manage the catalogue.',
                    style: const TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _busy ? null : _github,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.text,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.surfaceHigh,
                    ),
                    icon: _leavingForGitHub
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
                          )
                        : const _GitHubMark(),
                    label: Text(_leavingForGitHub ? 'Opening GitHub…' : 'Continue with GitHub'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New here? GitHub creates your FACET account the first time.',
                    textAlign: TextAlign.center,
                    style: monoLabel(size: 9.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR USE EMAIL', style: monoLabel(size: 9.5)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v ?? '').trim().contains('@') ? null : 'Enter your email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: AppColors.danger, height: 1.4)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _submit,
          child: _busy && !_leavingForGitHub
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sign in with email'),
        ),
      ],
    );
  }
}

/// The GitHub mark (Octocat silhouette), drawn so no image asset is needed.
class _GitHubMark extends StatelessWidget {
  const _GitHubMark();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.black;
    return SizedBox.square(dimension: 18, child: CustomPaint(painter: _GitHubMarkPainter(color)));
  }
}

class _GitHubMarkPainter extends CustomPainter {
  _GitHubMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Path traced from the 16×16 GitHub mark.
    final s = size.width / 16;
    final p = Path()
      ..moveTo(8 * s, 0)
      ..cubicTo(3.58 * s, 0, 0, 3.58 * s, 0, 8 * s)
      ..cubicTo(0, 11.54 * s, 2.29 * s, 14.53 * s, 5.47 * s, 15.59 * s)
      ..cubicTo(5.87 * s, 15.66 * s, 6.02 * s, 15.42 * s, 6.02 * s, 15.21 * s)
      ..cubicTo(6.02 * s, 15.02 * s, 6.01 * s, 14.39 * s, 6.01 * s, 13.72 * s)
      ..cubicTo(4 * s, 14.09 * s, 3.48 * s, 13.23 * s, 3.32 * s, 12.78 * s)
      ..cubicTo(3.23 * s, 12.55 * s, 2.84 * s, 11.84 * s, 2.5 * s, 11.65 * s)
      ..cubicTo(2.22 * s, 11.5 * s, 1.82 * s, 11.13 * s, 2.49 * s, 11.12 * s)
      ..cubicTo(3.12 * s, 11.11 * s, 3.57 * s, 11.7 * s, 3.72 * s, 11.94 * s)
      ..cubicTo(4.44 * s, 13.15 * s, 5.59 * s, 12.81 * s, 6.05 * s, 12.6 * s)
      ..cubicTo(6.12 * s, 12.08 * s, 6.33 * s, 11.73 * s, 6.56 * s, 11.53 * s)
      ..cubicTo(4.78 * s, 11.33 * s, 2.92 * s, 10.64 * s, 2.92 * s, 7.58 * s)
      ..cubicTo(2.92 * s, 6.71 * s, 3.23 * s, 5.99 * s, 3.74 * s, 5.43 * s)
      ..cubicTo(3.66 * s, 5.23 * s, 3.38 * s, 4.41 * s, 3.82 * s, 3.31 * s)
      ..cubicTo(3.82 * s, 3.31 * s, 4.49 * s, 3.1 * s, 6.02 * s, 4.13 * s)
      ..cubicTo(6.66 * s, 3.95 * s, 7.34 * s, 3.86 * s, 8.02 * s, 3.86 * s)
      ..cubicTo(8.7 * s, 3.86 * s, 9.38 * s, 3.95 * s, 10.02 * s, 4.13 * s)
      ..cubicTo(11.55 * s, 3.09 * s, 12.22 * s, 3.31 * s, 12.22 * s, 3.31 * s)
      ..cubicTo(12.66 * s, 4.41 * s, 12.38 * s, 5.23 * s, 12.3 * s, 5.43 * s)
      ..cubicTo(12.81 * s, 5.99 * s, 13.12 * s, 6.7 * s, 13.12 * s, 7.58 * s)
      ..cubicTo(13.12 * s, 10.65 * s, 11.25 * s, 11.33 * s, 9.47 * s, 11.53 * s)
      ..cubicTo(9.76 * s, 11.78 * s, 10.01 * s, 12.26 * s, 10.01 * s, 13.01 * s)
      ..cubicTo(10.01 * s, 14.08 * s, 10 * s, 14.94 * s, 10 * s, 15.21 * s)
      ..cubicTo(10 * s, 15.42 * s, 10.15 * s, 15.67 * s, 10.55 * s, 15.59 * s)
      ..cubicTo(13.71 * s, 14.53 * s, 16 * s, 11.53 * s, 16 * s, 8 * s)
      ..cubicTo(16 * s, 3.58 * s, 12.42 * s, 0, 8 * s, 0)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GitHubMarkPainter old) => old.color != color;
}
