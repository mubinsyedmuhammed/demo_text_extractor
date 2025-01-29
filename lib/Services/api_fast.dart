import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  final String apiUrl = "http://127.0.0.1:8000/extract_text/";

  Future<String> extractText(Uint8List imageBytes) async {
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    try {
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final extractedText = json.decode(responseData)['extracted_cleaned_text'];
        log('extracted text is $extractedText');
        return extractedText;
      } else {
        log('Failed to extract text in OCRService.');
        return 'Failed to extract text in OCRService.';
      }
    } catch (e) {
      log('exception raise');
      return 'Error: $e';
    }
  }

  Future<String> extractTextFromImage(Uint8List croppedImage) async {
    return await extractText(croppedImage); // Call extractText with the cropped image
  }
}
