import 'dart:io';
void main() {
  final file = File('lib/screens/playlist_detail_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    '''                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 20,''',
    '''                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 20,'''
  );
  file.writeAsStringSync(content);
}