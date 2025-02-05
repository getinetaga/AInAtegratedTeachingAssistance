import 'package:flutter/material.dart';
import 'package:intelligrade/controller/main_controller.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const AppHeader({super.key, required this.title});

  static MainController controller = MainController();

  @override
  _AppHeaderState createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.blueGrey,
            width: 0.5,
          ),
        ),
      ),
      child: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.deepPurple[200],
          ),
        ),
        leading: const Icon(Icons.computer_outlined),
        actions: [
          FutureBuilder<bool>(
            future: AppHeader.controller.isUserLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return IconButton(
                  icon: const Icon(Icons.error),
                  onPressed: () {},
                );
              } else {
                bool isLoggedIn = snapshot.data ?? false;
                return Tooltip(
                  message: isLoggedIn ? 'Logout' : 'Login',
                  child: IconButton(
                    icon: isLoggedIn
                        ? const Icon(Icons.logout)
                        : const Icon(Icons.login),
                    onPressed: () async {
                      if (isLoggedIn) {
                        bool? confirmLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                  'Are you sure you want to logout of Moodle?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmLogout == true) {
                          AppHeader.controller.logoutFromMoodle();
                          setState(
                              () {}); // Repaint the page to show the login button
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Successfully logged out of Moodle',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          );
                        }
                      } else {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                );
              }
            },
          ),
          Tooltip(
            message: 'Settings',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
    );
  }
}
