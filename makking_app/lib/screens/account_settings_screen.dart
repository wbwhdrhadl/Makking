import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String userId;
  final String serverIp;

  AccountSettingsScreen({required this.userId, required this.serverIp});

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String _username = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Guest';
      _profileImageUrl = prefs.getString('profileImageUrl'); // 프로필 이미지 URL 로드
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (_username == 'Guest') {
      _showWarningDialog(context);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              '로그아웃',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '로그아웃 하시겠습니까?',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('취소', style: TextStyle(color: Color(0xFF749BC2))),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('확인', style: TextStyle(color: Color(0xFF749BC2))),
                onPressed: () {
                  _logout(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 모든 세션 값 삭제
    Navigator.pop(context); // 로그아웃 후 뒤로가기
  }

  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            '경고',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '비회원으로 이용중입니다. 로그아웃할 수 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인', style: TextStyle(color: Color(0xFF749BC2))),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('계정 센터', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // 뒤로 가기 동작 추가
          },
        ),
      ),
      body: ListView(
        children: [
          // Profile Section
          ListTile(
            leading: CircleAvatar(
              radius: 40,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/img4.jpeg') as ImageProvider, // 프로필 이미지 경로
            ),
            title: Text(
              _username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '프로필',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: Icon(Icons.edit, color: Colors.grey),
            onTap: () {
              // 프로필 클릭 시 동작 추가
            },
          ),
          Divider(color: Colors.grey),
          // My Broadcasts Section
          ListTile(
            leading: Icon(Icons.tv, color: Color(0xFF749BC2)),
            title: Text(
              '내가 한 방송',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () {
              // 내가 한 방송 클릭 시 동작 추가
            },
          ),
          Divider(color: Colors.grey),
          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
            onTap: () => _confirmLogout(context),
          ),
          Divider(color: Colors.grey),
          // Account Deletion Section
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              '회원탈퇴',
              style: TextStyle(color: Colors.red),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
            onTap: () {
              // 회원탈퇴 클릭 시 동작 추가
            },
          ),
        ],
      ),
    );
  }
}
