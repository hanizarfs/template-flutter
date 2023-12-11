import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stayin1/screens/customer/home.dart';
import 'package:stayin1/screens/admin/home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stayin1/screens/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> loginUser(BuildContext context) async {
    try {
      if (_formKey.currentState!.validate()) {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String userEmail = userCredential.user!.email!;
        String userRole = await getUserRole(userCredential.user!.uid);

        redirectToHome(context, userEmail, userRole);
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
        ),
      );

      print('Login failed: $e');
      // Display more information about the error in the console
      print('Error details: $e');
    }
  }

  Future<String> getUserRole(String userUID) async {
    // Implementasi untuk mendapatkan peran (role) pengguna dari Firestore
    // Misalnya, dapatkan peran dari koleksi 'users' berdasarkan UID
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userUID).get();

    // Pastikan bahwa dokumen ditemukan dan memiliki data peran
    if (userDoc.exists &&
        userDoc.data() != null &&
        userDoc.data()!['role'] != null) {
      return userDoc.data()!['role'];
    }

    // Jika tidak ditemukan, kembalikan nilai default atau sesuaikan dengan kebutuhan aplikasi Anda
    return 'Customer';
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

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
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
      String userRole = await getUserRole(userCredential.user!.uid);

      if (userRole == 'Customer') {
        // Jika role Customer, periksa apakah akun sudah terdaftar di Firestore
        bool isUserRegistered =
            await checkIfUserRegistered(userCredential.user!.uid);

        if (!isUserRegistered) {
          // Jika tidak terdaftar, tampilkan pesan atau dialog
          showRegistrationDialog(context);
          return;
        }
      }

      redirectToHome(context, userEmail, userRole);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login with Google failed: $e'),
        ),
      );

      print('Login with Google failed: $e');
      // Display more information about the error in the console
      print('Error details: $e');
    }
  }

  Future<bool> checkIfUserRegistered(String userUID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userUID)
          .get();

      return userDoc.exists;
    } catch (e) {
      print('Error checking if user is registered: $e');
      return false;
    }
  }

  void showRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Not Registered'),
          content: Text(
              'This account is not registered. Please create an account first.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Redirect to registration page or perform other actions
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
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
                    icon: Icon(Icons.visibility),
                    onPressed: () {
                      // Implementasi untuk menampilkan atau menyembunyikan password
                      // Sesuaikan dengan kebutuhan aplikasi Anda
                    },
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password cannot be empty';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  loginUser(context);
                },
                child: Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  loginWithGoogle(context);
                },
                child: Text('Login with Google'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Register()),
                  );
                },
                child: Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
