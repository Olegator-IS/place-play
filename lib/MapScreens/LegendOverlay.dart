import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'MapsPage.dart';

class LegendOverlay extends StatefulWidget {
  @override
  _LegendOverlayState createState() => _LegendOverlayState();
}

class _LegendOverlayState extends State<LegendOverlay> {
  bool _isLegendVisible = true; // Начальное состояние - легенда видима

  void _toggleLegendVisibility() {
    setState(() {
      _isLegendVisible = !_isLegendVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(6.0, 0.0, 6.0, 100.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_isLegendVisible)
              Column(
                children: [
                  LegendItem(color: Colors.blue, label: 'Метки с синим цветом - бильярд'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.red, label: 'Метки с красным цветом - настольный теннис'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.green, label: 'Метки с красным цветом - большой теннис'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.purple, label: 'Метки с красным цветом - пэйнтболл'),
                  Divider(height: 8.0, color: Colors.black),
                  LegendItem(color: Colors.orange, label: 'Метки с красным цветом - страйкболл'),
                ],
              ),
            ElevatedButton(
              onPressed: _toggleLegendVisibility,
              child: Text(_isLegendVisible ? 'Скрыть легенду' : 'Показать легенду'),
            ),
          ],
        ),
      ),
    );
  }
}