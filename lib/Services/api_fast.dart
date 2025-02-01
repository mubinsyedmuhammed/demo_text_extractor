import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiUrl = "http://127.0.0.1:8000/extract_text/";

  Future<String> extractText(Uint8List croppedImage) async {
    if (croppedImage.isEmpty) {
      throw Exception('Invalid image data');
    }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    try {
      request.files.add(
        http.MultipartFile.fromBytes('file', croppedImage, filename: 'image.jpg')
      );

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        
        if (!jsonResponse.containsKey('extracted_cleaned_text')) {
          throw Exception('Invalid response format');
        }
        
        final extractedText = jsonResponse['extracted_cleaned_text'];
        log('Extracted text: $extractedText');
        return extractedText;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      log('OCR Error: $e');
      rethrow;
    }
  }

  Future<String> extractTextFromImageOcr(Uint8List croppedImage) async {
    try {
      return await extractText(croppedImage);
    } catch (e) {
      log('Text extraction failed: $e');
      return ''; // Return empty string on error
    }
  }
}


