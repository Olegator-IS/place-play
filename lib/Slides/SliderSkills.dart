import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: SliderSkills()));
}

class SliderSkills extends StatefulWidget {
  @override
  _SliderSkills createState() => _SliderSkills();

  String _getSkillLevelDescription(double value) {
    if (value >= 0.0 && value <= 10.0) {
      return 'Не умею играть';
    } else if (value > 10.0 && value <= 30.0) {
      return 'Начинающий';
    } else if (value > 30.0 && value <= 50.0) {
      return 'Любитель';
    } else if (value > 50.0 && value <= 75.0) {
      return 'Полупрофессионал';
    } else if (value > 75.0 && value <= 100.0) {
      return 'Профессионал';
    }
    return '';
  }
}

class _SliderSkills extends State<SliderSkills> {
  double _skillLevel = 0.0;
  String _skillLevelDescription = 'Не умею играть';

  // Маппинг значений ползунка на уровни навыков
  final Map<double, String> _skillLevelMap = {
    0.0: 'Не умею играть',
    10.0: 'Начинающий',
    30.0: 'Любитель',
    50.0: 'Полупрофессионал',
    100.0: 'Профессионал',
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slider Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Уровень навыков: $_skillLevelDescription',
              style: TextStyle(fontSize: 20.0),
            ),
            Slider(
              value: _skillLevel,
              onChanged: (newValue) {
                setState(() {
                  _skillLevel = newValue;

                  // Находим ближайшее значение из маппинга
                  double closestValue = _skillLevelMap.keys.reduce((a, b) {
                    return (a - newValue).abs() < (b - newValue).abs() ? a : b;
                  });

                  _skillLevelDescription = _skillLevelMap[closestValue] ?? '';
                });
              },
              min: 0.0,
              max: 100.0,
              divisions: 100,
              label: _skillLevel.toStringAsFixed(2),
            ),
          ],
        ),
      ),
    );
  }
}
