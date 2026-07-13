import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glow_beauty_store/consts/validator.dart';
import 'package:glow_beauty_store/screens/auth/forgot_password.dart';
import 'package:glow_beauty_store/screens/auth/register.dart';
import 'package:glow_beauty_store/screens/root_screen.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/auth/auth_brand_header.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = "/LoginScreen";
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscureText = true;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  final _formkey = GlobalKey<FormState>();
  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
// Focus Nodes
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      _emailController.dispose();
      _passwordController.dispose();
// Focus Nodes
      _emailFocusNode.dispose();
      _passwordFocusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loginFct() async {
    final isValid = _formkey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      try {
        setState(() {});

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Fluttertoast.showToast(
          msg: "Signed in successfully",
          textColor: Colors.white,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RootScreen.routeName);
      } on FirebaseException catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.message.toString(),
          fct: () {},
        );
      } catch (error) {
        await MyAppFunctions.showErrorOrWarningDialog(
          context: context,
          subtitle: error.toString(),
          fct: () {},
        );
      } finally {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthBrandHeader(),
                const SizedBox(height: 34),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: TitelesTextWidget(label: "Welcome back")),
                const SizedBox(
                  height: 16,
                ),
                Form(
                  key: _formkey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "Email address",
                          prefixIcon: Icon(
                            IconlyLight.message,
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          FocusScope.of(context)
                              .requestFocus(_passwordFocusNode);
                        },
                        validator: (value) {
                          return MyValidators.emailValidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      TextFormField(
                        obscureText: obscureText,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          hintText: "***********",
                          prefixIcon: const Icon(
                            IconlyLight.lock,
                          ),
                        ),
                        onFieldSubmitted: (value) async {
                          await _loginFct();
                        },
                        validator: (value) {
                          return MyValidators.passwordValidator(value);
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(ForgotPasswordScreen.routeName);
                          },
                          child: const SubtitleTextWidget(
                            label: "Forgot password?",
                            fontStyle: FontStyle.italic,
                            textDecoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
// backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text("Sign in"),
                          onPressed: () async {
                            await _loginFct();
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text("Continue as guest"),
                          onPressed: () async {
                            Navigator.of(context)
                                .pushNamed(RootScreen.routeName);
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SubtitleTextWidget(label: "New here?"),
                          TextButton(
                            child: const SubtitleTextWidget(
                              label: "Sign up",
                              fontStyle: FontStyle.italic,
                              textDecoration: TextDecoration.underline,
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(RegisterScreen.routeName);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
