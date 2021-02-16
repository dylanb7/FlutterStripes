import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stripes_app/Models/Routes.dart';
import 'package:stripes_app/Utility/rgbToMaterial.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  AssetImage logo = AssetImage("assets/StripesLogo.png");

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double sideEdge = size.width * 0.15;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      body: Column(
        children: [
          Padding(
              padding: EdgeInsets.only(
                  top: size.height * 0.2,
                  left: size.width * 0.1,
                  right: size.width * 0.1),
              child: Center(
                  child: Image(
                image: logo,
              ))),
          Padding(
            padding: EdgeInsets.only(
                left: sideEdge, right: sideEdge, top: size.height * 0.12),
            child: _button("Sign up with access code", showSignUp, context),
          ),
          Padding(
            padding: EdgeInsets.only(left: sideEdge, right: sideEdge, top: 20),
            child: RaisedButton(
              elevation: 0,
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                  Text(
                    "Login",
                    style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                ],
              )),
              color: Colors.transparent,
              onPressed: showLogin,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          Expanded(
            child: Align(
              child: ClipPath(
                child: Container(
                  color: Theme.of(context).primaryColor,
                  height: 300,
                ),
                clipper: BottomWaveClipper(),
              ),
              alignment: Alignment.bottomCenter,
            ),
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    );
  }

  showBottomSheet(Widget content, String title) {
    _scaffoldKey.currentState.showBottomSheet((context) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          border: Border.all(color: Theme.of(context).primaryColor, width: 4.0),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0)),
        ),
        child: Column(children: <Widget>[
          Padding(
              padding: EdgeInsets.only(top: 15),
              child: Stack(
                children: [
                  Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                          height: 50,
                          width: 50,
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.close,
                              size: 30.0,
                              color: Colors.black54,
                            ),
                          ))),
                  Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            style:
                                TextStyle(fontSize: 30, color: Colors.black54),
                          ))),
                ],
              )),
          SingleChildScrollView(
            child: content,
          )
        ]),
        height: MediaQuery.of(context).size.height / 1.1,
        width: MediaQuery.of(context).size.width,
      );
    },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))));
  }

  showLogin() {
    showBottomSheet(LoginPage(_scaffoldKey), "Login");
  }

  showSignUp() {
    showBottomSheet(SignUp(_scaffoldKey), "Sign Up");
  }
}

class LoginPage extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey;

  LoginPage(this._scaffoldKey);

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();

  String emailError = "";

  final TextEditingController passwordController = TextEditingController();

  String passwordError = "";

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return isLoading
        ? Center(
            child: SizedBox(
                width: 100, height: 100, child: CircularProgressIndicator()))
        : Column(children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: _input(Icon(Icons.email), "Email", emailController,
                    false, false, emailError, context)),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: _input(Icon(Icons.lock), "Password", passwordController,
                    true, false, passwordError, context)),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.2),
                child: _button("Login", login, context)),
            Padding(
              padding: EdgeInsets.only(
                  top: 20, left: size.width * 0.2, right: size.width * 0.2),
              child: _button("Reset password", resetPassword, context),
            )
          ]);
  }

  login() async {
    setState(() {
      isLoading = true;
    });
    final String email = emailController.text;
    final String password = passwordController.text;
    if (email.isEmpty) {
      setState(() {
        isLoading = false;
        emailError = "Empty Field";
      });
    } else if (password.isEmpty) {
      setState(() {
        isLoading = false;
        passwordError = "Empty Field";
      });
    } else {
      emailError = "";
      passwordError = "";
      final FirebaseAuth auth = FirebaseAuth.instance;
      try {
        User user = (await auth.signInWithEmailAndPassword(
                email: email, password: password))
            .user;
        if (user.emailVerified) {
          final String uid = user.uid;
          final FirebaseFirestore store = FirebaseFirestore.instance;
          try {
            await store.collection("UserData").doc(uid).get();
          } catch (e) {
            await store.collection("UserData").doc(uid).set({"email": email});
          }
          Navigator.pushReplacementNamed(context, Routes.dashboard);
        } else {
          Navigator.of(context).pop();
          showSnack("Email not yet verified", context);
        }
      } on FirebaseAuthException catch (err) {
        setState(() {
          isLoading = false;
          passwordController.clear();
          showSnack(err.toString().split("]").last, context);
        });
      } on FirebaseException catch (err) {
        setState(() {
          isLoading = false;
          passwordController.clear();
          showSnack(err.toString().split("]").last, context);
        });
      }
    }
  }

  resetPassword() {
    setState(() {
      isLoading = true;
    });
    final String email = emailController.text;
    if (email.isEmpty) {
      setState(() {
        isLoading = false;
        emailError = "Empty Field";
      });
    } else {
      final FirebaseAuth auth = FirebaseAuth.instance;
      auth
          .sendPasswordResetEmail(email: emailController.text)
          .catchError((err) {
        setState(() {
          showSnack(err.toString().split("]").last, context);
          isLoading = false;
        });
      }).then((res) {
        setState(() {
          showSnack("Password reset email sent to $email", context);
          isLoading = false;
        });
      });
    }
  }
}

class SignUp extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey;

  SignUp(this._scaffoldKey);

  @override
  State<StatefulWidget> createState() {
    return _SignUpState();
  }
}

class _SignUpState extends State<SignUp> {
  final store = FirebaseFirestore.instance;

  bool hasCode = false;

  bool isLoading = false;

  DocumentReference reference;

  final TextEditingController codeController = TextEditingController();

  String codeError = "";

  final TextEditingController emailController = TextEditingController();

  String emailError = "";

  final TextEditingController passwordController = TextEditingController();

  String passwordError = "";

  final TextEditingController passwordConfController = TextEditingController();

  String passwordConfError = "";

  @override
  Widget build(BuildContext context) {
    double sideSize = MediaQuery.of(context).size.width * 0.2;
    return isLoading
        ? Center(
            child: SizedBox(
                width: 100, height: 100, child: CircularProgressIndicator()))
        : hasCode
            ? Column(
                children: [
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: _input(Icon(Icons.email), "Email", emailController,
                          false, false, emailError, context)),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: _input(
                          Icon(Icons.lock),
                          "Password",
                          passwordController,
                          true,
                          false,
                          passwordError,
                          context)),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: _input(
                          Icon(Icons.lock),
                          "Confirm Password",
                          passwordConfController,
                          true,
                          false,
                          passwordConfError,
                          context)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: sideSize), child: _button("Sign Up", signUp, context))
                ],
              )
            : Column(
                children: [
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 25),
                      child: _input(Icon(Icons.sort), "Access Code",
                          codeController, false, true, codeError, context)),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideSize),
                      child: _button("Verify", verify, context))
                ],
              );
  }

  verify() async {
    setState(() {
      isLoading = true;
    });
    if (codeController.text.isNotEmpty) {
      int code = int.parse(codeController.text);
      store
          .collection("accessCodes")
          .where("value", isEqualTo: code)
          .get()
          .then((value) => {
                if (value.size == 0)
                  {
                    setState(() {
                      codeController.clear();
                      codeError = "Code does not exist";
                      isLoading = false;
                    })
                  }
                else
                  {
                    setState(() {
                      codeController.clear();
                      reference = value.docs.first.reference;
                      isLoading = false;
                      hasCode = true;
                    })
                  }
              });
    } else {
      setState(() {
        codeController.clear();
        codeError = "Empty Field";
        isLoading = false;
      });
    }
  }

  signUp() async {
    setState(() {
      isLoading = true;
    });
    final String pass = passwordController.text;
    final String passConf = passwordConfController.text;
    final String email = emailController.text;
    if (pass != passConf) {
      setState(() {
        passwordError = "Passwords don't match";
        passwordConfError = "Passwords don't match";
        isLoading = false;
      });
    } else {
      bool empty = false;
      if (email.isEmpty) {
        emailError = "Empty Field";
        empty = true;
      }
      if (passConf.isEmpty) {
        passwordConfError = "Empty Field";
        empty = true;
      }
      if (pass.isEmpty) {
        passwordError = "Empty Field";
        empty = true;
      }
      if (empty)
        setState(() {
          isLoading = false;
        });
      else {
        final String res = validatePass(pass);
        if (!RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(email))
          setState(() {
            emailError = "Invalid email";
            isLoading = false;
          });
        else if (res.isNotEmpty) {
          setState(() {
            emailError = "";
            passwordConfError = "";
            passwordError = res;
            isLoading = false;
          });
        } else {
          final FirebaseAuth _authInstance = FirebaseAuth.instance;
          UserCredential userCred;
          try {
            userCred = await _authInstance.createUserWithEmailAndPassword(
              email: email,
              password: pass,
            );
          } on FirebaseAuthException catch (err) {
            Navigator.of(context).pop();
            showSnack(err.toString().split("]").last, context);
          } catch (e) {
            setState(() {
              isLoading = false;
              showSnack("Unable to create user", context);
            });
          }
          if (userCred != null) {
            await userCred.user.sendEmailVerification();
            await _authInstance.signOut();
            store.runTransaction((transaction) async {
              transaction.update(reference, {"value": getRand()});
            });
            setState(() {
              isLoading = false;
              Navigator.of(context).pop();
              showSnack("Verification email sent to $email", context);
            });
          } else {
            setState(() {
              isLoading = false;
              showSnack("Unable to create user", context);
            });
          }
        }
      }
    }
  }
}

String validatePass(String value) {
  final int len = value.length;
  if (len < 8) return "Must be 8 characters";
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasSpecialCharacter =
      value.contains(new RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool hasDigits = false;
  int i = 0;
  String character = ' ';
  while (i < len) {
    character = value.substring(i, i + 1);
    if (double.tryParse(character) != null) hasDigits = true;
    if (character == character.toUpperCase()) hasUppercase = true;
    if (character == character.toLowerCase()) hasLowercase = true;

    i++;
  }
  if (!hasLowercase) return "Must have a lowercase";
  if (!hasUppercase) return "Must have an uppercase";
  if (!hasDigits) return "Must have a number";
  if (!hasSpecialCharacter) return "Must have a special character";
  return "";
}

int getRand() {
  int min = 10000000; //min and max values act as your 6 digit range
  int max = 99999999;
  var rand = new Random();
  return min + rand.nextInt(max - min);
}

Widget _button(String text, Function func, BuildContext context) {
  return Container(
      height: 50,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          blurRadius: 1.0,
          spreadRadius: 1.0,
          offset: Offset(0, 5), // changes position of shadow
        ),
      ], borderRadius: BorderRadius.circular(25)),
      child: RaisedButton(
        child: Ink(
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(25.0),
                gradient: LinearGradient(colors: [
                  from(Color.fromRGBO(54, 103, 229, 1)),
                  Theme.of(context).primaryColor
                ], begin: Alignment.centerLeft, end: Alignment.centerRight)),
            child: Center(
                child: Text(
              text,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ))),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        onPressed: func,
        padding: EdgeInsets.all(0),
      ));
}

showSnack(String message, BuildContext context) {
  Flushbar(
    messageText: Text(
      message,
      style: TextStyle(fontSize: 20, color: Colors.black54),
    ),
    backgroundColor: Colors.white70,
    duration: Duration(seconds: 4),
    flushbarStyle: FlushbarStyle.FLOATING,
    borderColor: Colors.black54,
    borderWidth: 2,
    borderRadius: 8,
    flushbarPosition: FlushbarPosition.BOTTOM,
    margin: EdgeInsets.all(8),
  )..show(context);
}

Widget _input(Icon icon, String hint, TextEditingController controller,
    bool obscure, bool numbersOnly, String errorText, BuildContext context) {
  return Container(
    padding: EdgeInsets.only(left: 20, right: 20),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
      inputFormatters:
          numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: TextStyle(
        fontSize: 20,
      ),
      decoration: InputDecoration(
          hintStyle: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black12),
          hintText: hint,
          errorText: errorText.isEmpty ? null : errorText,
          errorStyle: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 3,
            ),
          ),
          prefixIcon: Padding(
            child: IconTheme(
              data: IconThemeData(color: Theme.of(context).primaryColor),
              child: icon,
            ),
            padding: EdgeInsets.only(left: 30, right: 10),
          )),
    ),
  );
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width, 0.0);
    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.lineTo(0.0, size.height + 5);
    var secondControlPoint = Offset(size.width - (size.width / 6), size.height);
    var secondEndPoint = Offset(size.width, 0.0);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
