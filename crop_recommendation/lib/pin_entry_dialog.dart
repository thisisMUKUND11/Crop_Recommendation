import 'package:flutter/material.dart';

class PinEntryDialog extends StatefulWidget {
  @override
  _PinEntryDialogState createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter PIN'),
      content: TextField(
        controller: _pinController,
        decoration: InputDecoration(labelText: '4-digit PIN'),
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _pinController.text);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}