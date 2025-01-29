import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiUrl = "http://127.0.0.1:8000/extract_text/";  // Fixed endpoint

  Future<String> extractText(Uint8List imageBytes) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    try {
      // Add the image file to the request
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

      // Send the request and await the response
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final extractedText = json.decode(responseData)['extracted_cleaned_text'];
        return extractedText;
      } else {
        return 'Failed to extract text';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  extractTextFromImage(Uint8List croppedImage) {}
}