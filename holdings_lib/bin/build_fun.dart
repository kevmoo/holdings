import 'dart:io';

import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;

const _flutterDirectory = '/Users/kevmoo/github/flutter';

const _flutterVersions = <String, String>{
  '3.32.0-0.1.pre': 'eeb81b9',
  'last_main': '9d3d0dc0ed',
  'throw_silly_lerp': 'e34e0fc6c7',
  'segment_button_null': 'fb8c9a3c3f',
};

final _appDir = p.canonicalize(p.join(p.current, '..', 'flutter_web_demo'));

Future<void> main(List<String> args) async {
  print('Using this dart');
  print(Platform.resolvedExecutable);

  print('App dir: $_appDir');

  final flutterDir = Directory(_flutterDirectory);

  assert(flutterDir.existsSync());
  assert(
    !p.isWithin(_flutterDirectory, Platform.resolvedExecutable),
    'dude, use another dart!',
  );

  final outputRoot = Directory(p.join(p.current, 'out'));
  if (outputRoot.existsSync()) {
    throw StateError('We need you to delete the `out` directory manually, sir');
  }

  var count = 0;
  for (var entry in _flutterVersions.entries) {
    final MapEntry(key: commitName, value: commitSha) = entry;
    print('Rocking on $commitName');

    // checkout the SHA
    await _run('git', ['checkout', commitSha], workingDir: _flutterDirectory);
    // await _run('git', ['clean', '-fdx'], workingDir: _flutterDirectory);

    // flutter doctor
    await _run('flutter', ['doctor', '-v'], workingDir: _flutterDirectory);

    final outputDir = p.join(
      outputRoot.path,
      '${count.toString().padLeft(3, '0')}_${commitSha}_$commitName',
    );

    // build the app - to the out directory 00X_sha{8}_description
    await _run('flutter', [
      'build',
      'web',
      '--dump-info',
      '--no-frequency-based-minification',
      '--pwa-strategy',
      'none',
      '--no-source-maps',
      '--output',
      outputDir,
    ], workingDir: _appDir);

    count++;
  }
}

void _screamHeader(String value) {
  print(red.wrap(['*' * 80, value, '*' * 80].join('\n')));
}

Future<void> _run(
  String executable,
  List<String> args, {
  required String workingDir,
}) async {
  _screamHeader('''
RUNNING
`${[executable, ...args].join(' ')}`
in $workingDir''');

  final proc = await Process.start(
    executable,
    args,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
    workingDirectory: workingDir,
  );

  final errorCode = await proc.exitCode;
  if (errorCode != 0) {
    throw ProcessException(executable, args, 'Boo!', errorCode);
  }
}
