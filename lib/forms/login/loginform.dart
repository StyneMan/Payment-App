import 'dart:convert';

import 'package:airtimeslot_app/components/dashboard/dashboard.dart';
import 'package:airtimeslot_app/components/text_components.dart';
import 'package:airtimeslot_app/helper/constants/constants.dart';
import 'package:airtimeslot_app/helper/preferences/preference_manager.dart';
import 'package:airtimeslot_app/helper/service/api_service.dart';
import 'package:airtimeslot_app/helper/state/state_controller.dart';
import 'package:airtimeslot_app/model/error/error.dart';
import 'package:airtimeslot_app/model/error/validation_error.dart';
import 'package:airtimeslot_app/screens/account/verify_account.dart';
import 'package:airtimeslot_app/screens/auth/forgotpass/forgotPass.dart';
import 'package:airtimeslot_app/screens/wallet/set_wallet_pin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:page_transition/page_transition.dart';

class LoginForm extends StatefulWidget {
  final PreferenceManager manager;
  LoginForm({Key? key, required this.manager}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<StateController>();

  _togglePass() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  _login() async {
    Map _payload = {
      "email": _emailController.text,
      "password": _passwordController.text
    };
    //Perform Login here
    _controller.setLoading(true);
    try {
      final response = await APIService().login(_payload);
      debugPrint("LOGIN RESP:: ${response.body}");

      if (response.statusCode == 200) {
        Map<String, dynamic> loginMap = jsonDecode(response.body);
        // LoginModel login = LoginModel.fromJson(loginMap);
        // debugPrint('TESTTERRE:::: ${loginMap['data']['token']}');

        _controller.setAccessToken('${loginMap['data']['token']}');
        widget.manager.saveAccessToken('${loginMap['data']['token']}');

        final _toks = "${loginMap['data']['token']}";

        // UserModel? model = login.data?.user;
        // _controller.setUserData('${login.data?.user}');

        if (loginMap['data']['user']['is_account_verified']) {
          //Account has been verified. Now check if wallet pin is set.
          if (loginMap['data']['user']['is_wallet_pin']) {
            //Wallet pin has been set, go to dashboard from here.
            //Save user data and preferences
            String userData = jsonEncode(loginMap['data']['user']);
            widget.manager.setUserData(userData);

            // _controller.setUserData('${loginMap['data']['user']}');

            await APIService().fetchTransactions(_toks);

            widget.manager.setIsLoggedIn(true);
            _controller.setLoading(false);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(manager: widget.manager),
              ),
            );

           
          } else {
            //Set wallet PIN from here.
            _controller.setLoading(false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SetWalletPin(manager: widget.manager),
              ),
            );
          }
        } else {
          //Verify account from here...
          _controller.setLoading(false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyAccount(
                manager: widget.manager,
                token: '${loginMap['data']['token']}',
                email: _emailController.text,
              ),
            ),
          );
        }
      } else if (response.statusCode == 422) {
        _controller.setLoading(false);
        //Error occurred on login
        Map<String, dynamic> errorMap = jsonDecode(response.body);
        ValidationError error = ValidationError.fromJson(errorMap);
        Constants.toast("${error.errors?.email[0] ?? error.message}");
      } else {
        //Error occurred on login
        _controller.setLoading(false);
        Map<String, dynamic> errorMap = jsonDecode(response.body);
        ErrorResponse error = ErrorResponse.fromJson(errorMap);
        Constants.toast("${error.message}");
      }
    } catch (e) {
      _controller.setLoading(false);
      debugPrint("ERR::: $e");
      Constants.toast("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
              filled: false,
              labelText: 'Email',
              hintText: 'Email',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email or phone';
              }
              //if email
              // if (value.contains(RegExp(r'[a-z]'))) {
              //Email is entere now check if the email is valid
              if (!RegExp('^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }

              return null;
            },
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
          ),
          const SizedBox(
            height: 16.0,
          ),
          TextFormField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                gapPadding: 1.0,
              ),
              filled: false,
              labelText: 'Password',
              hintText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => _togglePass(),
                icon: Icon(
                  _obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please type password';
              }
              return null;
            },
            obscureText: _obscureText,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
          ),
          const SizedBox(
            height: 1.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageTransition(
                      type: PageTransitionType.size,
                      alignment: Alignment.bottomCenter,
                      child: ForgotPassword(),
                    ),
                  );
                },
                child: TextPoppins(
                  text: "Forgot password?",
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16.0,
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _login();
                }
              },
              child: TextPoppins(
                text: "Sign in",
                fontSize: 14,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Constants.primaryColor,
                elevation: 0.2,
              ),
            ),
          )
        ],
      ),
    );
  }
}
