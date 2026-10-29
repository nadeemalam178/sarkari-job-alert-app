import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const ServerConfigDialog({super.key, required this.onSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    StorageService.getServerUrl().then((url) {
      if (mounted) {
        setState(() {
          _controller.text = url;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Backend Server Settings',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your Flask backend API base URL. Use localhost for Web, 10.0.2.2 for Android Emulator, or your local Wi-Fi IP for phone debugging.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://localhost:5000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('localhost:5000', style: TextStyle(fontSize: 11)),
                      onPressed: () => _controller.text = 'http://localhost:5000',
                    ),
                    ActionChip(
                      label: const Text('10.0.2.2:5000', style: TextStyle(fontSize: 11)),
                      onPressed: () => _controller.text = 'http://10.0.2.2:5000',
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
          onPressed: () async {
            await StorageService.setServerUrl(_controller.text.trim());
            widget.onSaved();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save & Reconnect'),
        ),
      ],
    );
  }
}
