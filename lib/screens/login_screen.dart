import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartpath_app/core/pallet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async{
    setState(() => _isLoading = true);

    try {
      // Use an existing credential of the Firebase Authentication to login
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get user role from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final role = userDoc.data()!['role'] as String;
      
      // Navigate to the corresponding screen depending on the profile
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          role == 'student' ? '/studenthome' : '/teacherhome',
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = "Error en l'inici de sessió";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Credencials incorrectes';
      } else if (e.code == 'invalid-email') {
        message = 'Format d\'email invàlid';
      }
      _showError(message);
      } catch (e) {
        _showError('Error desconegut: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
              buildBackground(),
              buildForm(),
              if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.black)),
        ],
      ),
    );
  }

Widget buildForm() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 440,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              TextField(
                controller: _emailController,
                decoration: inputDecoration('Email', 'Introdueix el teu email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                decoration: inputDecoration('Contrasenya', 'Introdueix la teva contrasenya'),
                obscureText: true,
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Has oblidat la contrasenya?',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Iniciar sessió',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No tens un compte?"),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      "Registra't",
                      style: TextStyle(color: primaryColor),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

Widget buildBackground(){
  return Stack(
    children: [
      Container(
        height: 475,
        width: double.infinity,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(60),
          ),
        ),
      ),
      Align(
        alignment: Alignment(0, -0.70),
        child: Image.asset('images/smartpath_logo_inverse.png',
        width: 350,
        ),
      ),
      Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 440,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/smartpath_logo_inverse.png'),
            fit: BoxFit.cover 
          )
        ),
       ),
      ),
    ],
  );
}

InputDecoration inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}