import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/widgets/muscle_painter.dart';
import '../parser.dart';
import '../size_controller.dart';

class MuscleGroup {
  final String name;
  final Color? color;

  MuscleGroup({required this.name, this.color})
      : assert(Parser.muscleGroups.containsKey(name),
            'Muscle group not found $name');
}

class MuscleMap extends StatefulWidget {
  final double? width;
  final double? height;
  final Function(MuscleGroup muscle) onClicked;
  final Color? strokeColor;
  final Color? selectedColor;
  final Set<MuscleGroup>? muscles;

  const MuscleMap(
      {Key? key,
      required this.onClicked,
      this.width,
      this.height,
      this.strokeColor,
      this.selectedColor,
      this.muscles})
      : super(key: key);

  @override
  MuscleMapState createState() => MuscleMapState();
}

class MuscleMapState extends State<MuscleMap> {
  final List<Muscle> _muscleList = [];

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
    final list = await Parser.instance.svgToMuscleList(Maps.BODY);
    _muscleList.clear();
    setState(() {
      _muscleList.addAll(list);
      mapSize = _sizeController.mapSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size size = Size.zero;
        if (mapSize != null) {
          double aspectRatio = mapSize!.width/mapSize!.height;
          size = Size(constraints.maxWidth, constraints.maxWidth/aspectRatio);
        }

        return Stack(
          children: [
            for (var muscle in _muscleList) _buildStackItem(muscle, size),
          ],
        );
      },
    );
  }

  MuscleGroup? _getMuscleGroup(Muscle muscle) {
    String? groupName;
    for (MapEntry<String, List<String>> entry in Parser.muscleGroups.entries) {
      if (entry.value.contains(muscle.id)) {
        groupName = entry.key;
        break;
      }
    }

    if (groupName == null) return null;

    MuscleGroup? ret =
        widget.muscles?.firstWhereOrNull((m) => m.name == groupName);
    if (ret == null) {
      if (groupName != null) {
        ret = MuscleGroup(name: groupName);
      }
    }
    return ret;
  }

  Widget _buildStackItem(Muscle muscle, Size size) {
    final bool isSelectable = muscle.id != 'human_body';
    MuscleGroup? group = _getMuscleGroup(muscle);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: group == null
          ? null
          : () => {
                if (isSelectable) {widget.onClicked(group)}
              },
      child: CustomPaint(
        isComplex: true,
        foregroundPainter: MusclePainter(
          muscle: muscle,
          selected: widget.muscles == null
              ? false
              : widget.muscles!.any((m) => m.name == group?.name),
          selectedColor: group?.color ?? widget.selectedColor,
          strokeColor: widget.strokeColor,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          constraints: BoxConstraints(
            maxWidth: size.width,
            maxHeight: size.height,
          ),
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
