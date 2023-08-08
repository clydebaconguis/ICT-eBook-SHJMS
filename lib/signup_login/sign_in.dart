import 'dart:convert';
import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:ebooks/widget/bezier_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

const snackBar2 = SnackBar(
  content: Text('Fill all fields!'),
);

class _SignInState extends State<SignIn> {
  var loggedIn = false;
  bool isButtonEnabled = true;
  bool isVisible = false;
  // late bool _isLoading = false;
  TextEditingController textController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  _navigateToBooks() {
    if (mounted) {
      EasyLoading.showSuccess('Successfully loggedin!');
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MyNav(),
          ),
          (Route<dynamic> route) => false);
    }
  }

  _login() async {
    EasyLoading.show(status: 'loading...');
    var data = {
      'email': emailController.text,
      'password': textController.text,
    };

    try {
      var res = await CallApi().login(data, 'studentlogin');
      var body = {};
      if (res != null) {
        body = json.decode(res.body);
        // print(body);
      }

      if (body['success']) {
        SharedPreferences localStorage = await SharedPreferences.getInstance();
        localStorage.setString('token', body['user']['name']);
        localStorage.setString('grade', body['grade']);
        localStorage.setString('user', json.encode(body['user']));
        _navigateToBooks();
      } else {
        EasyLoading.showError('Failed to Login');
      }
    } catch (e) {
      // print('Error during login: $e');
      EasyLoading.showError('An error occurred during login');
    } finally {
      EasyLoading.dismiss();
    }
    setState(() {
      isButtonEnabled = true;
    });
  }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
          text: 'ICT',
          style: GoogleFonts.prompt(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(141, 31, 31, 1),
          ),
          children: [
            TextSpan(
              text: ' e',
              style: GoogleFonts.prompt(
                color: const Color.fromRGBO(242, 167, 0, 1),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'Book',
              style: GoogleFonts.prompt(
                color: const Color.fromRGBO(242, 167, 0, 1),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
    );
  }

  Widget _entryField(String title, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(
            height: 10,
          ),
          // TextField(
          //   controller: title == "Email" ? emailController : textController,
          //   obscureText: isPassword,
          //   decoration: const InputDecoration(
          //       border: InputBorder.none,
          //       fillColor: Color(0xfff3f3f4),
          //       filled: true),
          // ),
          Stack(
            children: [
              TextField(
                controller: title == "Email" ? emailController : textController,
                obscureText: title == "Password" ? isVisible : false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  fillColor: Color(0xfff3f3f4),
                  filled: true,
                ),
              ),
              if (title == "Password")
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        isVisible = !isVisible;
                      });
                    },
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        _entryField("Email"),
        _entryField("Password", isPassword: true),
      ],
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: isButtonEnabled
          ? () {
              if (textController.text.isEmpty || emailController.text.isEmpty) {
                EasyLoading.showToast(
                  'Fill all fields!',
                  toastPosition: EasyLoadingToastPosition.bottom,
                );
              } else {
                setState(() {
                  isButtonEnabled = false;
                });
                _login();
              }
            }
          : null,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(2, 4),
                blurRadius: 5,
                spreadRadius: 2)
          ],
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: isButtonEnabled
                ? [
                    const Color.fromRGBO(141, 31, 31, 1),
                    const Color.fromRGBO(141, 31, 31, 1),
                  ]
                : [Colors.grey, Colors.grey],
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  // Widget _createAccountLabel() {
  //   return InkWell(
  //     onTap: () {
  //       // Navigator.push(
  //       //     context, MaterialPageRoute(builder: (context) => SignUpPage()));
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(vertical: 20),
  //       padding: const EdgeInsets.all(15),
  //       alignment: Alignment.bottomCenter,
  //       child: const Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: <Widget>[
  //           Text(
  //             'Don\'t have an account ?',
  //             style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  //           ),
  //           SizedBox(
  //             width: 10,
  //           ),
  //           Text(
  //             'Register',
  //             style: TextStyle(
  //                 color: Color.fromARGB(179, 207, 46, 137),
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w600),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back by returning false
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          height: height,
          // padding: const EdgeInsets.only(left: 30, right: 30),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -height * .15,
                right: -MediaQuery.of(context).size.width * .4,
                child: const BezierContainer(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: height * 0.1),
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.transparent,
                        child: Image.asset("img/liceo-logo.png"),
                      ),
                      _title(),
                      const SizedBox(
                        height: 50,
                      ),
                      _emailPasswordWidget(),
                      const SizedBox(
                        height: 20,
                      ),
                      _submitButton(),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          child: const Text('Forgot Password ?',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          onTap: () {
                            EasyLoading.showInfo(
                                'Please inform the school authority or your teacher for further assistance.');
                          },
                        ),
                      ),
                      // _createAccountLabel(),
                    ],
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

class TextInput extends StatefulWidget {
  final String textString;
  final TextEditingController textController;
  final String hint;
  final bool obscureText;

  const TextInput({
    Key? key,
    required this.textString,
    required this.textController,
    required this.hint,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  bool _obscureText = true;
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Color(0xFF000000)),
      cursorColor: const Color(0xFF9b9b9b),
      controller: widget.textController,
      keyboardType: TextInputType.text,
      obscureText: widget.textString == "Password" ? _obscureText : false,
      focusNode: _focusNode,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isFocused ? Colors.blue : Colors.grey,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 15, horizontal: 16), // Adjust the vertical padding here
        hintText: widget.textString,
        hintStyle: const TextStyle(
          color: Color(0xFF9b9b9b),
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        suffixIcon: widget.textString == "Password"
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
