import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class HomePage extends StatelessWidget {
  final _tab1navigatorKey = GlobalKey<NavigatorState>();
  final _tab3navigatorKey = GlobalKey<NavigatorState>();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: const Hexadecimal(),
          icon: Icons.home,
          title: 'Home',
          navigatorkey: _tab1navigatorKey,
        ),
        // PersistentTabItem(
        //   tab: const SettingsPage(),
        //   icon: Icons.settings,
        //   title: 'Settings',
        //   navigatorkey: _tab3navigatorKey,
        // ),
      ],
    );
  }
}

class TestSelection extends StatelessWidget {
  const TestSelection({super.key});

  @override
  Widget build(BuildContext context) {
    // final session = Provider.of<SessionChanges>(context);
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Text('GhostPeerShare', style: TextStyle(fontSize: 20)),
              ],
            )
          ),
          ListTile(
            title: const Text('KLD'),
            onTap: () {
              // session.clearLogs();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ListDoubleAddition(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class Hexadecimal extends StatefulWidget {
  const Hexadecimal({super.key});

  @override
  HexidecimalOpPage createState() {
    return HexidecimalOpPage();
  }
}

class HexidecimalOpPage extends State<Hexadecimal> {
  final xP = TextEditingController();
  final yP = TextEditingController();
  final xEncrypted = GlobalKey<FormFieldState>();
  final yEncrypted = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hexadecimal')),
      drawer: const TestSelection(),
      body: hexOp(context, xP, yP, xEncrypted, yEncrypted));
  }
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    xP.dispose();
    yP.dispose();
    super.dispose();
  }
}
