import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpath_app/core/pallet.dart';

enum UserRole { student, teacher }

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final formKey = GlobalKey<FormState>();
  UserRole? selectedRole;
  bool isLoading = false;

  Future<void> _registerUser() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si us plau, selecciona un rol')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create user using Firebase Authentication
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      // Save information in the Firebase Database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': email.text.trim(),
        'name': name.text.trim(),
        'role': selectedRole!.name
      });

      // Navegation to screen depending on the profile
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          selectedRole == UserRole.student ? '/studenthome' : '/teacherhome',
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  void _handleAuthError(FirebaseAuthException e) {
    String message = 'Error en el registre';
    switch (e.code) {
      case 'email-already-in-use':
        message = 'Aquest correu electrònic ja està registrat';
        break;
      case 'weak-password':
        message = 'La contrasenya és massa feble';
        break;
      case 'invalid-email':
        message = 'Correu electrònic invàlid';
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildBackground(),
          buildBackground2(),
          buildForm(),
          if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.black)),
        ],
      ),
    );
  }

  Widget buildBackground() {
    return Stack(
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -1),
          child: Image.asset(
            'images/smartpath_logo_inverse.png',
            width: 270,
          ),
        ),
      ],
    );
  }

  Widget buildForm() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 675,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                buildEmailField(),
                const SizedBox(height: 20),
                buildNameField(),
                const SizedBox(height: 20),
                buildPasswordField(),
                const SizedBox(height: 30),
                buildRoleSelector(),
                const SizedBox(height: 40),
                buildRegisterButton(),
                buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBackground2() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 675,
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/smartpath_logo_inverse.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget buildEmailField() {
    return TextFormField(
      controller: email,
      decoration: inputDecoration('Email', 'Introdueix el teu email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) => value!.isEmpty ? 'Introdueix un email' : null,
    );
  }

  Widget buildNameField() {
    return TextFormField(
      controller: name,
      decoration: inputDecoration('Nom', 'Introdueix el teu nom'),
      validator: (value) => value!.isEmpty ? 'Introdueix el teu nom' : null,
    );
  }

  Widget buildPasswordField() {
    return TextFormField(
      controller: password,
      decoration: inputDecoration('Contrasenya', 'Introdueix la teva contrasenya'),
      obscureText: true,
      validator: (value) => value!.length < 6 ? 'Mínim 6 caràcters' : null,
    );
  }

  Widget buildRoleSelector() {
    return Column(
      children: UserRole.values.map((role) {
        return RadioListTile<UserRole>(
          title: Text(role.name == 'student' ? 'Estudiant' : 'Professor'),
          value: role,
          groupValue: selectedRole,
          onChanged: (value) => setState(() => selectedRole = value),
        );
      }).toList(),
    );
  }

  Widget buildRegisterButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _registerUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        "Registra't",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Ja tens un compte?"),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: Text(
            "Inicia sessió",
            style: TextStyle(color: primaryColor),
          ),
        )
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