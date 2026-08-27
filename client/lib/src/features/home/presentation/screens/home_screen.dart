import 'package:app/src/data/repositories/user_repository.dart';
import 'package:app/src/data/services/api/user_api.dart';
import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel viewModel;

  @override
  void initState() {
    super.initState();

    final repository = UserRepository(apiService: UserApiService());

    viewModel = HomeViewModel(userRepository: repository);

    viewModel.loadUsers();
  }

  static const IconData ticket = IconData(0xf916);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Show Snackbar',
            onPressed: () {},
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.err != null) {
            return Center(child: Text(viewModel.err!));
          }

          return ListView.builder(
            itemCount: viewModel.users.length,
            itemBuilder: (context, index) {
              final user = viewModel.users[index];

              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                subtitle: Text(user.email),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(ticket),
            icon: Icon(ticket),
            label: 'Requests',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // Called when this object is removed from the tree permanently.
  @override
  void dispose() {
    viewModel.dispose();

    super.dispose();
  }
}
