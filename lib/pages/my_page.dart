import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class MyPage extends StatefulWidget{
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage>{
  bool _isEditing = false;
  String _nickname = 'Nickname';
  TextEditingController _controller = TextEditingController();

  File? _profileImage;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
        children: [
          SizedBox(height: 40),

          // 프로필 사진
          GestureDetector(
            onTap: _isEditing ? _pickProfileImage : null,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ?Icon(Icons.person, size: 40, color: Colors.grey[700])
                  :null,
            ),
          ),
          SizedBox(height: 20),


          // 닉네임
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
          if(!_isEditing)
            TextButton(
                onPressed: () async {
                  // 로그아웃
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  Navigator.pushReplacementNamed(context, '/login');
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