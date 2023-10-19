import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LegendOverlay extends StatefulWidget {
  @override
  _LegendOverlayState createState() => _LegendOverlayState();
}

class _LegendOverlayState extends State<LegendOverlay> {
  PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
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
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  LegendPage(
                    color: Colors.blue,
                    label: 'Метки с синим цветом - бильярд',
                  ),
                  LegendPage(
                    color: Colors.red,
                    label: 'Метки с красным цветом - настольный теннис',
                  ),
                  // Добавьте другие разделы как страницы
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    if (_pageController.page! > 0) {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    if (_pageController.page! < 2) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegendPage extends StatelessWidget {
  final Color color;
  final String label;

  LegendPage({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            color: color,
          ),
        ),
        SizedBox(height: 8.0),
        Text(label),
      ],
    );
  }
}
