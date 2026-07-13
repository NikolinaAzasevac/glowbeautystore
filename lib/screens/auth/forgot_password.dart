import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../../consts/validator.dart';
import '../../services/assets_manager.dart';
import '../../services/my_app_functions.dart';
import '../../widgets/subtitle_text.dart';
import '../../widgets/title_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/ForgotPasswordScreen';
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  late final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void initState() {
    _emailController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _forgetPassFCT() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();
    if (!isValid || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle:
            'Password reset link has been sent. Please check your inbox and spam folder.',
        isError: false,
        fct: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: _authErrorMessage(error),
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
          _isSending = false;
        });
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return error.message ?? 'Password reset email could not be sent.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
// Navigator.canPop(context) ? Navigator.pop(context) : null;
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 20,
            ),
          ),
// automaticallyImplyLeading: false,
          title: const Text("Glow Beauty Store")),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: ListView(
// shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: [
// Section 1 - Header
              const SizedBox(
                height: 10,
              ),
              Image.asset(
                AssetsManager.forgotPassword,
                width: size.width * 0.6,
                height: size.width * 0.6,
              ),
              const SizedBox(
                height: 10,
              ),
              const TitelesTextWidget(
                label: 'Forgot password',
                fontSize: 22,
              ),
              const SubtitleTextWidget(
                label:
                    'Please enter the email address you\'d like your passwordreset information sent to',
                fontSize: 14,
              ),
              const SizedBox(
                height: 40,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'youremail@email.com',
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(IconlyLight.message),
                        ),
                        filled: true,
                      ),
                      validator: (value) {
                        return MyValidators.emailValidator(value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
// backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  icon: const Icon(IconlyBold.send),
                  label: Text(
                    _isSending ? "Sending..." : "Request link",
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  onPressed: _isSending ? null : _forgetPassFCT,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
