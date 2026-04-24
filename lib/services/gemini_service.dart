// lib/services/gemini_service.dart
// WEB API: Google Gemini Integration
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/expense_model.dart';

class GeminiService {
  static const _textEndpoint =
    '${AppConstants.geminiEndpointText}?key=${AppConstants.geminiApiKey}';
  static const _visionEndpoint =
    '${AppConstants.geminiEndpointVision}?key=${AppConstants.geminiApiKey}';

  static Future<String> generateInsights(List<ExpenseModel> expenses) async {
    if (expenses.isEmpty) return 'No expense data available for analysis.';

    final summary = expenses.map((e) => {
      'date': e.date.toIso8601String().substring(0, 10),
      'amount': e.amount, 'category': e.category,
      'description': e.description,
    }).toList();

    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    final prompt = '''
You are a friendly financial advisor helping a small business owner who sells frozen pastries in Accra, Ghana.
Analyse these ${expenses.length} expense records (total: GH₵${total.toStringAsFixed(2)}) and provide:
1. A brief 2-sentence spending summary
2. Top 3 spending categories with percentages
3. 3 specific, actionable tips to reduce costs
4. A single encouraging closing sentence

Expense data: ${jsonEncode(summary)}

Respond in plain text, no markdown. Use GH₵ for currency.
''';

    try {
      final response = await http.post(
        Uri.parse(_textEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 600},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      return 'Could not generate insights at this time. Please try again later.';
    } catch (_) {
      return 'Network error. Please check your connection and try again.';
    }
  }

  static Future<Map<String, dynamic>> extractReceiptData(String base64Image) async {
    const prompt = '''
Extract the following from this receipt image. Return ONLY valid JSON, no markdown:
{"vendor":"name or null","amount":number or null,"date":"YYYY-MM-DD or null","category":"Food & Ingredients|Transport|Inventory|Labour|Utilities|Equipment|Packaging|Other","raw":"brief description"}
''';
    try {
      final response = await http.post(
        Uri.parse(_visionEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [
            {'text': prompt},
            {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}},
          ]}],
          'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 300},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(text) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
}
