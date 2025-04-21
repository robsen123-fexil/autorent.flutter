import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Services {

Future<void> generateVideo(String imageUrl) async {
  String apiKey = '74931102c587c3522ddf7d0c51cb9d010d75c666b115d60d87592cf20962fb0d';
  Uri url = Uri.parse('https://api.segmind.com/v1/kling-image2video');

  Map<String, dynamic> body = {
    'image': imageUrl,
    'prompt': 'A serene beach at sunset with waves gently crashing and seagulls flying overhead.',
    'negative_prompt': 'No sudden movements, no fast zooms.',
    'cfg_scale': 0.5,
    'mode': 'pro',
    'duration': 5,
  };

  Map<String, String> headers = {
    'x-api-key': apiKey,
    'Content-Type': 'application/json',
  };

  http.Response response = await http.post(url, headers: headers, body: json.encode(body));

  if (response.statusCode == 200) {
    print('Video generated successfully');
  } else {
    print('Failed to generate video: ${response.body}');
  }
}


Future<String?> uploadImage() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) return null;

  File imageFile = File(pickedFile.path);
  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  Reference storageRef = FirebaseStorage.instance.ref().child('images/$fileName');

  UploadTask uploadTask = storageRef.putFile(imageFile);
  TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

  String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  return downloadUrl;

}

Future<void> storeImageUrl(String imageUrl) async {
  await FirebaseFirestore.instance.collection('images').add({
    'url': imageUrl,
    'timestamp': FieldValue.serverTimestamp(),
  });
}


}