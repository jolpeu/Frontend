import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 마이페이지 화면 - 프로필 이미지, 닉네임 수정, 로그아웃
class MyPage extends StatefulWidget{
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage>{
  bool _isEditing = false;        // 수정 모드 여부
  String _nickname = 'Nickname';  // 현재 닉네임
  TextEditingController _controller = TextEditingController();  // 닉네임 수정용 컨트롤러

  File? _profileImage;    // 선택된 프로필 이미지 파일

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
        children: [
          Container(height: 60, color: Color(0xDDB3C39C)),
          SizedBox(height: 40),

          // 프로필 사진 영역
          GestureDetector(
            onTap: _isEditing ? _pickProfileImage : null,   // 수정 모드일 때만 이미지 변경 가능
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ?Icon(Icons.person, size: 40, color: Colors.grey[700])
                  :null,
            ),
          ),
          SizedBox(height: 20),


          // 닉네임 수정/보기 상태
          _isEditing
          ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: (){
                  setState(() {
                    _isEditing = false;
                  });
                },
              ),
            ],
          )
          :Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _nickname,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                  icon: Icon(Icons.edit, size: 18),
                  onPressed: (){
                    setState(() {
                      _controller.text = _nickname;
                      _isEditing = true;
                    });
                  }
                ),
            ],
          ),
          SizedBox(height: 6),
          Text("email@gmail.com", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),

          // 완료 버튼(닉네임 수정 후 저장)
          if(_isEditing)
            TextButton(
                onPressed: (){
                  setState(() {
                    _nickname = _controller.text;
                    _isEditing = false;
                  });
                },
                child: Text('완료'),
            ),
          // 로그아웃 버튼 - 수정 모드 아닐 때만 표시
          if(!_isEditing)
            TextButton(
                onPressed: () async {
                  // SharedPreference를 통해 로그인 상태 초기화
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  Navigator.pushReplacementNamed(context, '/login');  // 로그인 화면으로 이동
                },
                child: Text('로그아웃', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    );
  }

  Future<void> _pickProfileImage() async {
    //갤러리에서 프로필 이미지 가져오기
    final picker = ImagePicker();
    final picked_pic = await picker.pickImage(source: ImageSource.gallery);

    if(picked_pic != null){
      setState(() {
        _profileImage = File(picked_pic.path);
      });
    }
  }
}