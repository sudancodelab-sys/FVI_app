import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../l10n/app_localizations.dart';
import '../data/admin.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';
import 'lock.dart';

/// A6: the backup, the WhatsApp number and the security of the app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final admin = AdminScope.of(context);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8, right: 4, left: 4),
          child: Text(text, style: const TextStyle(color: Fvi.muted, fontWeight: FontWeight.w800)),
        );
    Widget icon(IconData i, Color color, Color soft) => Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
          child: Icon(i, color: color),
        );
    Widget tile(Widget leading, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: leading,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: Fvi.muted)),
          trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_left_rounded)),
          onTap: onTap,
        );
    final development = admin.keys?.isDevelopment ?? true;
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        heading(t.backupSection),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            tile(icon(Icons.cloud_upload_outlined, Fvi.navy, Fvi.navySoft), t.makeBackup,
                subtitle: t.makeBackupSub, onTap: () => makeBackup(context)),
            const Divider(height: 1, color: Fvi.line),
            tile(icon(Icons.settings_backup_restore_rounded, Fvi.navy, Fvi.navySoft), t.restore,
                subtitle: t.restoreSub, onTap: () => restoreBackup(context)),
          ]),
        ),
        heading(t.whatsappSection),
        Panel(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(children: [
            tile(icon(Icons.chat_outlined, Fvi.whatsapp, Fvi.greenSoft), t.whatsappNumber,
                subtitle: phoneNumber(admin.whatsapp),
                trailing: OutlinedButton(onPressed: () => _changeWhatsapp(context), child: Text(t.change))),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Fvi.navyTint, borderRadius: BorderRadius.circular(14)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Fvi.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(t.whatsappNote, style: const TextStyle(color: Fvi.text, height: 1.6))),
              ]),
            ),
          ]),
        ),
        heading(t.security),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(children: [
            FutureBuilder(
              future: LocalAuthentication().canCheckBiometrics.catchError((_) => false),
              builder: (context, snap) => tile(icon(Icons.fingerprint, Fvi.navy, Fvi.navySoft), t.biometricLogin,
                  trailing: Switch(value: admin.biometrics, onChanged: snap.data == true ? admin.setBiometrics : null)),
            ),
            const Divider(height: 1, color: Fvi.line),
            tile(icon(Icons.lock_outline_rounded, Fvi.navy, Fvi.navySoft), t.changePin,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const LockScreen(changing: true)))),
            const Divider(height: 1, color: Fvi.line),
            tile(icon(Icons.key_rounded, Fvi.orange, Fvi.orangeSoft), t.sealKey,
                subtitle: t.sealKeySub,
                trailing: development
                    ? Pill(t.sealDevelopment, color: Fvi.amber, background: Fvi.amberSoft)
                    : Pill('✓ ${t.sealOk}', color: Fvi.green, background: Fvi.greenSoft)),
            const Divider(height: 1, color: Fvi.line),
            tile(icon(Icons.logout_rounded, Fvi.muted, Fvi.navyTint), t.lockNow, onTap: admin.lock),
          ]),
        ),
        if (development) ...[
          const SizedBox(height: 14),
          Text(t.developmentBuild, textAlign: TextAlign.center, style: const TextStyle(color: Fvi.muted, fontSize: 12.5)),
        ],
      ]),
    );
  }

  Future<void> _changeWhatsapp(BuildContext context) async {
    final t = L10n.of(context);
    final admin = AdminScope.read(context);
    final field = TextEditingController(text: '+${admin.whatsapp}');
    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.whatsappNumber),
        content: TextField(controller: field, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(field.text), child: Text(t.save)),
        ],
      ),
    );
    if (number != null && number.replaceAll(RegExp(r'\D'), '').length >= 8) await admin.setWhatsapp(number);
  }
}
