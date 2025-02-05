import 'package:http/http.dart' as http;
import 'package:intelligrade/controller/model/beans.dart';

// Static class to access the C# compiler service.
class CsharpCompilerApiService {
  static const baseUrl = 'http://18.222.224.35:8001';
  static const compileUrl = '$baseUrl/compile/csharp';

  // Submits student files and instructor test file to the C# compiler.
  // The test file is run, and output is returned as a string.
  static Future<String> compileAndGrade(List<FileNameAndBytes> studentFiles) async {
    var request = http.MultipartRequest('POST', Uri.parse(compileUrl));

    // Attach files to the request
    for (var file in studentFiles) {
      request.files.add(http.MultipartFile.fromBytes(
        'files', 
        file.bytes,
        filename: file.filename,
      ));
    }

    // Send the request to the server
    var response = await request.send();

    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      throw Exception('Failed to compile and run C# code');
    }
  }
}