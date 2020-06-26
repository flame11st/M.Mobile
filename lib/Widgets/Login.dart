import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'MState.dart';

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginState();
  }
}

class LoginState extends State<Login> {
    @override
        Widget build(BuildContext context) {
            final provider = Provider.of<MState>(context);

            return Scaffold (
                body: Center(
                    child: Text("Not Authorized"),
                ),
                floatingActionButton: FloatingActionButton(
                    onPressed: () {
                        provider.setIsUserAuthorized(!provider.isUserAuthorized);
                    })
        );
    }

}