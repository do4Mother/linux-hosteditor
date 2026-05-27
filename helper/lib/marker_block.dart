class MarkerBlock {
  static const beginLine = '# BEGIN hosteditor — DO NOT EDIT THIS BLOCK BY HAND';
  static const endLine = '# END hosteditor';
  static final _begin = RegExp(r'^# BEGIN hosteditor.*$', multiLine: true);
  static final _end = RegExp(r'^# END hosteditor.*$', multiLine: true);

  static String replace(String fileContent, String blockBody) {
    final beginMatch = _begin.firstMatch(fileContent);
    final endMatch = _end.firstMatch(fileContent);
    final body = blockBody.isEmpty || blockBody.endsWith('\n')
        ? blockBody
        : '$blockBody\n';
    final newBlock = '$beginLine\n$body$endLine\n';

    if (beginMatch == null || endMatch == null || endMatch.start < beginMatch.start) {
      final sep = fileContent.isEmpty || fileContent.endsWith('\n') ? '' : '\n';
      return '$fileContent$sep$newBlock';
    }
    // endMatch.end is the position right after the matched text; we need to
    // also skip the trailing newline of the END line if present.
    var tail = endMatch.end;
    if (tail < fileContent.length && fileContent[tail] == '\n') tail++;
    return fileContent.substring(0, beginMatch.start) +
        newBlock +
        fileContent.substring(tail);
  }
}
