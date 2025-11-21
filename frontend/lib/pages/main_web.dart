import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import './header_web.dart';

class MainPageWeb extends StatefulWidget {
  const MainPageWeb({super.key});

  @override
  State<MainPageWeb> createState() => _MainPageWebState();
}

class _MainPageWebState extends State<MainPageWeb> {
  final TextEditingController _textController = TextEditingController();
  Uint8List? _imageBytes;
  String resultText = "789798";

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
      if (_imageBytes != null || _textController.text.trim().isNotEmpty) {
        resultText = "검사가 완료되었습니다. (예시 결과)";
      } else {
        resultText = "검사한 콘텐츠를 업로드하거나 입력해주세요.";
      }
    });
  }

  Widget _buildInputPanel() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "콘텐츠 검사하기",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            DottedBorder( // 오류
              // color: const Color(0xFF4A46C3),
              // strokeWidth: 2,
              // dashPattern: const [8, 4],
              // borderType: BorderType.RRect,
              // radius: const Radius.circular(12),
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 250,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: _imageBytes != null
                      ? Stack(
                          children: [
                            Center(
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageBytes = null;
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image,
                              color: Color(0xFF4A46C3),
                              size: 36,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '이미지를 업로드하거나 여기에 드래그하세요',
                              style: TextStyle(
                                color: Color(0xFF4A46C3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            //const Text("또는"),
            const SizedBox(height: 12),
            Container(
              height: 250,
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "검사할 텍스트를 직접 입력하세요...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A46C3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              child: const Text(
                "검사 시작",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "검사 결과",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.search_rounded,
              size: 60,
              color: Color(0xFF4A46C3),
            ),
            const SizedBox(height: 12),
            Text(resultText, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE8FF),
      appBar: buildWebHeaderBar(context),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return Container(
              width: isWide
                  ? constraints.maxWidth * 0.9
                  : constraints.maxWidth * 0.95,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputPanel(),
                  const SizedBox(width: 24, height: 24),
                  _buildResultPanel(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
