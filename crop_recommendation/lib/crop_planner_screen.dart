import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'storage_service.dart';

class CropPlannerScreen extends StatefulWidget {
  final String cropName;

  const CropPlannerScreen({Key? key, required this.cropName}) : super(key: key);

  @override
  _CropPlannerScreenState createState() => _CropPlannerScreenState();
}

class _CropPlannerScreenState extends State<CropPlannerScreen> {
  final TextEditingController _plantingDateController = TextEditingController();
  final TextEditingController _harvestingDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final StorageService _storageService = StorageService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadPlannerData();
    _initSpeechToText();
  }

  void _initSpeechToText() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );
    if (!available) {
      print('The device does not support speech recognition.');
    }
  }

  Future<void> _loadPlannerData() async {
    final data = await _storageService.readData('crop_planner_${widget.cropName}');
    if (data != null && mounted) {
      setState(() {
        _plantingDateController.text = data['plantingDate'] ?? '';
        _harvestingDateController.text = data['harvestingDate'] ?? '';
        _notesController.text = data['notes'] ?? '';
      });
    }
  }

  Future<void> _savePlannerData() async {
    final data = {
      'plantingDate': _plantingDateController.text,
      'harvestingDate': _harvestingDateController.text,
      'notes': _notesController.text,
    };
    await _storageService.saveData('crop_planner_${widget.cropName}', data);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planner data saved!')),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    // Harvest can't be before planting, so use the planting date as the lower bound.
    final DateTime firstDate = controller == _harvestingDateController
        ? (DateTime.tryParse(_plantingDateController.text) ?? DateTime(2000))
        : DateTime(2000);
    DateTime initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) setState(() => _isListening = status == 'listening');
        },
        onError: (errorNotification) => print('Speech error: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              _notesController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _plantingDateController.dispose();
    _harvestingDateController.dispose();
    _notesController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Planner for ${widget.cropName}', overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/0ecf5266f293425e38e96ce149f94145.jpg'), // Background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5), // Translucent overlay
          ),
          SafeArea(
            child: Center(
            // Keep the form a readable width on tablets/desktop/web.
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextFormField(
                  controller: _plantingDateController,
                  readOnly: true,
                  style: TextStyle(color: Colors.white), // Set text color to white for visibility
                  decoration: InputDecoration(
                    labelText: 'Planting Date',
                    labelStyle: TextStyle(color: Colors.white70), // Set label color
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white), // Set icon color
                      onPressed: () => _selectDate(context, _plantingDateController),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _harvestingDateController,
                  readOnly: true,
                  style: TextStyle(color: Colors.white), // Set text color to white for visibility
                  decoration: InputDecoration(
                    labelText: 'Harvesting Date',
                    labelStyle: TextStyle(color: Colors.white70), // Set label color
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white), // Set icon color
                      onPressed: () => _selectDate(context, _harvestingDateController),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _notesController,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white), // Set text color to white for visibility
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Colors.white70), // Set label color
                    hintText: 'Enter your notes here...',
                    hintStyle: TextStyle(color: Colors.white54), // Set hint text color
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white), // Set icon color
                      onPressed: _isListening ? _stopListening : _startListening,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _savePlannerData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Set button background color
                    foregroundColor: Colors.white, // Set button text color
                  ),
                  child: const Text('Save Planner'),
                ),
              ],
            ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}