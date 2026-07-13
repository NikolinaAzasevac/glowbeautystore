import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowbeautystore_admin/services/admin_role_service.dart';
import 'package:glowbeautystore_admin/services/assets_manager.dart';
import 'package:glowbeautystore_admin/services/my_app_functions.dart';
import 'package:glowbeautystore_admin/widgets/app_name_text.dart';
import 'package:glowbeautystore_admin/widgets/subtitle_text.dart';
import 'package:glowbeautystore_admin/widgets/title_text.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscureText = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || !value.contains('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().length < 6) {
      return 'Password must have at least 6 characters';
    }
    return null;
  }

  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'admin-login-failed',
          message: 'Unable to complete admin sign in.',
        );
      }

      final isAdmin = await AdminRoleService.isAdminUser(user.uid);
      if (!isAdmin) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle:
              'This account does not have administrator access. Set role = admin in Firestore users collection.',
          fct: () {},
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? 'Admin login failed.',
        fct: () {},
      );
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AssetsManager.shoppingCart,
                          height: 56,
                          width: 56,
                        ),
                        const SizedBox(width: 12),
                        const AppNameTextWidget(fontSize: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const TitlesTextWidget(label: 'Administrator Login'),
                    const SizedBox(height: 8),
                    const SubtitleTextWidget(
                      label:
                          'Sign in with an account that has role = admin in Firestore.',
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Admin email',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: _passwordValidator,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _login,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  _isSubmitting ? 'Signing in...' : 'Sign In',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnauthorizedAdminScreen extends StatelessWidget {
  const UnauthorizedAdminScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AssetsManager.warning,
                  height: 72,
                  width: 72,
                ),
                const SizedBox(height: 20),
                const TitlesTextWidget(label: 'Admin access required'),
                const SizedBox(height: 8),
                const SubtitleTextWidget(
                  label:
                      'This account is authenticated, but it does not have the admin role in Firestore.',
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
