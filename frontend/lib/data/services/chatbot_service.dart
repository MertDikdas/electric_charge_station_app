import '../api/api_client.dart';
import 'json_helpers.dart';

class ChatbotService {
  ChatbotService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChatbotResponse> sendMessage({required String message}) async {
    final response = await _apiClient.post(
      '/chatbots/message',
      body: {'message': message},
    );

    return ChatbotResponse.fromJson(parseObject(response));
  }
}

class ChatbotResponse {
  const ChatbotResponse({required this.reply});

  final String reply;

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(reply: (json['reply'] ?? '').toString());
  }
}
