import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 마이페이지 화면 - 프로필 이미지, 닉네임 수정, 로그아웃
class MyPage extends StatefulWidget{
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isEditing = false; // 수정 모드 여부
  String _nickname = 'Nickname'; // 현재 닉네임
  String _email = 'email@example.com'; // 실제 저장된 이메일 불러올 변수
  TextEditingController _controller = TextEditingController(); // 닉네임 수정용 컨트롤러

  File? _profileImage; // 선택된 프로필 이미지 파일

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nickname = prefs.getString('userId') ?? 'Nickname';
      _email = prefs.getString('userId') ?? 'email@example.com';
    });
  }

  Future<void> _pickProfileImage() async {
    //갤러리에서 프로필 이미지 가져오기
    final picker = ImagePicker();
    final picked_pic = await picker.pickImage(source: ImageSource.gallery);

    if (picked_pic != null) {
      setState(() {
        _profileImage = File(picked_pic.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          Container(
            height:70,
            color: Color(0xDDB2C29B),
            child: Center(
              child: Image.asset(
                'assets/logos/logo_horizontal.png',
                height: 40,
              ),
            ),
          ),
          SizedBox(height: 100),

          // 프로필 사진 영역
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: _isEditing ? Colors.grey[700] : Colors.white54,
                  backgroundImage: _profileImage != null ? FileImage(
                      _profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey[500])
                      : null,
                ),
              ),
              if(_isEditing)
                GestureDetector(
                  onTap: _pickProfileImage, // 수정 모드일 때만 이미지 변경 가능
                  child: Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Icon(
                        Icons.camera_alt, color: Colors.white, size: 32),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),


          // 닉네임 수정/보기 상태
          _isEditing
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 140,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration.collapsed(hintText: '닉네임'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          )

              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _nickname,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () {
                  setState(() {
                    _controller.text = _nickname;
                    _isEditing = true;
                  });
                },
              )
            ],
          ),
          SizedBox(height: 8),
          Text(_email, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),

          // 완료 버튼(닉네임 수정 후 저장)
          _isEditing
              ? TextButton(
            onPressed: () {
              setState(() {
                _nickname = _controller.text;
                _isEditing = false;
              });
            },
            child: Text(
                '완료', style: TextStyle(decoration: TextDecoration.underline)),
          )

          // 로그아웃 버튼 - 수정 모드 아닐 때만 표시
              : TextButton(
            onPressed: () async {
              // SharedPreference를 통해 로그인 상태 초기화
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
            },
            child: Text('로그아웃', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}