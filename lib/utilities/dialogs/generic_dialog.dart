import 'package:flutter/material.dart';

typedef DialogOptionBuilder<T> = Map<String, T?> Function();

//the reason its a questionable generic T is because it could be the case that it doesnt return any type an dit returns a null
// T represents a generic that can take any type
Future<T?> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder optionsBuilder,
}) {
  final options = optionsBuilder();

  return showDialog<T>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        // here using map we will go through all the keys and execute the function defined that takes in the key as parameter
        actions: options.keys.map(
          (optionsTitle) {
            final value = options[optionsTitle];
            return TextButton(
              onPressed: () {
                if (value != null) {
                  Navigator.of(context).pop(value);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(optionsTitle),
            );
          },
        ).toList(),
      );
    },
  );
}
