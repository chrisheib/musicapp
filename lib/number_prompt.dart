import 'package:flutter/material.dart';
import 'package:musicapp/main.dart';

final myController = TextEditingController();

Future<String?> promptNumber(BuildContext context) async {
  var out = await showDialog<String?>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
          title: Row(children: [
        Expanded(
          child: TextField(
            controller: myController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter any data',
              hintText: 'Enter any data',
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            child: const Text('OK'),
            onPressed: () {
              var userData = myController.text;
              myController.text = '';
              FocusManager.instance.primaryFocus?.unfocus();
              logger.info(userData);
              Navigator.of(context).pop(userData);
            },
          ),
        )
      ]));
    },
  );
  // myController.dispose();
  return out;
}
