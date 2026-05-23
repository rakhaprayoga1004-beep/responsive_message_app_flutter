// lib/widgets/window_resizer_shortcut.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/screen_presets.dart';

// Extension untuk menampilkan panel resizer
class WindowResizerExtension {
  static GlobalKey<NavigatorState>? navigatorKey;
  
  static void showResizerPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            height: MediaQuery.of(dialogContext).size.height * 0.8,
            child: const WindowResizerPanel(),
          ),
        );
      },
    );
  }
}

// Panel untuk mengatur ukuran window
class WindowResizerPanel extends StatefulWidget {
  const WindowResizerPanel({super.key});

  @override
  State<WindowResizerPanel> createState() => _WindowResizerPanelState();
}

class _WindowResizerPanelState extends State<WindowResizerPanel> {
  late ScreenPreset _currentPreset;
  final TextEditingController _customWidthController = TextEditingController();
  final TextEditingController _customHeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPreset = ScreenPreset.presets[2];
    _customWidthController.text = _currentPreset.width.toString();
    _customHeightController.text = _currentPreset.height.toString();
  }

  @override
  void dispose() {
    _customWidthController.dispose();
    _customHeightController.dispose();
    super.dispose();
  }

  Future<void> _resizeWindow(ScreenPreset preset) async {
    await windowManager.setSize(Size(preset.width, preset.height));
    setState(() {
      _currentPreset = preset;
      _customWidthController.text = preset.width.toString();
      _customHeightController.text = preset.height.toString();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Window diubah ke ${preset.name} (${preset.width.toInt()}×${preset.height.toInt()})'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _resizeCustom() async {
    double width = double.tryParse(_customWidthController.text) ?? 375;
    double height = double.tryParse(_customHeightController.text) ?? 667;
    
    if (width < 320) width = 320;
    if (height < 480) height = 480;
    
    await _resizeWindow(ScreenPreset.customPreset(width, height));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Ukuran Window'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Tutup',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📱 Pilih Device',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: ScreenPreset.presets.length,
            itemBuilder: (context, index) {
              final preset = ScreenPreset.presets[index];
              final isSelected = _currentPreset.name == preset.name && 
                                _currentPreset.width == preset.width;
              
              return ElevatedButton.icon(
                onPressed: () => _resizeWindow(preset),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue[700] : Colors.white,
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                ),
                icon: Text(preset.icon, style: const TextStyle(fontSize: 20)),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(preset.name, style: const TextStyle(fontSize: 11)),
                    Text(
                      '${preset.width.toInt()}×${preset.height.toInt()}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(height: 24),
          
          const Text(
            '⚙️ Ukuran Custom',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Lebar',
                    border: OutlineInputBorder(),
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              const Text('×', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Tinggi',
                    border: OutlineInputBorder(),
                    suffixText: 'px',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _resizeCustom,
            icon: const Icon(Icons.aspect_ratio),
            label: const Text('Terapkan Ukuran Custom'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          
          const Divider(height: 24),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('• Gunakan panel ini untuk menguji UI di berbagai ukuran layar'),
                Text('• Pilih device yang sesuai dengan target pengguna'),
                Text('• Perhatikan perubahan UI yang responsif'),
                Text('• Tekan tombol close untuk kembali ke aplikasi'),
                Text('• Tekan F2 untuk membuka panel ini dari halaman mana pun'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shortcut keyboard untuk membuka window resizer
class WindowResizerShortcut extends StatelessWidget {
  final Widget child;
  
  const WindowResizerShortcut({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): () {
          WindowResizerExtension.showResizerPanel(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}