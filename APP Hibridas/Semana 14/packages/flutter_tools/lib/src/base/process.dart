// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../convert.dart';
import 'io.dart';
import 'logger.dart';

typedef StringConverter = String? Function(String string);

/// A function that will be run before the VM exits.
typedef ShutdownHook = FutureOr<void> Function();

// TODO(ianh): We have way too many ways to run subprocesses in this project.
// Convert most of these into one or more lightweight wrappers around the
// [ProcessManager] API using named parameters for the various options.
// See [here](https://github.com/flutter/flutter/pull/14535#discussion_r167041161)
// for more details.

abstract class ShutdownHooks {
  factory ShutdownHooks() => _DefaultShutdownHooks();

  /// Registers a [ShutdownHook] to be executed before the VM exits.
  void addShutdownHook(
    ShutdownHook shutdownHook
  );

  @visibleForTesting
  List<ShutdownHook> get registeredHooks;

  /// Runs all registered shutdown hooks and returns a future that completes when
  /// all such hooks have finished.
  ///
  /// Shutdown hooks will be run in groups by their [ShutdownStage]. All shutdown
  /// hooks within a given stage will be started in parallel and will be
  /// guaranteed to run to completion before shutdown hooks in the next stage are
  /// started.
  ///
  /// This class is constructed before the [Logger], so it cannot be direct
  /// injected in the constructor.
  Future<void> runShutdownHooks(Logger logger);
}

class _DefaultShutdownHooks implements ShutdownHooks {
  _DefaultShutdownHooks();

  @override
  final List<ShutdownHook> registeredHooks = <ShutdownHook>[];

  bool _shutdownHooksRunning = false;

  @override
  void addShutdownHook(
    ShutdownHook shutdownHook
  ) {
    assert(!_shutdownHooksRunning);
    registeredHooks.add(shutdownHook);
  }

  @override
  Future<void> runShutdownHooks(Logger logger) async {
    logger.printTrace(
      'Running ${registeredHooks.length} shutdown hook${registeredHooks.length == 1 ? '' : 's'}',
    );
    _shutdownHooksRunning = true;
    try {
      final List<Future<dynamic>> futures = <Future<dynamic>>[];
      for (final ShutdownHook shutdownHook in registeredHooks) {
        final FutureOr<dynamic> result = shutdownHook();
        if (result is Future<dynamic>) {
          futures.add(result);
        }
      }
      await Future.wait<dynamic>(futures);
    } finally {
      _shutdownHooksRunning = false;
    }
    logger.printTrace('Shutdown hooks complete');
  }
}

class ProcessExit implements Exception {
  ProcessExit(this.exitCode, {this.immediate = false});

  final bool immediate;
  final int exitCode;

  String get message => 'ProcessExit: $exitCode';

  @override
  String toString() => message;
}

class RunResult {
  RunResult(this.processResult, this._command)
    : assert(_command.isNotEmpty);

  final ProcessResult processResult;

  final List<String> _command;

  int get exitCode => processResult.exitCode;
  String get stdout => processResult.stdout as String;
  String get stderr => processResult.stderr as String;

  @override
  String toString() {
    final StringBuffer out = StringBuffer();
    if (stdout.isNotEmpty) {
      out.writeln(stdout);
    }
    if (stderr.isNotEmpty) {
      out.writeln(stderr);
    }
    return out.toString().trimRight();
  }

  /// Throws a [ProcessException] with the given `message`.
  void throwException(String message) {
    throw ProcessException(
      _command.first,
      _command.skip(1).toList(),
      message,
      exitCode,
    );
  }
}

typedef RunResultChecker = bool Function(int);

abstract class ProcessUtils {
  factory ProcessUtils({
    required ProcessManager processManager,
    required Logger logger,
  }) => _DefaultProcessUtils(
    processManager: processManager,
    logger: logger,
  );

  /// Spawns a child process to run the command [cmd].
  ///
  /// When [throwOnError] is `true`, if the child process finishes with a non-zero
  /// exit code, a [ProcessException] is thrown.
  ///
  /// If [throwOnError] is `true`, and [allowedFailures] is supplied,
  /// a [ProcessException] is only thrown on a non-zero exit code if
  /// [allowedFailures] returns false when passed the exit code.
  ///
  /// When [workingDirectory] is set, it is the working directory of the child
  /// process.
  ///
  /// When [allowReentrantFlutter] is set to `true`, the child process is
  /// permitted to call the Flutter tool. By default it is not.
  ///
  /// When [environment] is supplied, it is used as the environment for the child
  /// process.
  ///
  /// When [timeout] is supplied, [runAsync] will kill the child process and
  /// throw a [ProcessException] when it doesn't finish in time.
  ///
  /// If [timeout] is supplied, the command will be retried [timeoutRetries] times
  /// if it times out.
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker? allowedFailures,
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    Duration? timeout,
    int timeoutRetries = 0,
  });

  /// Run the command and block waiting for its result.
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker? allowedFailures,
    bool hideStdout = false,
    String? workingDirectory,
    Map<String, String>? environment,
    bool allowReentrantFlutter = false,
    Encoding encoding = systemEncoding,
  });

  /// This runs the command in the background from the specified working
  /// directory. Completes when the process has been started.
  Future<Process> start(
    List<String> cmd, {
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    ProcessStartMode mode = ProcessStartMode.normal,
  });

  /// This runs the command and streams stdout/stderr from the child process to
  /// this process' stdout/stderr. Completes with the process's exit code.
  ///
  /// If [filter] is null, no lines are removed.
  ///
  /// If [filter] is non-null, all lines that do not match it are removed. If
  /// [mapFunction] is present, all lines that match [filter] are also forwarded
  /// to [mapFunction] for further processing.
  ///
  /// If [stdoutErrorMatcher] is non-null, matching lines from stdout will be
  /// treated as errors, just as if they had been logged to stderr instead.
  Future<int> stream(
    List<String> cmd, {
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp? filter,
    RegExp? stdoutErrorMatcher,
    StringConverter? mapFunction,
    Map<String, String>? environment,
  });

  bool exitsHappySync(
    List<String> cli, {
    Map<String, String>? environment,
  });

  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String>? environment,
  });
}

class _DefaultProcessUtils implements ProcessUtils {
  _DefaultProcessUtils({
    required ProcessManager processManager,
    required Logger logger,
  }) : _processManager = processManager,
      _logger = logger;

  final ProcessManager _processManager;

  final Logger _logger;

  @override
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker? allowedFailures,
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    Duration? timeout,
    int timeoutRetries = 0,
  }) async {
    if (cmd.isEmpty) {
      throw ArgumentError('cmd must be a non-empty list');
    }
    if (timeoutRetries < 0) {
      throw ArgumentError('timeoutRetries must be non-negative');
    }
    _traceCommand(cmd, workingDirectory: workingDirectory);

    // When there is no timeout, there's no need to kill a running process, so
    // we can just use _processManager.run().
    if (timeout == null) {
      final ProcessResult results = await _processManager.run(
        cmd,
        workingDirectory: workingDirectory,
        environment: _environment(allowReentrantFlutter, environment),
      );
      final RunResult runResult = RunResult(results, cmd);
      _logger.printTrace(runResult.toString());
      if (throwOnError && runResult.exitCode != 0 &&
          (allowedFailures == null || !allowedFailures(runResult.exitCode))) {
        runResult.throwException('Process exited abnormally:\n$runResult');
      }
      return runResult;
    }

    // When there is a timeout, we have to kill the running process, so we have
    // to use _processManager.start() through _runCommand() above.
    while (true) {
      assert(timeoutRetries >= 0);
      timeoutRetries = timeoutRetries - 1;

      final Process process = await start(
          cmd,
          workingDirectory: workingDirectory,
          allowReentrantFlutter: allowReentrantFlutter,
          environment: environment,
      );

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();
      final Future<void> stdoutFuture = process.stdout
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stdoutBuffer.write)
          .asFuture<void>();
      final Future<void> stderrFuture = process.stderr
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stderrBuffer.write)
          .asFuture<void>();

      int? exitCode;
      exitCode = await process.exitCode.then<int?>((int x) => x).timeout(timeout, onTimeout: () {
        // The process timed out. Kill it.
        _processManager.killPid(process.pid);
        return null;
      });

      String stdoutString;
      String stderrString;
      try {
        Future<void> stdioFuture =
            Future.wait<void>(<Future<void>>[stdoutFuture, stderrFuture]);
        if (exitCode == null) {
          // If we had to kill the process for a timeout, only wait a short time
          // for the stdio streams to drain in case killing the process didn't
          // work.
          stdioFuture = stdioFuture.timeout(const Duration(seconds: 1));
        }
        await stdioFuture;
      } on Exception {
        // Ignore errors on the process' stdout and stderr streams. Just capture
        // whatever we got, and use the exit code
      }
      stdoutString = stdoutBuffer.toString();
      stderrString = stderrBuffer.toString();

      final ProcessResult result = ProcessResult(
          process.pid, exitCode ?? -1, stdoutString, stderrString);
      final RunResult runResult = RunResult(result, cmd);

      // If the process did not timeout. We are done.
      if (exitCode != null) {
        _logger.printTrace(runResult.toString());
        if (throwOnError && runResult.exitCode != 0 &&
            (allowedFailures == null || !allowedFailures(exitCode))) {
          runResult.throwException('Process exited abnormally:\n$runResult');
        }
        return runResult;
      }

      // If we are out of timeoutRetries, throw a ProcessException.
      if (timeoutRetries < 0) {
        runResult.throwException('Process timed out:\n$runResult');
      }

      // Log the timeout with a trace message in verbose mode.
      _logger.printTrace(
        'Process "${cmd[0]}" timed out. $timeoutRetries attempts left:\n'
        '$runResult',
      );
    }

    // Unreachable.
  }

  @override
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    bool verboseExceptions = false,
    RunResultChecker? allowedFailures,
    bool hideStdout = false,
    String? workingDirectory,
    Map<String, String>? environment,
    bool allowReentrantFlutter = false,
    Encoding encoding = systemEncoding,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    final ProcessResult results = _processManager.runSync(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
      stderrEncoding: encoding,
      stdoutEncoding: encoding,
    );
    final RunResult runResult = RunResult(results, cmd);

    _logger.printTrace('Exit code ${runResult.exitCode} from: ${cmd.join(' ')}');

    bool failedExitCode = runResult.exitCode != 0;
    if (allowedFailures != null && failedExitCode) {
      failedExitCode = !allowedFailures(runResult.exitCode);
    }

    if (runResult.stdout.isNotEmpty && !hideStdout) {
      if (failedExitCode && throwOnError) {
        _logger.printStatus(runResult.stdout.trim());
      } else {
        _logger.printTrace(runResult.stdout.trim());
      }
    }

    if (runResult.stderr.isNotEmpty) {
      if (failedExitCode && throwOnError) {
        _logger.printError(runResult.stderr.trim());
      } else {
        _logger.printTrace(runResult.stderr.trim());
      }
    }

    if (failedExitCode && throwOnError) {
      String message = 'The command failed';
      if (verboseExceptions) {
        message = 'The command failed\nStdout:\n${runResult.stdout}\n'
            'Stderr:\n${runResult.stderr}';
      }
      runResult.throwException(message);
    }

    return runResult;
  }

  @override
  Future<Process> start(
    List<String> cmd, {
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String>? environment,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    return _processManager.start(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
      mode: mode,
    );
  }

  @override
  Future<int> stream(
    List<String> cmd, {
    String? workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp? filter,
    RegExp? stdoutErrorMatcher,
    StringConverter? mapFunction,
    Map<String, String>? environment,
  }) async {
    final Process process = await start(
      cmd,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: environment,
    );
    final StreamSubscription<String> stdoutSubscription = process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        String? mappedLine = line;
        if (mapFunction != null) {
          mappedLine = mapFunction(line);
        }
        if (mappedLine != null) {
          final String message = '$prefix$mappedLine';
          if (stdoutErrorMatcher?.hasMatch(mappedLine) ?? false) {
            _logger.printError(message, wrap: false);
          } else if (trace) {
            _logger.printTrace(message);
          } else {
            _logger.printStatus(message, wrap: false);
          }
        }
      });
    final StreamSubscription<String> stderrSubscription = process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        String? mappedLine = line;
        if (mapFunction != null) {
          mappedLine = mapFunction(line);
        }
        if (mappedLine != null) {
          _logger.printError('$prefix$mappedLine', wrap: false);
        }
      });

    // Wait for stdout to be fully processed
    // because process.exitCode may complete first causing flaky tests.
    await Future.wait<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    // The streams as futures have already completed, so waiting for the
    // potentially async stream cancellation to complete likely has no benefit.
    // Further, some Stream implementations commonly used in tests don't
    // complete the Future returned here, which causes tests using
    // mocks/FakeAsync to fail when these Futures are awaited.
    unawaited(stdoutSubscription.cancel());
    unawaited(stderrSubscription.cancel());

    return process.exitCode;
  }

  @override
  bool exitsHappySync(
    List<String> cli, {
    Map<String, String>? environment,
  }) {
    _traceCommand(cli);
    if (!_processManager.canRun(cli.first)) {
      _logger.printTrace('$cli either does not exist or is not executable.');
      return false;
    }

    try {
      return _processManager.runSync(cli, environment: environment).exitCode == 0;
    } on Exception catch (error) {
      _logger.printTrace('$cli failed with $error');
      return false;
    }
  }

  @override
  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String>? environment,
  }) async {
    _traceCommand(cli);
    if (!_processManager.canRun(cli.first)) {
      _logger.printTrace('$cli either does not exist or is not executable.');
      return false;
    }

    try {
      return (await _processManager.run(cli, environment: environment)).exitCode == 0;
    } on Exception catch (error) {
      _logger.printTrace('$cli failed with $error');
      return false;
    }
  }

  Map<String, String>? _environment(bool allowReentrantFlutter, [
    Map<String, String>? environment,
  ]) {
    if (allowReentrantFlutter) {
      if (environment == null) {
        environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'};
      } else {
        environment['FLUTTER_ALREADY_LOCKED'] = 'true';
      }
    }

    return environment;
  }

  void _traceCommand(List<String> args, { String? workingDirectory }) {
    final String argsText = args.join(' ');
    if (workingDirectory == null) {
      _logger.printTrace('executing: $argsText');
    } else {
      _logger.printTrace('executing: [$workingDirectory/] $argsText');
    }
  }
}
