// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mason/mason.dart';

import '../../gherkin.dart';
import 'json/json_statuses.dart';

enum HtmlFramework {
  bootstrap5,
}

extension HtmlFrameworksPaths on HtmlFramework {
  String get path {
    switch (this) {
      case HtmlFramework.bootstrap5:
        return '/bootstrap5_template';
      default:
        throw ArgumentError.value(this);
    }
  }
}

class HtmlReporter extends JsonReporter {
  HtmlReporter({
    WriteReportCallback? writeReport,
    String path = './$defaultFileName',
    this.framework = HtmlFramework.bootstrap5,
    this.appVersion,
    this.buildNumber,
    this.targetDevice,
    this.targetPlatform,
    this.testEnviroment,
  }) : super(writeReport: writeReport, path: path);

  /// Html framework. Default: Bootstrap5
  final HtmlFramework framework;

  // Metadata
  final String? appVersion;

  final String? targetDevice;

  final String? targetPlatform;

  final String? testEnviroment;

  final int? buildNumber;

  static const String defaultFileName = 'report.html';

  static const String _brickPath = '/bricks';

  @override
  Future<void> onSaveReport(String jsonReport, String path) async {
    final scenarios = features.expand((element) => element.scenarios);
    final scenariosPassed = scenarios
        .where(
          (element) =>
              element.steps.every((step) => step.status == JsonStatus.passed),
        )
        .length;
    final scenariosFailed = scenarios
        .where(
          (element) =>
              element.steps.every((step) => step.status == JsonStatus.failed),
        )
        .length;

    final scenariosSkipped = scenarios
        .where(
          (element) =>
              element.steps.every((step) => step.status == JsonStatus.skipped),
        )
        .length;

    final featuresPassed = features
        .where(
          (feature) => feature.scenarios.every(
            (scenario) => scenario.steps
                .every((step) => step.status == JsonStatus.passed),
          ),
        )
        .length;

    final featuresSkipped = features
        .where(
          (feature) => feature.scenarios.every(
            (scenario) => scenario.steps
                .every((step) => step.status == JsonStatus.skipped),
          ),
        )
        .length;

    final featuresFailed = features
        .where(
          (feature) => feature.scenarios.every(
            (scenario) => scenario.steps
                .every((step) => step.status == JsonStatus.failed),
          ),
        )
        .length;

    final featuresTime = features.map(
      (e) => e.scenarios
          .expand((element) => element.steps)
          .map((e) => e.durationMs)
          .fold<int>(0, (previousValue, element) => previousValue + element),
    );

    final scenariosTime = features.expand((element) => element.scenarios).map(
          (e) => e.steps.map((e) => e.durationMs).fold<int>(
                0,
                (previousValue, element) => previousValue + element,
              ),
        );

    final json = _prepareJson(jsonDecode(jsonReport) as List<dynamic>);
    final fullPath = Directory.current.path + _brickPath + framework.path;
    final brick = Brick.path(fullPath);
    final generator = await MasonGenerator.fromBrick(brick);
    final target = DirectoryGeneratorTarget(Directory.current);
    final frameworkData = Bootstrap5Data(
      fileName: 'report',
      title: 'Report ${DateTime.now().toString()}',
      reportData: json,
      scenariosFailed: scenariosFailed,
      scenariosPassed: scenariosPassed,
      scenariosSkipped: scenariosSkipped,
      featuresFailed: featuresFailed,
      featuresPassed: featuresPassed,
      featuresSkipped: featuresSkipped,
      featuresAverageTime:
          Duration(milliseconds: featuresTime.average.toInt()).toString(),
      featuresMaxTime:
          Duration(milliseconds: featuresTime.maxOrNull ?? 0).toString(),
      featuresMinTime:
          Duration(milliseconds: featuresTime.minOrNull ?? 0).toString(),
      featuresTotalTime: Duration(milliseconds: featuresTime.sum).toString(),
      scenariosAverageTime:
          Duration(milliseconds: scenariosTime.average.toInt()).toString(),
      scenariosMaxTime:
          Duration(milliseconds: scenariosTime.maxOrNull ?? 0).toString(),
      scenariosMinTime:
          Duration(milliseconds: scenariosTime.minOrNull ?? 0).toString(),
      scenariosTotalTime: Duration(milliseconds: scenariosTime.sum).toString(),
      appVersion: appVersion,
      targetDevice: targetDevice,
      targetPlatform: targetPlatform,
      testEnviroment: testEnviroment,
      executedOs: Platform.operatingSystemVersion,
    ).toMap();

    await generator.generate(
      target,
      vars: frameworkData,
      fileConflictResolution: FileConflictResolution.overwrite,
    );
  }

  static final Random _rnd = Random();
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  String getRandomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ),
    );
  }

  List<dynamic> _prepareJson(List<dynamic> json) {
    final copy = List.of(json);

    for (final el in copy) {
      el['hash'] = getRandomString(13);
      final elements = el['elements'] as List<dynamic>;
      for (final sc in elements) {
        sc['hash'] = getRandomString(13);
        sc['scTags'] = sc['tags'] as List<dynamic>?;

        final steps = sc['steps'] as List<dynamic>;

        for (final st in steps) {
          st['hash'] = getRandomString(13);
          final status = st['result']['status'] as String;
          st['isSkipped'] = status == 'skipped';
          st['isFailed'] = status == 'failed';
          st['isPassed'] = status == 'passed';
          st['timeMs'] = (st['result']['duration'] as int) ~/ 1000000;
        }
      }
    }

    return copy;
  }
}

class Bootstrap5Data {
  const Bootstrap5Data({
    required this.fileName,
    required this.title,
    required this.reportData,
    required this.scenariosPassed,
    required this.scenariosFailed,
    required this.scenariosSkipped,
    required this.scenariosMaxTime,
    required this.scenariosMinTime,
    required this.scenariosAverageTime,
    required this.scenariosTotalTime,
    required this.featuresPassed,
    required this.featuresFailed,
    required this.featuresSkipped,
    required this.featuresMaxTime,
    required this.featuresMinTime,
    required this.featuresAverageTime,
    required this.featuresTotalTime,
    this.appVersion,
    this.buildNumber,
    this.targetDevice,
    this.targetPlatform,
    this.testEnviroment,
    this.executedOs,
  });

  final String fileName;
  final String title;
  final List<dynamic> reportData;

  // Scenarios data
  final int scenariosPassed;
  final int scenariosFailed;
  final int scenariosSkipped;
  final String scenariosMaxTime;
  final String scenariosMinTime;
  final String scenariosAverageTime;
  final String scenariosTotalTime;

  // Features data
  final int featuresPassed;
  final int featuresFailed;
  final int featuresSkipped;
  final String featuresMaxTime;
  final String featuresMinTime;
  final String featuresAverageTime;
  final String featuresTotalTime;

  // Meta Data
  final String? appVersion;
  final int? buildNumber;
  final String? targetDevice;
  final String? targetPlatform;
  final String? testEnviroment;
  final String? executedOs;

  bool get showAppVersion => appVersion != null;
  bool get showBuildNumber => buildNumber != null;
  bool get showTargetDevice => targetDevice != null;
  bool get showTargetPlatform => targetPlatform != null;
  bool get showTestEnviroment => testEnviroment != null;
  bool get showExectuedOs => executedOs != null;

  bool get showMetadata =>
      showAppVersion ||
      showTestEnviroment ||
      showTargetPlatform ||
      showTargetDevice ||
      showBuildNumber ||
      showExectuedOs;

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'title': title,
      'reportData': reportData,
      'scenariosPassed': scenariosPassed,
      'scenariosFailed': scenariosFailed,
      'scenariosSkipped': scenariosSkipped,
      'scenariosMaxTime': scenariosMaxTime,
      'scenariosMinTime': scenariosMinTime,
      'scenariosAverageTime': scenariosAverageTime,
      'scenariosTotalTime': scenariosTotalTime,
      'featuresPassed': featuresPassed,
      'featuresFailed': featuresFailed,
      'featuresSkipped': featuresSkipped,
      'featuresMaxTime': featuresMaxTime,
      'featuresMinTime': featuresMinTime,
      'featuresAverageTime': featuresAverageTime,
      'featuresTotalTime': featuresTotalTime,
      'appVersion': appVersion ?? '',
      'buildNumber': buildNumber ?? '',
      'targetDevice': targetDevice ?? '',
      'targetPlatform': targetPlatform ?? '',
      'testEnviroment': testEnviroment ?? '',
      'executedOs': executedOs ?? '',
      'showAppVersion': showAppVersion,
      'showBuildNumber': showBuildNumber,
      'showTargetDevice': showTargetDevice,
      'showTargetPlatform': showTargetPlatform,
      'showTestEnviroment': showTestEnviroment,
      'showExectuedOs': showExectuedOs,
      'showMetadata': showMetadata,
    };
  }

  String toJson() => json.encode(toMap());
}
