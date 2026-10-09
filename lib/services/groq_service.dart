import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wraps every call to the Groq API. The app never calls http directly
/// from a screen or provider - same pattern as AuthService and
/// WorkoutLogService.
///
/// IMPORTANT: this service only ever asks Groq to phrase a short sentence
/// around numbers that progressive_overload.dart already computed. It never
/// asks the model to do arithmetic, so a bad or slow AI response can never
/// make a recommendation's numbers wrong - only its wording temporarily
/// falls back to a plain sentence (see recommendation_provider.dart).
class GroqService {
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  /// Takes one entry per exercise (exercise name, current + suggested
  /// numbers, and the trigger reason from suggestNext()) and returns a map
  /// of exerciseName -> one short coaching sentence.
  ///
  /// Batches every exercise into a single request rather than one call per
  /// exercise, to stay well inside the free-tier rate limit.
  Future<Map<String, String>> explainRecommendations(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return {};
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw GroqException('No GROQ_API_KEY configured for this build.');
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0.4,
            'messages': [
              {'role': 'user', 'content': _buildPrompt(items)},
            ],
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 429) {
      throw GroqException('Rate limited - try again shortly.');
    }
    if (response.statusCode != 200) {
      throw GroqException('Groq returned ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    // Strip markdown code fences in case the model adds them despite being
    // asked not to - defensive parsing, same as any LLM JSON response.
    final cleaned = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    return parsed.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Takes a small set of already-computed weekly stats (top/neglected
  /// muscle group, 1RM % change for the pinned exercise) and returns 2-3
  /// short coaching sentences for the Analysis tab's "Key Insights" card.
  ///
  /// Same reliability contract as explainRecommendations: every number in
  /// `facts` was computed in Dart before this call, so a failed or slow
  /// Groq response can only cost wording, never a wrong number (see
  /// analysisProvider's fallback sentences).
  Future<List<String>> explainKeyInsights(Map<String, dynamic> facts) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw GroqException('No GROQ_API_KEY configured for this build.');
    }

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0.4,
            'messages': [
              {'role': 'user', 'content': _buildInsightsPrompt(facts)},
            ],
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 429) {
      throw GroqException('Rate limited - try again shortly.');
    }
    if (response.statusCode != 200) {
      throw GroqException('Groq returned ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    final cleaned = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final parsed = jsonDecode(cleaned);
    final rawList = parsed is Map<String, dynamic>
        ? parsed['insights']
        : parsed;
    return (rawList as List).map((e) => e.toString()).toList();
  }

  String _buildInsightsPrompt(Map<String, dynamic> facts) {
    return '''
You are a strength coach summarising this week's training data for a user.
Every fact below is ALREADY CALCULATED - do not invent numbers or change them.

Facts:
- Highest-volume muscle group this week: ${facts['topMuscleGroup'] ?? 'not enough data yet'}
- Lowest-volume muscle group this week: ${facts['neglectedMuscleGroup'] ?? 'not enough data yet'}
- ${facts['exercise']} estimated 1RM change since first log: ${facts['oneRmPercentChange']}%

Write 2 to 3 short, encouraging insight sentences (max 20 words each) for a
gym app dashboard, using ONLY the facts above. Skip any fact marked "not
enough data yet".
Respond ONLY with a raw JSON object: {"insights": ["...", "..."]}. No
markdown fences, no extra text before or after.
''';
  }

  String _buildPrompt(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer()
      ..writeln(
        'You are a strength coach. For each exercise below the target '
        'weight and reps are ALREADY DECIDED - do not change them or do '
        'any calculation yourself.',
      )
      ..writeln(
        'Write exactly one short, encouraging sentence (max 20 words) per '
        'exercise, explaining the change using the given reason.',
      )
      ..writeln(
        'Respond ONLY with a raw JSON object mapping exercise name to '
        'sentence. No markdown fences, no extra text before or after.',
      )
      ..writeln();

    for (final item in items) {
      buffer.writeln(
        '- ${item['exercise']}: last session ${item['currentWeight']}kg x '
        '${item['currentReps']} reps, next target ${item['suggestedWeight']}kg '
        'x ${item['suggestedReps']} reps. Reason: ${item['trigger']}.',
      );
    }

    return buffer.toString();
  }
}

class GroqException implements Exception {
  final String message;
  GroqException(this.message);

  @override
  String toString() => message;
}
