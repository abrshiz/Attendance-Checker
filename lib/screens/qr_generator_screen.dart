import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import '../models/student.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String classId;
  final Function(Student) onStudentGenerated;

  const QRGeneratorScreen({
    super.key,
    required this.classId,
    required this.onStudentGenerated,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  String _qrData = "";
  bool _isSaving = false;

  void _generateData() {
    if (_idController.text.isNotEmpty && _nameController.text.isNotEmpty) {
      Map<String, String> dataMap = {
        "id": _idController.text,
        "name": _nameController.text,
        "timestamp": DateTime.now().toIso8601String(),
      };
      setState(() {
        _qrData = jsonEncode(dataMap);
      });
    } else {
      setState(() {
        _qrData = "";
      });
    }
  }

  Future<bool> _requestPermission() async {
    if (await Permission.photos.isGranted) {
      return true;
    }
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<void> _saveQrToGallery() async {
    setState(() => _isSaving = true);

    try {
      bool hasPermission = await _requestPermission();
      if (!hasPermission) {
        _showMessage("Storage permission denied", Colors.red);
        return;
      }

      final RenderObject? renderObject =
          _qrKey.currentContext?.findRenderObject();

      if (renderObject == null) {
        _showMessage("QR widget not found", Colors.red);
        return;
      }

      if (renderObject is! RenderRepaintBoundary) {
        _showMessage("Widget is not properly wrapped", Colors.red);
        return;
      }

      final boundary = renderObject;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showMessage("Failed to generate image", Colors.red);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final fileName =
          "qr_${_idController.text}_${DateTime.now().millisecondsSinceEpoch}.png";

      await Gal.putImageBytes(pngBytes, name: fileName);
      _showMessage("QR saved to gallery", Colors.green);
    } catch (e) {
      _showMessage("Error: $e", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _markAttendance() {
    if (_idController.text.isNotEmpty && _nameController.text.isNotEmpty) {
      final student = Student(
        id: _idController.text,
        name: _nameController.text,
        timestamp: DateTime.now(),
        status: AttendanceStatus.present,
      );
      widget.onStudentGenerated(student);
      _showMessage("${student.name} marked present!", Colors.green);

      _idController.clear();
      _nameController.clear();
      setState(() {
        _qrData = "";
      });
    } else {
      _showMessage("Please enter student details", Colors.orange);
    }
  }

  void _showMessage(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: "Student ID",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    onChanged: (_) => _generateData(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Student Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (_) => _generateData(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_qrData.isNotEmpty) ...[
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: _qrData,
                    size: 250,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.blue,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQrToGallery,
                    icon: const Icon(Icons.download),
                    label: Text(_isSaving ? "Saving..." : "Save QR"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markAttendance,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Mark Present"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade50,
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Enter student details to generate QR code",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
