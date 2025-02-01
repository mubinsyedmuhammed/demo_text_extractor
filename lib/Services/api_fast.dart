import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiUrl = "http://127.0.0.1:8000/extract_text/";

  Future<String> extractText(Uint8List croppedImage) async {
    try {
      if (croppedImage.isEmpty) {
        throw OCRException('Invalid image data: Empty image');
      }

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        http.MultipartFile.fromBytes('file', croppedImage, filename: 'image.jpg')
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw OCRException('Connection timeout after 30 seconds'),
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        
        if (!jsonResponse.containsKey('extracted_cleaned_text')) {
          throw OCRException('Invalid response format: Missing extracted_cleaned_text');
        }
        
        final extractedText = jsonResponse['extracted_cleaned_text'] as String;
        if (extractedText.trim().isEmpty) {
          throw OCRException('No text found in image');
        }
        
        log('Successfully extracted text: $extractedText');
        return extractedText;
      } else {
        throw OCRException('Server error: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw OCRException('Invalid response format: ${e.message}');
    } on OCRException {
      rethrow;
    } catch (e) {
      throw OCRException('OCR Error: $e');
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

class OCRException implements Exception {
  final String message;
  OCRException(this.message);
  
  @override
  String toString() => message;
}


