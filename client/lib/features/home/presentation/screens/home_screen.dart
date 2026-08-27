import 'package:app/core/network/api_client.dart';
import 'package:app/data/repositories/user_repository.dart';
import 'package:app/data/services/api/user_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    final apiClient = ApiClient(client: http.Client());
    final apiService = UserApiService(apiClient: apiClient);

    final repository = UserRepository(apiService: apiService);

    viewModel = HomeViewModel(userRepository: repository);

    viewModel.loadUsers();
  }

  @override
  void dispose() {
    viewModel.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
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
    );
  }
}
