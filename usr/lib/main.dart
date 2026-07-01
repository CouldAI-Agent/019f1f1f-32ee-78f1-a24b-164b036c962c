import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const PhotoEditorApp());
}

class PhotoEditorApp extends StatelessWidget {
  const PhotoEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Фоторедактор',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(imageFile: pickedFile),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фоторедактор'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Выберите фото для начала',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.image),
              label: const Text('Галерея'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Камера'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final XFile imageFile;

  const EditorScreen({super.key, required this.imageFile});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  
  // A simple color matrix to simulate basic adjustments
  List<double> get _colorMatrix {
    // This is a very simplified simulation of adjustments using ColorFiltered.
    // Real adjustments would require an image processing library or more complex shaders.
    // We use a base matrix and multiply it by contrast/brightness factors.
    
    // Base identity matrix
    final matrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // Apply brightness and contrast
    double t = (1.0 - _contrast) / 2.0 * 255;
    for (int i = 0; i < 3; i++) {
      matrix[i * 6] = _contrast; // Diagonal scaling
      matrix[i * 5 + 4] = t + (_brightness * 255); // Offset
    }

    return matrix;
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(widget.imageFile.path, fit: BoxFit.contain);
    } else {
      return Image.file(File(widget.imageFile.path), fit: BoxFit.contain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В этой демо-версии сохранение недоступно.')),
              );
            },
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_colorMatrix),
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSlider('Яркость', _brightness, -1.0, 1.0, (val) => setState(() => _brightness = val)),
                  _buildSlider('Контраст', _contrast, 0.0, 2.0, (val) => setState(() => _contrast = val)),
                  // Saturation omitted for simplicity in this basic demo matrix
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toStringAsFixed(1), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
