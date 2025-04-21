import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class ImageUploadWidget extends StatefulWidget {
  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _selectedImage;
  String? _videoUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _videoUrl = null;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _uploadAndGenerateVideo() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload to Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'images/$fileName',
      );
      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Store URL in Firestore
      await FirebaseFirestore.instance.collection('images').add({
        'url': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send to Kling AI API
      String apiKey = 'your_kling_api_key'; // Replace with your actual API key
      Uri url = Uri.parse('https://api.segmind.com/v1/kling-image2video');

      Map<String, dynamic> body = {
        'image': downloadUrl,
        'prompt':
            'A serene beach at sunset with waves gently crashing and seagulls flying overhead.',
        'negative_prompt': 'No sudden movements, no fast zooms.',
        'cfg_scale': 0.5,
        'mode': 'pro',
        'duration': 5,
      };

      Map<String, String> headers = {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      };

      http.Response response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        String videoUrl =
            responseData['data']['task_result']['videos'][0]['url'];

        setState(() {
          _videoUrl = videoUrl;
          _videoController = VideoPlayerController.network(_videoUrl!)
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
            });
        });
      } else {
        print('Failed to generate video: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('3D Video Generator')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : Text('No image selected.'),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: Icon(Icons.photo),
              label: Text('Select from Gallery'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: Icon(Icons.camera_alt),
              label: Text('Capture Image'),
            ),
            SizedBox(height: 20),
            _selectedImage != null
                ? ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _uploadAndGenerateVideo(),
                  child:
                      _isLoading
                          ? CircularProgressIndicator()
                          : Text('Generate 3D Video'),
                )
                : Container(),
            SizedBox(height: 20),
            _videoUrl != null && _videoController != null
                ? _videoController!.value.isInitialized
                    ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                    : CircularProgressIndicator()
                : Container(),
          ],
        ),
      ),
    );
  }
}
