import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './header_mobile.dart';
import 'package:dotted_border/dotted_border.dart';

class MainPageMobile extends StatefulWidget {
  const MainPageMobile({super.key});

  @override
  State<MainPageMobile> createState() => _MainPageMobileState();
}

class _MainPageMobileState extends State<MainPageMobile> {
  bool isTextMode = true;
  final TextEditingController _textController = TextEditingController();
  Uint8List? _imageBytes;
  String resultText = "검사할 콘텐츠를 업로드하거나 입력해주세요.";

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _startCheck() {
    setState(() {
      if (isTextMode) {
        final text = _textController.text.trim();
        resultText = text.isEmpty
            ? "검사할 콘텐츠를 업로드하거나 입력해주세요."
            : "텍스트 검사가 완료되었습니다. (예시)";
      } else {
        resultText = _imageBytes == null
            ? "검사할 콘텐츠를 업로드하거나 입력해주세요."
            : "이미지 검사가 완료되었습니다. (예시)";
      }
    });
  }

  Widget _buildTabButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            isTextMode = true;
            resultText = "검사할 콘텐츠를 업로드하거나 입력해주세요.";
            _textController.clear();
            _imageBytes = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isTextMode ? const Color(0xFF6C4EFF) : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
            ),
            child: Text(
              "텍스트 검사",
              style: TextStyle(
                color: isTextMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            isTextMode = false;
            resultText = "검사할 콘텐츠를 업로드하거나 입력해주세요.";
            _textController.clear();
            _imageBytes = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: !isTextMode ? const Color(0xFF6C4EFF) : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Text(
              "이미지 검사",
              style: TextStyle(
                color: !isTextMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      maxLines: 8,
      decoration: InputDecoration(
        hintText: "검사할 텍스트를 입력하세요...",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF4A46C3), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    return DottedBorder(
      color: const Color(0xFF4A46C3),
      strokeWidth: 2,
      dashPattern: const [8, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 180,
          alignment: Alignment.center,
          child: _imageBytes != null
              ? Image.memory(_imageBytes!)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: Color(0xFF4A46C3),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "이미지를 업로드하거나 여기에 드래그하세요",
                      style: TextStyle(color: Color(0xFF4A46C3)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStartCheckButton() {
    return ElevatedButton(
      onPressed: _startCheck,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A46C3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      ),
      child: const Text(
        "검사 시작",
        style: TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 252, 252, 252),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResultBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAFF),
        border: Border.all(color: const Color(0xFF4A46C3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.search, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(child: Text(resultText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void handleMenuTap(String selected) {
      setState(() {
        _textController.clear();
        _imageBytes = null;
        resultText = '검사할 콘텐츠를 업로드하거나 입력해주세요.';
        isTextMode = (selected == '텍스트 분석');
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFE8FF),

      appBar: buildAppHeaderBar(context, onMenuTap: handleMenuTap),
      drawer: AppDrawer(onMenuTap: handleMenuTap),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildTabButtons(),
              const SizedBox(height: 24),
              isTextMode ? _buildTextInput() : _buildImageUploader(),
              const SizedBox(height: 20),
              _buildStartCheckButton(),
              const SizedBox(height: 32),
              _buildResultBox(),
            ],
          ),
        ),
      ),
    );
  }
}
