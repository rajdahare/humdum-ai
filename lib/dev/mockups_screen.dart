import 'dart:ui' as ui;
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../screens/home_screen.dart';

class MockupsScreen extends StatefulWidget {
  const MockupsScreen({super.key});

  @override
  State<MockupsScreen> createState() => _MockupsScreenState();
}

class _MockupsScreenState extends State<MockupsScreen> {
  final _repaintKey = GlobalKey();

  Future<void> _capture(String name) async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(bytes);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${file.path}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mockup Generator')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('iPhone 15'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _capture('mockup_iphone15'),
            ),
          ),
          RepaintBoundary(
            key: _repaintKey,
            child: const SizedBox(
              height: 700,
              child: DeviceFrame(
                device: Devices.ios.iPhone13, // close enough visual frame
                screen: HomeScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Pixel 8'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _capture('mockup_pixel8'),
            ),
          ),
          const SizedBox(
            height: 700,
            child: DeviceFrame(
              device: Devices.android.onePlus8Pro, // similar modern Android frame
              screen: HomeScreen(),
            ),
          ),
        ],
      ),
    );
  }
}


