import 'package:flutter/services.dart' show rootBundle;
import 'package:muscle_selector/muscle_selector.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:collection/collection.dart';
import 'dart:ui';
import 'size_controller.dart';
import 'constant.dart';

class Parser {
  static Parser? _instance;

  static Parser get instance {
    _instance ??= Parser._init();
    return _instance!;
  }

  final sizeController = SizeController.instance;

  Parser._init();

  static const muscleGroups = {
    'chest': ['chest1', 'chest2'],
    'front_delts': ['shoulder1_2', 'shoulder2_2'],
    'side_delts': ['shoulder1_1', 'shoulder2_1'],
    'back_delts': ['shoulder3', 'shoulder4'],
    'obliques': ['obliques1', 'obliques2'],
    'abs': ['abs1', 'abs2', 'abs3', 'abs4', 'abs5', 'abs6', 'abs7', 'abs8'],
    'abductor': ['abductor1', 'abductor2'],
    'biceps': ['biceps1', 'biceps2'],
    'calves': ['calves1', 'calves2', 'calves3', 'calves4'],
    'forearm': ['forearm1', 'forearm2', 'forearm3', 'forearm4'],
    'glutes': ['glutes1', 'glutes2'],
    'harmstrings': ['harmstrings1', 'harmstrings2'],
    'lats': ['lats1', 'lats2', 'lats3', 'lats4'],
    'quads': ['quads1', 'quads2', 'quads3', 'quads4'],
    'trapezius': [
      'trapezius1',
      'trapezius2',
      'trapezius3',
      'trapezius4',
      'trapezius5'
    ],
    'triceps': ['triceps1', 'triceps2'],
    'adductors': ['adductors1', 'adductors2'],
    'lower_back': ['lower_back'],
    'neck': ['neck']
  };

  static Map<String, List<Muscle>> _mapCache = {};

  Set<Muscle> getMusclesByGroups(
      List<String> groupKeys, List<Muscle> muscleList) {
    final groupIds =
        groupKeys.expand((groupKey) => muscleGroups[groupKey] ?? []).toSet();
    return muscleList.where((muscle) => groupIds.contains(muscle.id)).toSet();
  }

  Future<List<Muscle>> svgToMuscleList(String body) async {
    if (_mapCache.containsKey(body)) {
      return _mapCache[body]!;
    }

    final svgMuscle =
        await rootBundle.loadString('${Constants.ASSETS_PATH}/$body');
    List<Muscle> muscleList = [];

    // Extract viewBox information
    final viewBoxRegExp = RegExp(Constants.VIEWBOX_REGEXP,
        multiLine: true, caseSensitive: false, dotAll: false);
    final viewBoxMatch = viewBoxRegExp.firstMatch(svgMuscle);

    double minX = 0, minY = 0, width = 0, height = 0;
    if (viewBoxMatch != null) {
      minX = double.parse(viewBoxMatch.group(1)!);
      minY = double.parse(viewBoxMatch.group(2)!);
      width = double.parse(viewBoxMatch.group(3)!);
      height = double.parse(viewBoxMatch.group(4)!);

      // Set the initial map size based on viewBox
      sizeController.setInitialSize(Size(width, height));
    }

    final regExp = RegExp(Constants.MAP_REGEXP,
        multiLine: true, caseSensitive: false, dotAll: false);

    regExp.allMatches(svgMuscle).forEach((muscleData) {
      final id = muscleData.group(1)!;
      final title = muscleData.group(2)!;
      var path = parseSvgPath(muscleData.group(3)!);

      // Apply viewBox transformation if present
      if (viewBoxMatch != null) {
        path = path.transform((Matrix4.identity()
              ..translate(-minX, -minY)
              ..scale(width / sizeController.mapSize.width,
                  height / sizeController.mapSize.height))
            .storage);
      }

      sizeController.addBounds(path.getBounds());

      final muscle = Muscle(id: id, title: title, path: path);
      muscleList.add(muscle);

      final group = muscleGroups.entries
          .firstWhereOrNull((entry) => entry.value.contains(id));
      if (group != null) {
        for (var groupId in group.value) {
          if (groupId != id) {
            final groupMuscle = Muscle(id: groupId, title: title, path: path);
            muscleList.add(groupMuscle);
          }
        }
      }
    });

    _mapCache[body] = muscleList;
    return muscleList;
  }
}
