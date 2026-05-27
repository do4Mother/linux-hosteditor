import 'package:flutter/material.dart';

import '../models/host.dart';
import '../theme/app_colors.dart';
import 'dot.dart';
import 'filled_btn.dart';

class HostDialog extends StatefulWidget {
  final Host? host;
  final List<Host> existing;
  const HostDialog({super.key, required this.host, required this.existing});

  @override
  State<HostDialog> createState() => _HostDialogState();
}

class _HostDialogState extends State<HostDialog> {
  late final TextEditingController hostname;
  late final TextEditingController target;
  late final TextEditingController note;
  late Env env;
  bool touched = false;

  @override
  void initState() {
    super.initState();
    final h = widget.host;
    hostname = TextEditingController(text: h?.hostname ?? '');
    target = TextEditingController(text: h?.target ?? '');
    note = TextEditingController(text: h?.note ?? '');
    env = h?.env ?? Env.dev;
  }

  @override
  void dispose() {
    hostname.dispose();
    target.dispose();
    note.dispose();
    super.dispose();
  }

  bool get hostnameValid =>
      RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$', caseSensitive: false).hasMatch(hostname.text);
  bool get targetValid => target.text.isNotEmpty;
  bool get duplicate => widget.host == null && widget.existing.any((h) => h.hostname == hostname.text && h.env == env);
  bool get canSave => hostnameValid && targetValid && !duplicate;

  void _submit() {
    setState(() => touched = true);
    if (!canSave) return;
    final base =
        widget.host ?? Host(id: DateTime.now().millisecondsSinceEpoch, hostname: '', target: '', env: Env.dev, active: true, updated: 'just now');
    Navigator.of(context).pop(base.copyWith(hostname: hostname.text.trim(), target: target.text.trim(), env: env, note: note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.host != null;
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit host' : 'New host redirect',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.onSurface),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: hostname,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Hostname',
                  hintText: 'e.g. api.acme.com',
                  prefixIcon: const Icon(Icons.public),
                  helperText: 'The domain name to intercept',
                  errorText: touched && !hostnameValid
                      ? 'Enter a valid hostname (e.g. example.com)'
                      : (touched && duplicate ? 'A host with this name already exists in this environment' : null),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: target,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Target IP',
                  hintText: '127.0.0.1',
                  prefixIcon: const Icon(Icons.arrow_forward),
                  helperText: 'IP address or hostname',
                  errorText: touched && !targetValid ? 'Target is required' : null,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Environment', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    for (final e in Env.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => env = e),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: env == e ? AppColors.secondaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Dot(color: e.accent, size: 8),
                                const SizedBox(width: 8),
                                Text(
                                  e.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: env == e ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What this redirect is for',
                  prefixIcon: Icon(Icons.notes),
                  helperText: 'Helps your future self remember',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledBtn(label: isEdit ? 'Save changes' : 'Add host', onTap: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
