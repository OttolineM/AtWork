import 'package:flutter/material.dart';

void main() {
  runApp(const AtWorkApp());
}

const navy = Color(0xFF101C32);
const gold = Color(0xFFC8A96B);
const background = Color(0xFFF7F8FA);

class AtWorkApp extends StatelessWidget {
  const AtWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AtWork',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: gold,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: gold, width: 2),
          ),
        ),
      ),
      home: const AuthenticationScreen(),
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isRegistering = true;
  bool hidePassword = true;
  bool acceptedTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    if (isRegistering && !acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRegistering
              ? 'Registration form completed! Account setup still needs connecting.'
              : 'Login form completed! Account authentication still needs connecting.',
        ),
      ),
    );
  }

  Widget fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        label,
        style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 66,
                    width: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'A',
                      style: TextStyle(
                        color: gold,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'AtWork',
                    style: TextStyle(
                      color: navy,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Everyday skills. New opportunities.',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: modeButton('Register', true)),
                        Expanded(child: modeButton('Login', false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isRegistering
                        ? 'Create your contributor account'
                        : 'Welcome back',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isRegistering
                        ? 'Join AtWork and explore available activities.'
                        : 'Sign in to continue to your AtWork account.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isRegistering) ...[
                          fieldLabel('Full name'),
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                        ],
                        fieldLabel('Email address'),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: validateEmail,
                        ),
                        fieldLabel('Password'),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (isRegistering && value.length < 8) {
                              return 'Use at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          fieldLabel('Confirm password'),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            decoration: const InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                acceptedTerms = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: navy,
                            title: const Text(
                              'I agree to the AtWork terms and conditions.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isRegistering ? 'Create account' : 'Sign in',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'AtWork is being prepared. Account creation and '
                    'sign-in will be connected to secure authentication '
                    'before launch.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget modeButton(String label, bool registerMode) {
    final selected = isRegistering == registerMode;

    return TextButton(
      onPressed: () {
        setState(() {
          isRegistering = registerMode;
          formKey.currentState?.reset();
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selected ? navy : Colors.transparent,
        foregroundColor: selected ? Colors.white : navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
