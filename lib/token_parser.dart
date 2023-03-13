import 'package:figma2flutter/models/token.dart';

class TokenParser {
  final List<String> sets;
  final Map<String, Token> tokenMap = {};

  TokenParser([this.sets = const []]);

  void parse(Map<String, dynamic> input) {
    tokenMap.addAll(findTokens('.', input));

    _postProcess();
  }

  // Loop trough the ordered sets and remove the set name from key an path
  // this will make sure that overrides are properly applied
  void _postProcess() {
    for (var element in sets) {
      final set = '$element.';
      final setLength = set.length - 1;

      tokenMap.entries.where((element) => element.key.startsWith(set)).toList().forEach((entry) {
        final key = entry.key;
        final value = entry.value;

        if (key.startsWith(set)) {
          tokenMap.remove(key);
          tokenMap[key.substring(setLength + 1)] = value.copyWith(
            path: value.path.substring(setLength),
          );
        }
      });
    }
  }

  Map<String, Token> findTokens(String parent, Map<String, dynamic> input, [String? groupType]) {
    final tokens = <String, Token>{};

    if (input.containsKey('value')) {
      final cleaned = parent.substring(0, parent.length - 1); // remove the trailing dot
      final name = cleaned.split('.').last;

      final end = cleaned.length - name.length - 1;
      final path = end > 0 ? cleaned.substring(1, end) : '';
      final token = Token(
        value: input['value'],
        type: input['type'] as String? ?? groupType as String,
        path: path,
        name: name,
      );

      return {
        [path, name].where((e) => e.isNotEmpty).join('.'): token
      };
    }

    input.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        tokens.addAll(findTokens('$parent$key.', value, input['type'] as String?));
      }
    });

    return tokens;
  }

  Token? getReference(Token token) {
    return tokenMap[token.value.substring(1)];
  }
}