import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'broadcast_start_screen.dart'; // BroadcastStartScreen을 임포트
import 'broadcast_list_screen.dart'; // BroadcastStartScreen을 임포트
import 'register_screen.dart'; // RegisterScreen을 임포트

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://172.30.1.66:5001/login'), // Server URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Safely extract userId, handling the case where it might be missing or null
        final String? userId = data['userId'] as String?;

        if (userId != null) {
          print('Login successful: ${data['msg']}');
          await _saveSessionData(userId, _usernameController.text, _passwordController.text);
          _showWelcomeDialog(context, _usernameController.text, userId);
        } else {
          // Handle the case where userId is not present or is null
          print('Login failed: userId is missing or null');
          _showDialog(context, 'Login failed: userId is missing or null.');
        }
      } else {
        print('Login failed: ${response.body}');
        _showDialog(context, 'Login failed: ${response.body}');
      }
    } catch (e) {
      print('Connection failed: $e');
      _showDialog(context, 'Server connection failed.');
    }
  }

  Future<void> _saveSessionData(String userId, String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId); // userId 저장
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }

  void _showWelcomeDialog(BuildContext context, String username, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('환영합니다'),
          content: Text('$username님 환영합니다'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadcastListScreen(userId: userId), // BroadcastStartScreen으로 userId 전달
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('알림'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign In',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Become a makking_app member!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (bool? value) {},
                ),
                Text('Remember Me'),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 129, 139, 195),
                padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: Text('LOGIN'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          RegisterScreen()), // RegisterScreen으로 이동
                );
              },
              child: Text(
                'Become a member makking-app',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
