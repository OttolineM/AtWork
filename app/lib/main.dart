import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const navy = Color(0xFF101C32);
const gold = Color(0xFFC8A96B);
const background = Color(0xFFF7F8FA);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const AtWorkApp(configurationError: true));
    return;
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    runApp(const AtWorkApp());
  } catch (error) {
    runApp(AtWorkApp(startupError: error.toString()));
  }
}

class AtWorkApp extends StatelessWidget {
  const AtWorkApp({super.key, this.configurationError = false, this.startupError});

  final bool configurationError;
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AtWork',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: gold),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      home: configurationError
          ? const SetupMessage(message: 'AtWork needs its secure connection settings before it can start. Please install the latest app build.')
          : startupError != null
              ? SetupMessage(message: 'AtWork could not connect securely. Please check your connection and try again. Details: $startupError')
              : const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = client.auth.currentSession;
        if (session != null) return const ContributorHomeScreen();
        return const AuthenticationScreen();
      },
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
  bool isLoading = false;
  String? infoMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email address';
    if (!RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (isRegistering && !acceptedTerms) {
      showMessage('Please accept the terms to continue.');
      return;
    }
    setState(() { isLoading = true; infoMessage = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (isRegistering) {
        final response = await auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
            'role': 'contributor',
          },
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            infoMessage = 'Your account has been created. Check your email for a confirmation link, then return here to sign in.';
            isRegistering = false;
          });
        }
        // If email confirmation is disabled, Supabase signs the new user in automatically.
      } else {
        await auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) showMessage(friendlyAuthError(error.message));
    } catch (error) {
      if (mounted) showMessage('Something went wrong. Please check your internet connection and try again.');
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  String friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('invalid login credentials')) return 'Email or password is incorrect.';
    if (lower.contains('password')) return message;
    if (lower.contains('email not confirmed')) return 'Please confirm your email address before signing in.';
    return message;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(label, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
  );

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
                    height: 66, width: 66, alignment: Alignment.center,
                    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
                    child: const Text('A', style: TextStyle(color: gold, fontSize: 38, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 22),
                  const Text('AtWork', style: TextStyle(color: navy, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  const Text('Everyday skills. New opportunities.', style: TextStyle(color: Colors.black54, fontSize: 15)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Expanded(child: modeButton('Register', true)),
                      Expanded(child: modeButton('Login', false)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text(isRegistering ? 'Create your contributor account' : 'Welcome back',
                    style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(isRegistering ? 'Join AtWork and explore available activities.' : 'Sign in to continue to your AtWork account.',
                    style: const TextStyle(color: Colors.black54)),
                  if (infoMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(10)),
                      child: Text(infoMessage!, style: const TextStyle(color: Color(0xFF245B35))),
                    ),
                  ],
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your full name' : null,
                          ),
                        ],
                        fieldLabel('Email address'),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                          validator: validateEmail,
                        ),
                        fieldLabel('Password'),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: isRegistering ? TextInputAction.next : TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePassword = !hidePassword),
                              icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (isRegistering && value.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          fieldLabel('Confirm password'),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            decoration: const InputDecoration(hintText: 'Re-enter your password', prefixIcon: Icon(Icons.lock_outline)),
                            validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: acceptedTerms,
                            onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: navy,
                            title: const Text('I agree to the AtWork terms and conditions.', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isRegistering ? 'Create account' : 'Sign in',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (!isRegistering) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () async {
                              if (validateEmail(emailController.text) != null) {
                                showMessage('Enter your email address above first.');
                                return;
                              }
                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(emailController.text.trim());
                                if (mounted) showMessage('Password reset instructions have been sent if the account exists.');
                              } on AuthException catch (error) {
                                if (mounted) showMessage(error.message);
                              }
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Your information is handled securely. AtWork will never charge a joining fee.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
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
      onPressed: isLoading ? null : () => setState(() {
        isRegistering = registerMode;
        infoMessage = null;
        formKey.currentState?.reset();
      }),
      style: TextButton.styleFrom(
        backgroundColor: selected ? navy : Colors.transparent,
        foregroundColor: selected ? Colors.white : navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class ContributorHomeScreen extends StatelessWidget {
  const ContributorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Contributor';
    return Scaffold(
      appBar: AppBar(
        title: const Text('AtWork', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: navy),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: gold, size: 58),
              const SizedBox(height: 18),
              Text('Welcome, $name', textAlign: TextAlign.center,
                style: const TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Your AtWork account is active.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 18),
              const Text('The contributor work area is the next part being prepared. No tasks or earnings are available until a funded project is approved.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout), label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupMessage extends StatelessWidget {
  const SetupMessage({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: gold, size: 48),
          const SizedBox(height: 16),
          const Text('AtWork', style: TextStyle(color: navy, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
).hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (isRegistering && !acceptedTerms) {
      showMessage('Please accept the terms to continue.');
      return;
    }
    setState(() { isLoading = true; infoMessage = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (isRegistering) {
        final response = await auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
            'role': 'contributor',
          },
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            infoMessage = 'Your account has been created. Check your email for a confirmation link, then return here to sign in.';
            isRegistering = false;
          });
        }
        // If email confirmation is disabled, Supabase signs the new user in automatically.
      } else {
        await auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) showMessage(friendlyAuthError(error.message));
    } catch (error) {
      if (mounted) showMessage('Something went wrong. Please check your internet connection and try again.');
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  String friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('invalid login credentials')) return 'Email or password is incorrect.';
    if (lower.contains('password')) return message;
    if (lower.contains('email not confirmed')) return 'Please confirm your email address before signing in.';
    return message;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(label, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
  );

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
                    height: 66, width: 66, alignment: Alignment.center,
                    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
                    child: const Text('A', style: TextStyle(color: gold, fontSize: 38, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 22),
                  const Text('AtWork', style: TextStyle(color: navy, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  const Text('Everyday skills. New opportunities.', style: TextStyle(color: Colors.black54, fontSize: 15)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Expanded(child: modeButton('Register', true)),
                      Expanded(child: modeButton('Login', false)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text(isRegistering ? 'Create your contributor account' : 'Welcome back',
                    style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(isRegistering ? 'Join AtWork and explore available activities.' : 'Sign in to continue to your AtWork account.',
                    style: const TextStyle(color: Colors.black54)),
                  if (infoMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(10)),
                      child: Text(infoMessage!, style: const TextStyle(color: Color(0xFF245B35))),
                    ),
                  ],
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your full name' : null,
                          ),
                        ],
                        fieldLabel('Email address'),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                          validator: validateEmail,
                        ),
                        fieldLabel('Password'),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: isRegistering ? TextInputAction.next : TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePassword = !hidePassword),
                              icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (isRegistering && value.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          fieldLabel('Confirm password'),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            decoration: const InputDecoration(hintText: 'Re-enter your password', prefixIcon: Icon(Icons.lock_outline)),
                            validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: acceptedTerms,
                            onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: navy,
                            title: const Text('I agree to the AtWork terms and conditions.', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isRegistering ? 'Create account' : 'Sign in',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (!isRegistering) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () async {
                              if (validateEmail(emailController.text) != null) {
                                showMessage('Enter your email address above first.');
                                return;
                              }
                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(emailController.text.trim());
                                if (mounted) showMessage('Password reset instructions have been sent if the account exists.');
                              } on AuthException catch (error) {
                                if (mounted) showMessage(error.message);
                              }
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Your information is handled securely. AtWork will never charge a joining fee.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
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
      onPressed: isLoading ? null : () => setState(() {
        isRegistering = registerMode;
        infoMessage = null;
        formKey.currentState?.reset();
      }),
      style: TextButton.styleFrom(
        backgroundColor: selected ? navy : Colors.transparent,
        foregroundColor: selected ? Colors.white : navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class ContributorHomeScreen extends StatelessWidget {
  const ContributorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Contributor';
    return Scaffold(
      appBar: AppBar(
        title: const Text('AtWork', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: navy),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: gold, size: 58),
              const SizedBox(height: 18),
              Text('Welcome, $name', textAlign: TextAlign.center,
                style: const TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Your AtWork account is active.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 18),
              const Text('The contributor work area is the next part being prepared. No tasks or earnings are available until a funded project is approved.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout), label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupMessage extends StatelessWidget {
  const SetupMessage({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: gold, size: 48),
          const SizedBox(height: 16),
          const Text('AtWork', style: TextStyle(color: navy, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
).hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (isRegistering && !acceptedTerms) {
      showMessage('Please accept the terms to continue.');
      return;
    }
    setState(() { isLoading = true; infoMessage = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (isRegistering) {
        final response = await auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
            'role': 'contributor',
          },
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            infoMessage = 'Your account has been created. Check your email for a confirmation link, then return here to sign in.';
            isRegistering = false;
          });
        }
        // If email confirmation is disabled, Supabase signs the new user in automatically.
      } else {
        await auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) showMessage(friendlyAuthError(error.message));
    } catch (error) {
      if (mounted) showMessage('Something went wrong. Please check your internet connection and try again.');
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  String friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('invalid login credentials')) return 'Email or password is incorrect.';
    if (lower.contains('password')) return message;
    if (lower.contains('email not confirmed')) return 'Please confirm your email address before signing in.';
    return message;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(label, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
  );

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
                    height: 66, width: 66, alignment: Alignment.center,
                    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
                    child: const Text('A', style: TextStyle(color: gold, fontSize: 38, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 22),
                  const Text('AtWork', style: TextStyle(color: navy, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  const Text('Everyday skills. New opportunities.', style: TextStyle(color: Colors.black54, fontSize: 15)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Expanded(child: modeButton('Register', true)),
                      Expanded(child: modeButton('Login', false)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text(isRegistering ? 'Create your contributor account' : 'Welcome back',
                    style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(isRegistering ? 'Join AtWork and explore available activities.' : 'Sign in to continue to your AtWork account.',
                    style: const TextStyle(color: Colors.black54)),
                  if (infoMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(10)),
                      child: Text(infoMessage!, style: const TextStyle(color: Color(0xFF245B35))),
                    ),
                  ],
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your full name' : null,
                          ),
                        ],
                        fieldLabel('Email address'),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                          validator: validateEmail,
                        ),
                        fieldLabel('Password'),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: isRegistering ? TextInputAction.next : TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePassword = !hidePassword),
                              icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (isRegistering && value.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          fieldLabel('Confirm password'),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            decoration: const InputDecoration(hintText: 'Re-enter your password', prefixIcon: Icon(Icons.lock_outline)),
                            validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: acceptedTerms,
                            onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: navy,
                            title: const Text('I agree to the AtWork terms and conditions.', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isRegistering ? 'Create account' : 'Sign in',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (!isRegistering) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () async {
                              if (validateEmail(emailController.text) != null) {
                                showMessage('Enter your email address above first.');
                                return;
                              }
                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(emailController.text.trim());
                                if (mounted) showMessage('Password reset instructions have been sent if the account exists.');
                              } on AuthException catch (error) {
                                if (mounted) showMessage(error.message);
                              }
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Your information is handled securely. AtWork will never charge a joining fee.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
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
      onPressed: isLoading ? null : () => setState(() {
        isRegistering = registerMode;
        infoMessage = null;
        formKey.currentState?.reset();
      }),
      style: TextButton.styleFrom(
        backgroundColor: selected ? navy : Colors.transparent,
        foregroundColor: selected ? Colors.white : navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class ContributorHomeScreen extends StatelessWidget {
  const ContributorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Contributor';
    return Scaffold(
      appBar: AppBar(
        title: const Text('AtWork', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: navy),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: gold, size: 58),
              const SizedBox(height: 18),
              Text('Welcome, $name', textAlign: TextAlign.center,
                style: const TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Your AtWork account is active.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 18),
              const Text('The contributor work area is the next part being prepared. No tasks or earnings are available until a funded project is approved.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout), label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupMessage extends StatelessWidget {
  const SetupMessage({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: gold, size: 48),
          const SizedBox(height: 16),
          const Text('AtWork', style: TextStyle(color: navy, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
).hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (isRegistering && !acceptedTerms) {
      showMessage('Please accept the terms to continue.');
      return;
    }
    setState(() { isLoading = true; infoMessage = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (isRegistering) {
        final response = await auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          data: {
            'full_name': nameController.text.trim(),
            'role': 'contributor',
          },
        );
        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            infoMessage = 'Your account has been created. Check your email for a confirmation link, then return here to sign in.';
            isRegistering = false;
          });
        }
        // If email confirmation is disabled, Supabase signs the new user in automatically.
      } else {
        await auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) showMessage(friendlyAuthError(error.message));
    } catch (error) {
      if (mounted) showMessage('Something went wrong. Please check your internet connection and try again.');
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  String friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('invalid login credentials')) return 'Email or password is incorrect.';
    if (lower.contains('password')) return message;
    if (lower.contains('email not confirmed')) return 'Please confirm your email address before signing in.';
    return message;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(label, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
  );

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
                    height: 66, width: 66, alignment: Alignment.center,
                    decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
                    child: const Text('A', style: TextStyle(color: gold, fontSize: 38, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 22),
                  const Text('AtWork', style: TextStyle(color: navy, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  const Text('Everyday skills. New opportunities.', style: TextStyle(color: Colors.black54, fontSize: 15)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    child: Row(children: [
                      Expanded(child: modeButton('Register', true)),
                      Expanded(child: modeButton('Login', false)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text(isRegistering ? 'Create your contributor account' : 'Welcome back',
                    style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(isRegistering ? 'Join AtWork and explore available activities.' : 'Sign in to continue to your AtWork account.',
                    style: const TextStyle(color: Colors.black54)),
                  if (infoMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(10)),
                      child: Text(infoMessage!, style: const TextStyle(color: Color(0xFF245B35))),
                    ),
                  ],
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
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your full name' : null,
                          ),
                        ],
                        fieldLabel('Email address'),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                          validator: validateEmail,
                        ),
                        fieldLabel('Password'),
                        TextFormField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          textInputAction: isRegistering ? TextInputAction.next : TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => hidePassword = !hidePassword),
                              icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (isRegistering && value.length < 8) return 'Use at least 8 characters';
                            return null;
                          },
                        ),
                        if (isRegistering) ...[
                          fieldLabel('Confirm password'),
                          TextFormField(
                            controller: confirmController,
                            obscureText: hidePassword,
                            decoration: const InputDecoration(hintText: 'Re-enter your password', prefixIcon: Icon(Icons.lock_outline)),
                            validator: (value) => value != passwordController.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: acceptedTerms,
                            onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: navy,
                            title: const Text('I agree to the AtWork terms and conditions.', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(isRegistering ? 'Create account' : 'Sign in',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (!isRegistering) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: isLoading ? null : () async {
                              if (validateEmail(emailController.text) != null) {
                                showMessage('Enter your email address above first.');
                                return;
                              }
                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(emailController.text.trim());
                                if (mounted) showMessage('Password reset instructions have been sent if the account exists.');
                              } on AuthException catch (error) {
                                if (mounted) showMessage(error.message);
                              }
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Your information is handled securely. AtWork will never charge a joining fee.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
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
      onPressed: isLoading ? null : () => setState(() {
        isRegistering = registerMode;
        infoMessage = null;
        formKey.currentState?.reset();
      }),
      style: TextButton.styleFrom(
        backgroundColor: selected ? navy : Colors.transparent,
        foregroundColor: selected ? Colors.white : navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class ContributorHomeScreen extends StatelessWidget {
  const ContributorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'Contributor';
    return Scaffold(
      appBar: AppBar(
        title: const Text('AtWork', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout, color: navy),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: gold, size: 58),
              const SizedBox(height: 18),
              Text('Welcome, $name', textAlign: TextAlign.center,
                style: const TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Your AtWork account is active.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 18),
              const Text('The contributor work area is the next part being prepared. No tasks or earnings are available until a funded project is approved.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout), label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupMessage extends StatelessWidget {
  const SetupMessage({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, color: gold, size: 48),
          const SizedBox(height: 16),
          const Text('AtWork', style: TextStyle(color: navy, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
