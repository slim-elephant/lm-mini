class SelectionUtils {
  static String extractMarkdown(String plainText, String markdown) {
    if (plainText.isEmpty) return plainText;
    
    String normalizedPlain = plainText.replaceAll('•', '-').replaceAll('◦', '-').replaceAll('▪', '-');
    String cleanPlain = normalizedPlain.replaceAll(RegExp(r'\s+'), '');
    if (cleanPlain.isEmpty) return plainText;
    
    int mIdx = 0;
    int pIdx = 0;
    
    int matchStart = -1;
    int matchEnd = -1;
    
    while (mIdx < markdown.length && pIdx < cleanPlain.length) {
      String mChar = markdown[mIdx];
      
      if (mChar.trim().isEmpty) {
        if (matchStart != -1) matchEnd = mIdx + 1;
        mIdx++;
        continue;
      }
      
      if (mChar == cleanPlain[pIdx]) {
        if (matchStart == -1) matchStart = mIdx;
        matchEnd = mIdx + 1;
        pIdx++;
        mIdx++;
      } else {
        if (matchStart == -1) {
          mIdx++;
        } else {
          if ('*_#`~[]()<>\\\\\$'.contains(mChar) || mChar == '\n' || mChar == '\r' || mChar == '-' || mChar == '+' || (RegExp(r'[0-9]').hasMatch(mChar) || mChar == '.')) {
            mIdx++;
            matchEnd = mIdx;
          } else {
            mIdx++;
          }
        }
      }
    }
    
    if (matchStart != -1 && matchEnd != -1 && pIdx >= cleanPlain.length * 0.8) {
      return markdown.substring(matchStart, matchEnd).trim();
    }
    return plainText;
  }
}
