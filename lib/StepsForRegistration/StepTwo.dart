import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StepTwo extends StatelessWidget {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Этап 1: Имя и Фамилия'),
        TextFormField(
          controller: firstNameController,
          decoration: InputDecoration(labelText: 'Имя'),
        ),
        TextFormField(
          controller: lastNameController,
          decoration: InputDecoration(labelText: 'Фамилия'),
        ),
      ],
    );
  }
}