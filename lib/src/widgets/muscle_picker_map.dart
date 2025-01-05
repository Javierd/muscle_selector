import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/widgets/muscle_painter.dart';
import '../parser.dart';
import '../size_controller.dart';

class MusclePickerMap extends StatefulWidget {
  final double? width;
  final double? height;
  final String map;
  final Function(Set<Muscle> muscles) onChanged;
  final Color? strokeColor;
  final Color? selectedColor;
  final Color? dotColor;
  final bool? actAsToggle;
  final bool? isEditing;
  final Set<Muscle>? initialSelectedMuscles;
  final List<String>? initialSelectedGroups;

  const MusclePickerMap({
    Key? key,
    required this.map,
    required this.onChanged,
    this.width,
    this.height,
    this.strokeColor,
    this.selectedColor,
    this.dotColor,
    this.actAsToggle,
    this.isEditing = false,
    this.initialSelectedMuscles,
    this.initialSelectedGroups
  }) : super(key: key);

  @override
  MusclePickerMapState createState() => MusclePickerMapState();
}

class MusclePickerMapState extends State<MusclePickerMap> {
  final List<Muscle> _muscleList = [];
  final Set<Muscle> selectedMuscles = {};

  final _sizeController = SizeController.instance;
  Size? mapSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMuscleList();
    });
  }

  _loadMuscleList() async {
    final list = await Parser.instance.svgToMuscleList(widget.map);
    _muscleList.clear();
    setState(() {
      _muscleList.addAll(list);
      mapSize = _sizeController.mapSize;
      _initializeSelectedMuscles();
    });
  }

  void _initializeSelectedMuscles() {
    if (widget.initialSelectedMuscles != null) {
      selectedMuscles.addAll(widget.initialSelectedMuscles!);
    } else if (widget.initialSelectedGroups != null && widget.initialSelectedGroups!.isNotEmpty) {
      final groupMuscles = Parser.instance.getMusclesByGroups(widget.initialSelectedGroups!, _muscleList);
      selectedMuscles.addAll(groupMuscles);
    }
    widget.onChanged.call(selectedMuscles);
  }

  void clearSelect() {
    setState(() {
      selectedMuscles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var muscle in _muscleList) _buildStackItem(muscle),
      ],
    );
  }

  Widget _buildStackItem(Muscle muscle) {

    final bool isSelectable = muscle.id != 'human_body' && !widget.isEditing!;

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => {
        if (isSelectable) {
          (widget.actAsToggle ?? false) ? _toggleButton(muscle) : _useButton(muscle)
        }
      },
      child: CustomPaint(
        isComplex: true,
        foregroundPainter: MusclePainter(
          muscle: muscle,
          selected: selectedMuscles.any((selected) => selected.id == muscle.id),
          dotColor: widget.dotColor,
          selectedColor: widget.selectedColor,
          strokeColor: widget.strokeColor,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          constraints: BoxConstraints(
            maxWidth: mapSize?.width ?? 0,
            maxHeight: mapSize?.height ?? 0,
          ),
          alignment: Alignment.center,
        ),
      ),
    );
  }

  void _toggleButton(Muscle muscle) {
    setState(() {
      final group = Parser.muscleGroups.entries.firstWhere(
            (entry) => entry.value.contains(muscle.id),
        orElse: () => const MapEntry('', []),
      );

      if (group.key.isNotEmpty) {
        final relatedMuscles = _muscleList.where((m) => group.value.contains(m.id)).toList();
        if (relatedMuscles.every((m) => selectedMuscles.contains(m))) {
          selectedMuscles.removeAll(relatedMuscles);
        } else {
          selectedMuscles.addAll(relatedMuscles);
        }
      } else {
        if (selectedMuscles.contains(muscle)) {
          selectedMuscles.remove(muscle);
        } else {
          selectedMuscles.add(muscle);
        }
      }
      widget.onChanged.call(selectedMuscles);
    });
  }

  void _useButton(Muscle muscle) {
    setState(() {
      final group = Parser.muscleGroups.entries.firstWhere(
            (entry) => entry.value.contains(muscle.id),
        orElse: () => const MapEntry('', []),
      );

      if (group.key.isNotEmpty) {
        final relatedMuscles = _muscleList.where((m) => group.value.contains(m.id)).toList();
        selectedMuscles.addAll(relatedMuscles);
      } else {
        selectedMuscles.add(muscle);
      }
      widget.onChanged.call(selectedMuscles);
    });
  }
}
