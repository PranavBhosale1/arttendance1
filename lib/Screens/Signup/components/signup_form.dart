import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Login/login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _prnController = TextEditingController();
  String? _selectedYear; // Variable to store the selected year
  final List<String> _yearOptions = ['FE', 'SE', 'TE', 'BE']; // Example year options
  String _errorMessage = '';

  Future<void> _signUpWithEmailAndPassword() async {
    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Store user data in Firestore (optional)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text,
        'email': _emailController.text,
        'prn': _prnController.text,
        'year': _selectedYear,
        'credits': 0,
        'role': 'Student',
      });

      // Registration successful, show a Snackbar and navigate to LoginScreen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Please log in.'),
        ),
      );

      // Delay the navigation slightly to allow the Snackbar to be displayed
      await Future.delayed(Duration(seconds: 2)); // Adjust the delay as needed

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during registration.';
      });
    }
  }

@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  _nameController.dispose();
  _prnController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          cursorColor: kPrimaryColor,
          decoration: InputDecoration(
            hintText: "Your email",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.email),
            ),
          ),
          validator: (value) {
            // Email validation logic (check if empty or invalid format)
            if (value == null || value.isEmpty) {
              return 'Please enter your email.';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email.';
            }
            return null; // Return null if the email is valid
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: defaultPadding),
          child: TextFormField(
            textInputAction: TextInputAction.done,
            obscureText: true,
            cursorColor: kPrimaryColor,
            controller: _passwordController, // Use controller
            decoration: InputDecoration(
              hintText: "Your password",
              prefixIcon: Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.lock),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password.';
              }
              return null;
            },
          ),
        ),
        // Name Field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "Your Name",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.person),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name.';
            }
            return null;
          },
        ),

        // PRN Field
        TextFormField(
          controller: _prnController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Your PRN",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.pin), // You can use a different icon if you prefer
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your PRN.';
            }
            return null;
          },
        ),

        // Year Dropdown
        DropdownButtonFormField<String>(
          value: _selectedYear,
          items: _yearOptions.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(year),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedYear = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Select Year",
            prefixIcon: Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Icon(Icons.school),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your year.';
            }
            return null;
          },
        ),

        const SizedBox(height: defaultPadding / 2),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _signUpWithEmailAndPassword();
            }
          },
          child: Text("Sign Up".toUpperCase()),
        ),

        // Error Message Display
        if (_errorMessage.isNotEmpty) ...[
          SizedBox(height: defaultPadding),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.red),
          ),
        ],

          // Display error message (if any)
          if (_errorMessage.isNotEmpty) ...[
            SizedBox(height: defaultPadding),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ],

          AlreadyHaveAnAccountCheck(

            login: false,

            press: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) {

                    return const LoginScreen();

                  },

                ),

              );

            },

          ),
        ],
      ),
    );
  }
}