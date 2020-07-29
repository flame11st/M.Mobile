import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/ServiceAgent.dart';
import 'Providers/UserState.dart';

class Login extends StatefulWidget {
    @override
    State<StatefulWidget> createState() {
        return LoginState();
    }
}

class LoginState extends State<Login> {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final serviceAgent = ServiceAgent();
    final storage = new FlutterSecureStorage();

    login(UserState state) async {
        var response = await serviceAgent.login(emailController.text, passwordController.text);

        if (response.statusCode == 200) {
            var responseJson = json.decode(response.body);
            var accessToken = responseJson['access_token'];
            var refreshToken = responseJson['refresh_token'];
            var userId = responseJson['userId'];
            var userName = responseJson['username'];

            state.setInitialUserData(accessToken, refreshToken, userId, userName);
        } else {
        }
    }

    @override
        Widget build(BuildContext context) {
            final provider = Provider.of<UserState>(context);

            final emailField = TextField(
                controller: emailController,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Email",
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
            );

            final passwordField = TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Password",
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
            );

            final loginButton = Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Color(0xff01A0C7),
                child: MaterialButton(
                    minWidth: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    onPressed: () {
                        login(provider);
                    },
                    child: Text("Login",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                ),
            ));

            return Scaffold (
                body: Center(
                    child: Container(
                        child: Column(
                            children: <Widget>[
                                SizedBox(height: 45.0),
                                emailField,
                                SizedBox(height: 25.0),
                                passwordField,
                                SizedBox(
                                    height: 35.0,
                                ),
                                loginButton,
                                SizedBox(
                                    height: 15.0,
                                )
                            ],
                        )
                    ),
                ),
        );
    }

}