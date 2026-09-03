import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/repositories/session/session_repository.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/routing/routes.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/requests/view_models/request_list_viewmodel.dart';
import 'package:provider/provider.dart';

import 'request_card.dart';
import 'request_filter_sheet.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key, required this.viewModel});

  final RequestListViewModel viewModel;

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      widget.viewModel.loadMore.execute();
    }
  }

  Future<void> _openFilters() async {
    final user = context.read<SessionRepository>().currentUser;
    if (user == null) return;

    final result = await RequestFilterSheet.show(
      context,
      initial: widget.viewModel.filters,
      categories: widget.viewModel.categoryOptions,
      currentUser: user,
    );
    if (result != null) widget.viewModel.applyFilters(result);
  }

  Future<void> _openRequest(Request request) async {
    final updated = await context.pushNamed<RequestDetail>(
      RouteNames.requestDetail,
      pathParameters: {'id': '${request.id}'},
      extra: request,
    );

    if (updated != null) widget.viewModel.replace(updated.request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilters,
            icon: ListenableBuilder(
              listenable: viewModel,
              builder: (context, child) => Badge(
                isLabelVisible: viewModel.isFiltering,
                backgroundColor: theme.colorScheme.primary,
                child: child,
              ),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: viewModel.search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search title and description',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: ListenableBuilder(
                  listenable: _searchController,
                  builder: (context, _) => _searchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            viewModel.search('');
                          },
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: viewModel.load,
              builder: (context, child) {
                if (viewModel.load.running && viewModel.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.load.error && viewModel.isEmpty) {
                  return ErrorIndicator(
                    title: 'Could not load requests',
                    error: viewModel.load.exception,
                    onPressed: viewModel.load.execute,
                  );
                }
                return child!;
              },
              child: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => Column(
                  children: [
                    _ResultBar(viewModel: viewModel),
                    const Divider(),
                    Expanded(
                      child: viewModel.isEmpty
                          ? EmptyIndicator(
                              icon: Icons.inbox_outlined,
                              title: viewModel.isFiltering
                                  ? 'No matching requests'
                                  : 'No requests yet',
                              message: viewModel.isFiltering
                                  ? 'Try widening or clearing your filters.'
                                  : 'Tap "New request" to raise the first one.',
                            )
                          : RefreshIndicator(
                              onRefresh: viewModel.load.execute,
                              child: ListView.separated(
                                controller: _scrollController,
                                // Keeps pull-to-refresh working on short lists.
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 96),
                                itemCount: viewModel.items.length + 1,
                                separatorBuilder: (_, _) => const Divider(),
                                itemBuilder: (context, index) {
                                  if (index == viewModel.items.length) {
                                    return _ListFooter(viewModel: viewModel);
                                  }

                                  final request = viewModel.items[index];
                                  return RequestCard(
                                    request: request,
                                    onTap: () => _openRequest(request),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final created = await context.pushNamed<RequestDetail>(
            RouteNames.newRequest,
          );
          if (created != null) viewModel.load.execute();
        },
        tooltip: 'New request',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.viewModel});

  final RequestListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${viewModel.total} '
              '${viewModel.total == 1 ? 'request' : 'requests'}'
              ' · ${viewModel.filters.sort.label}',
              style: style,
            ),
          ),
          if (viewModel.isFiltering)
            TextButton.icon(
              onPressed: viewModel.clearFilters,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.viewModel});

  final RequestListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel.loadMore,
      builder: (context, _) {
        if (viewModel.loadMore.running) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!viewModel.hasMore && viewModel.items.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'End of list',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
