import 'dart:convert';

typedef JsonMap = Map<String, dynamic>;

String prettyEncode(Object? json) =>
    const JsonEncoder.withIndent(' ').convert(json);

typedef TypedId = ({String kind, String key, String orignial});
