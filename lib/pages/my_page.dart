import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // UI 상태
  bool _loading = true;
  bool _editingNick = false;

  // 사용자 정보
  String _email = '';
  String _nickname = 'Nickname';

  // 닉네임 입력 컨트롤러
  final _nickCtrl = TextEditingController();

  // 프로필 이미지 (모바일: 파일경로 / 웹: bytes)
  File? _profileFile;
  Uint8List? _profileBytes;

  static const _keyColor = Color(0xFFB3C39C);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final nickKey = 'nickname_$email';
    final imgKey = 'profile_img_$email'; // 웹: base64 저장, 모바일: 파일경로 저장

    final nick = prefs.getString(nickKey) ??
        (email.contains('@') ? email.split('@').first : 'Nickname');

    // 이미지 로드
    File? file;
    Uint8List? bytes;
    final saved = prefs.getString(imgKey);
    if (saved != null && saved.isNotEmpty) {
      if (kIsWeb) {
        try {
          bytes = base64Decode(saved);
        } catch (_) {}
      } else {
        final f = File(saved);
        if (await f.exists()) file = f;
      }
    }

    setState(() {
      _email = email;
      _nickname = nick;
      _nickCtrl.text = nick;
      _profileFile = file;
      _profileBytes = bytes;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  // 닉네임 유효성 (2~16자)
  bool get _nickValid {
    final s = _nickCtrl.text.trim();
    return s.isNotEmpty && s.length >= 2 && s.length <= 16;
  }

  // 변경 여부
  bool get _nickChanged => _nickCtrl.text.trim() != _nickname;

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    final imgKey = 'profile_img_$_email';

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      await prefs.setString(imgKey, base64Encode(bytes));
      setState(() => _profileBytes = bytes);
    } else {
      await prefs.setString(imgKey, picked.path);
      setState(() => _profileFile = File(picked.path));
    }
  }

  ImageProvider? _imageProvider() {
    if (kIsWeb) {
      if (_profileBytes != null) return MemoryImage(_profileBytes!);
    } else {
      if (_profileFile != null) return FileImage(_profileFile!);
    }
    return null;
  }

  Future<void> _saveNickname() async {
    if (!_nickValid) return;
    final newNick = _nickCtrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname_$_email', newNick);
    setState(() {
      _nickname = newNick;
      _editingNick = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('닉네임이 저장되었습니다.')));
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // 취소
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(height: 8),
                // 로그아웃
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('isLoggedIn');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white70,
      body: Column(
        children: [
          // 상단 바
          Container(
            height: 70,
            color: const Color(0xDDB3C39C),
            child:
            Center(child: Image.asset('assets/logos/logo_horizontal.png', height: 40)),
          ),
          const SizedBox(height: 36),

          // 프로필 사진 + 카메라 아이콘
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 90,
                    backgroundColor: Colors.white,
                    backgroundImage: _imageProvider(),
                    child: _imageProvider() == null
                        ? Icon(Icons.person, size: 64, color: Colors.grey[400])
                        : null,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: InkWell(
                    onTap: _pickProfileImage,
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      backgroundColor: _keyColor,
                      radius: 20,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 닉네임 수정 UI (입력 + 체크/취소 아이콘)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _editingNick
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _nickCtrl,
                    textAlign: TextAlign.center,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '닉네임 (2~16자)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  tooltip: '저장',
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed:
                  (_nickValid && _nickChanged) ? _saveNickname : null,
                ),
                IconButton(
                  tooltip: '취소',
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _nickCtrl.text = _nickname;
                      _editingNick = false;
                    });
                  },
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nickname,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => setState(() => _editingNick = true),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(_email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          // 로그아웃 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: _confirmLogout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.grey[300],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('로그아웃'),
            ),
          ),
        ],
      ),
    );
  }
}
