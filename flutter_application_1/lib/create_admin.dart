import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// This is a one-time script to create the admin account
// Run this once, then you can delete this file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CreateAdminApp());
}

class CreateAdminApp extends StatelessWidget {
  const CreateAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Admin Account',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CreateAdminPage(),
    );
  }
}

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});

  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage> {
  bool _isCreating = false;
  String _message = '';

  Future<void> _createAdminAccount() async {
    setState(() {
      _isCreating = true;
      _message = 'Creating admin account...';
    });

    try {
      // Create admin account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: '99230041249@klu.ac.in',
            password: '123456',
          );

      await userCredential.user?.updateDisplayName('Admin');

      setState(() {
        _message =
            'Admin account created successfully!\n\n'
            'Email: 99230041249@klu.ac.in\n'
            'Password: 123456\n\n'
            'You can now delete this file and use the main app.';
        _isCreating = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _message =
              'Admin account already exists!\n\n'
              'Email: 99230041249@klu.ac.in\n'
              'Password: 123456\n\n'
              'You can use these credentials to sign in.';
        } else {
          _message = 'Error: ${e.message}';
        }
        _isCreating = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin Account'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 32),
              const Text(
                'Admin Account Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click the button below to create the admin account with credentials:\n\n'
                'Email: 99230041249@klu.ac.in\n'
                'Password: 123456',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isCreating ? null : _createAdminAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Create Admin Account',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 32),
              if (_message.isNotEmpty)
                Card(
                  color: _message.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _message.contains('Error')
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
