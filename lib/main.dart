import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/chores_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/roommate_provider.dart';
import 'screens/login_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/chores_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/shopping_list_screen.dart';

final ThemeData customTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey[50],
  cardTheme: CardTheme(
    elevation: 12,
    shadowColor: Colors.blue.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.blue.shade800,
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.blue.shade800,
    ),
    iconTheme: IconThemeData(color: Colors.blue.shade800),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 8,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.blue.shade600,
    ),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('userBox');
  await Hive.openBox('choresBox');
  await Hive.openBox('billsBox');
  await Hive.openBox('remindersBox');
  await Hive.openBox('expensesBox');
  await Hive.openBox('shoppingBox');
  runApp(DormMateApp());
}

class DormMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RoommateProvider()),
        ChangeNotifierProvider(
          create:
              (context) => ChoresProvider(
                Provider.of<RoommateProvider>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(create: (context) => BillsProvider()),
        ChangeNotifierProvider(create: (context) => RemindersProvider()),
        ChangeNotifierProvider(create: (context) => ShoppingProvider()),
        ChangeNotifierProvider(create: (context) => ExpensesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DormMate',
        theme: customTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/signup': (context) => SignUpScreen(),
          '/chores': (context) => ChoresScreen(),
          '/bills': (context) => BillsScreen(),
          '/reminders': (context) => RemindersScreen(),
          '/settings': (context) => SettingsScreen(),
          '/edit_profile': (context) => EditProfileScreen(),
          '/shopping_list': (context) => ShoppingListScreen(),
          '/expenses': (context) => ExpensesScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleProfileTap() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildProfileDrawer(BuildContext context) {
    final userBox = Hive.box('userBox');
    final currentUser = userBox.get('currentUser');

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blue),
            ),
            accountName: Text(
              currentUser != null ? currentUser['username'].toString() : 'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              currentUser != null
                  ? currentUser['email'].toString()
                  : 'email@example.com',
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              userBox.delete('currentUser');
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'DormMate',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground:
                Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade400],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.person, color: Colors.blue.shade800),
              onPressed: () => _handleProfileTap(),
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.all(20),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildFeatureCard(
                context,
                'Chores',
                Icons.cleaning_services,
                Colors.green,
                'chores',
              ),
              _buildFeatureCard(
                context,
                'Bills',
                Icons.attach_money,
                Colors.blue,
                'bills',
              ),
              _buildFeatureCard(
                context,
                'Reminders',
                Icons.notifications,
                Colors.orange,
                'reminders',
              ),
              _buildFeatureCard(
                context,
                'Shopping List',
                Icons.shopping_cart,
                Colors.red,
                'shopping_list',
              ),
              _buildFeatureCard(
                context,
                'Expenses',
                Icons.account_balance_wallet,
                Colors.purple,
                'expenses',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Hero(
      tag: route,
      child: Card(
        elevation: 12,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/$route'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withOpacity(0.2),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
