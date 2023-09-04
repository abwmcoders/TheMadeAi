import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/secret.dart';

class RequestService {
  Future<http.Response> requestOpenAi(
      String userInput, String mode, String apiKey, int maxTalker) async {
    const String baseUrl = "https://api.openai.com/";
    final String url =
        mode == "chat" ? "v1/completions" : "v1/images/generations";

    final body = mode == "chat"
        ? {
            "model": "text-davinci-003",
            "prompt": userInput,
            "max_tokens": 200,
            "temperature": 0.9,
            "n": 1,
          }
        : {
            "prompt": userInput,
          };

    final response = http.post(
      Uri.parse(baseUrl + url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $openAIAPIKey",
      },
      body: jsonEncode(body),
    );

    return response;
  }
}
