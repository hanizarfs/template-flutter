import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stayin1/screens/customer/home.dart';
import 'package:stayin1/screens/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stayin1/screens/admin/home.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? selectedRole;

  List<String> roles = ['Admin', 'Customer'];

  bool isPasswordVisible = false; // Untuk melihat atau menyembunyikan password

  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> registerUser(BuildContext context) async {
    try {
      if (_formKey.currentState!.validate()) {
        if (selectedRole == null || selectedRole!.isEmpty) {
          showErrorMessage(context, 'Role cannot be empty');
          return;
        }

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String userRole = selectedRole ?? 'Customer'; // Default role jika null

        // Simpan data pengguna ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'userUUID': userCredential.user!.uid,
          'email': emailController.text,
          'password': passwordController.text,
          'role': userRole,
        });

        redirectToHome(context, emailController.text, userRole);
      }
    } catch (e) {
      showErrorMessage(context, 'Registration failed: $e');
      print('Registration failed: $e');
      print('Selected Role: $selectedRole');
      print('Selected email: ${emailController.text}');
      print('Selected password: ${passwordController.text}');
    }
  }

  Future<void> showRoleSelectionDialog(BuildContext context) async {
    String? role = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Role'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Admin');
              },
              child: const Text('Admin'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'Customer');
              },
              child: const Text('Customer'),
            ),
          ],
        );
      },
    );

    if (role != null) {
      setState(() {
        selectedRole = role;
      });
    }
  }

  Future<void> registerWithGoogle(BuildContext context) async {
    try {
      await showRoleSelectionDialog(context);

      if (selectedRole == null || selectedRole!.isEmpty) {
        showErrorMessage(context, 'Role cannot be empty');
        return;
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      String userEmail = userCredential.user!.email!;
      String userRole = selectedRole ?? 'Customer';

      // Simpan data pengguna ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'userUUID': userCredential.user!.uid,
        'email': userEmail,
        'password': passwordController.text,
        'role': userRole,
      });

      redirectToHome(context, userEmail, userRole);
    } catch (e) {
      showErrorMessage(context, 'Registration with Google failed: $e');
      print('Registration with Google failed: $e');
      print('Error details: $e');
    }
  }

  void redirectToHome(BuildContext context, String userEmail, String userRole) {
    switch (userRole) {
      case 'Admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(userEmail: userEmail),
          ),
        );
        break;
      case 'Customer':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHomePage(userEmail: userEmail),
          ),
        );
        break;
      default:
        // Handle role yang tidak diketahui, misalnya dengan kembali ke halaman login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password cannot be empty';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    // Check if password contains at least one letter and one digit
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                      return 'Password must contain at least one letter and one digit';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Role'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Role cannot be empty';
                    }
                    return null;
                  },
                  items: roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    registerUser(context);
                  },
                  child: Text('Register'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    registerWithGoogle(context);
                  },
                  child: Text('Register with Google'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    navigateToLoginPage(context);
                  },
                  child: Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void navigateToLoginPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }
}
