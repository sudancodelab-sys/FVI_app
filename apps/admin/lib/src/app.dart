import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'data/admin.dart';
import 'data/catalog.dart';
import 'screens/home.dart';
import 'screens/lock.dart';
import 'theme.dart';

/// The admin app (docs/REQUIREMENTS.md 4): one phone, in Arabic as in its
/// approved designs, locked with a PIN or the phone's fingerprint.
class AdminApp extends StatefulWidget {
  const AdminApp({super.key, this.admin, this.catalog});

  final Admin? admin;
  final Catalog? catalog;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final admin = widget.admin ?? (Admin()..load());
  late final Future<Catalog> catalog = widget.catalog != null ? Future.value(widget.catalog) : Catalog.load();

  @override
  void dispose() {
    if (widget.admin == null) admin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AdminScope(
        admin: admin,
        child: MaterialApp(
          onGenerateTitle: (context) => L10n.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: Fvi.theme(),
          locale: const Locale('ar'),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FutureBuilder(
            future: catalog,
            builder: (context, snap) =>
                snap.hasData ? _Gate(catalog: snap.data!) : const Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
        ),
      );
}

/// The lock first, every time the app opens or comes back; then the app.
class _Gate extends StatefulWidget {
  const _Gate({required this.catalog});

  final Catalog catalog;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) AdminScope.read(context).lock();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AdminScope.of(context);
    if (!admin.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (admin.keys == null) return const SetupScreen();
    if (!admin.unlocked) return const LockScreen();
    return HomeScreen(catalog: widget.catalog);
  }
}
