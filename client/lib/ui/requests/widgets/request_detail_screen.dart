import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/services/api/api_exception.dart';
import 'package:app/domain/models/comment.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request.dart';
import 'package:app/domain/models/request_history.dart';
import 'package:app/domain/models/request_history_action.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/ui/core/themes/semantic_colors.dart';
import 'package:app/ui/core/ui/content_column.dart';
import 'package:app/ui/core/ui/detail_row.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/core/ui/status_chip.dart';
import 'package:app/ui/core/ui/user_avatar.dart';
import 'package:app/ui/requests/view_models/request_detail_viewmodel.dart';
import 'package:app/utils/date_format.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.viewModel});

  final RequestDetailViewModel viewModel;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.mutations.addListener(_onMutationChanged);
  }

  @override
  void dispose() {
    widget.viewModel.mutations.removeListener(_onMutationChanged);
    super.dispose();
  }

  void _onMutationChanged() {
    if (!mounted) return;

    for (final command in [
      widget.viewModel.changeStatus,
      widget.viewModel.changePriority,
      widget.viewModel.assign,
      widget.viewModel.addComment,
    ]) {
      if (!command.error) continue;

      final error = command.exception;
      command.clearResult();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error == null ? 'That did not work.' : messageFor(error),
            ),
          ),
        );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return PopScope<RequestDetail?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.pop(viewModel.detail);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Request #${viewModel.requestId}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(viewModel.detail),
          ),
        ),
        body: ContentColumn(
          child: ListenableBuilder(
            listenable: viewModel.load,
            builder: (context, child) {
              // A preview from the list means there is already something to show
              // while the full record loads.
              if (viewModel.load.running && viewModel.detail == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.load.error && viewModel.detail == null) {
                return ErrorIndicator(
                  title: 'Could not load this request',
                  error: viewModel.load.exception,
                  onPressed: viewModel.load.execute,
                );
              }
              return child!;
            },
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final detail = viewModel.detail;
                if (detail == null) return const SizedBox.shrink();

                return _DetailBody(detail: detail, viewModel: viewModel);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.viewModel});

  final RequestDetail detail;
  final RequestDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = detail.request;

    return Column(
      children: [
        ListenableBuilder(
          listenable: viewModel.mutations,
          builder: (context, _) => viewModel.isMutating
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.load.execute,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(request.status),
                          PriorityChip(request.priority),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        request.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SectionHeader('Details'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      DetailRow(
                        label: 'RequestCategory',
                        child: Text(request.category.name),
                      ),
                      DetailRow(
                        label: 'Requester',
                        child: _PersonLine(user: request.requester),
                      ),
                      DetailRow(
                        label: 'Assignee',
                        child: request.assignee == null
                            ? Text(
                                'Unassigned',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              )
                            : _PersonLine(user: request.assignee!),
                      ),
                      DetailRow(
                        label: 'Created',
                        child: Text(formatDateTime(request.createdAt)),
                      ),
                      if (request.resolvedAt != null)
                        DetailRow(
                          label: 'Resolved',
                          child: Text(formatDateTime(request.resolvedAt!)),
                        ),
                      if (request.closedAt != null)
                        DetailRow(
                          label: 'Closed',
                          child: Text(formatDateTime(request.closedAt!)),
                        ),
                    ],
                  ),
                ),

                if (viewModel.canManage) ...[
                  const SectionHeader('Actions'),
                  _Actions(detail: detail, viewModel: viewModel),
                ],

                SectionHeader('Comments (${detail.comments.length})'),
                if (viewModel.isPreviewOnly)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (detail.comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No comments yet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final comment in detail.comments)
                    _CommentTile(comment: comment),

                SectionHeader('History (${detail.history.length})'),
                for (final entry in detail.history)
                  _HistoryTile(
                    entry: entry,
                    request: request,
                    knownUsers: viewModel.assignableUsers,
                    categories: {
                      for (final c in viewModel.categoryOptions) c.id: c.name,
                    },
                  ),
              ],
            ),
          ),
        ),
        _CommentComposer(viewModel: viewModel),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.detail, required this.viewModel});

  final RequestDetail detail;
  final RequestDetailViewModel viewModel;

  Future<void> _pickAssignee(BuildContext context) async {
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Assign to'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Unassign'),
              // `null` is a legitimate choice here, so the sheet returns a
              // sentinel to tell "chose nobody" from "dismissed the sheet".
              onTap: () => Navigator.of(context).pop(#unassign),
            ),
            const Divider(),
            for (final user in viewModel.assignableUsers)
              ListTile(
                leading: UserAvatar(user, size: 32),
                title: Text(user.name),
                subtitle: Text(user.role.label),
                selected: detail.request.assignee?.id == user.id,
                onTap: () => Navigator.of(context).pop(user),
              ),
          ],
        ),
      ),
    );

    if (selected == null) return;
    await viewModel.assign.execute(selected is User ? selected.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final request = detail.request;

    return ListenableBuilder(
      listenable: viewModel.mutations,
      builder: (context, _) {
        final busy = viewModel.isMutating;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final next in request.status.nextOptions)
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => viewModel.changeStatus.execute(next),
                      child: Text(
                        next == RequestStatus.open && request.status.isSettled
                            ? 'Reopen'
                            : 'Mark ${next.label}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => _pickAssignee(context),
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: Text(
                        request.assignee == null ? 'Assign' : 'Reassign',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PopupMenuButton<Priority>(
                      enabled: !busy,
                      onSelected: viewModel.changePriority.execute,
                      itemBuilder: (context) => [
                        for (final priority in Priority.values)
                          PopupMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                PriorityChip(priority, dense: true),
                                if (priority == request.priority) ...[
                                  const Spacer(),
                                  const Icon(Icons.check, size: 16),
                                ],
                              ],
                            ),
                          ),
                      ],
                      child: IgnorePointer(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : () {},
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Priority'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        UserAvatar(user, size: 24),
        const SizedBox(width: 8),
        Flexible(child: Text(user.name, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(
          user.role.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(comment.author, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRelative(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.request,
    required this.knownUsers,
    required this.categories,
  });

  final RequestHistory entry;
  final Request request;
  final List<User> knownUsers;
  final Map<int, String> categories;

  String _describe() => switch (entry.action) {
    RequestHistoryAction.created => 'created the request',
    RequestHistoryAction.statusChanged =>
      'moved it from ${_status(entry.oldValue)} to ${_status(entry.newValue)}',
    RequestHistoryAction.priorityChanged =>
      'changed priority from ${_priority(entry.oldValue)} to ${_priority(entry.newValue)}',
    RequestHistoryAction.assigned => 'assigned it to ${_user(entry.newValue)}',
    RequestHistoryAction.unassigned => 'removed the assignee',
    RequestHistoryAction.categoryChanged =>
      'changed category to ${_category(entry.newValue)}',
  };

  String _status(String? wire) =>
      wire == null ? 'nothing' : RequestStatus.tryFromWire(wire)?.label ?? wire;

  String _priority(String? wire) =>
      wire == null ? 'nothing' : Priority.tryFromWire(wire)?.label ?? wire;

  String _user(String? raw) {
    final id = int.tryParse(raw ?? '');
    if (id == null) return 'someone';

    for (final user in [
      ...knownUsers,
      request.requester,
      if (request.assignee != null) request.assignee!,
    ]) {
      if (user.id == id) return user.name;
    }
    return 'user #$id';
  }

  String _category(String? raw) {
    final id = int.tryParse(raw ?? '');
    if (id == null) return 'another category';
    return categories[id] ?? request.category.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              entry.action.icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: entry.actor.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' ${_describe()}'),
                  TextSpan(
                    text: ' · ${formatRelative(entry.createdAt)}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({required this.viewModel});

  final RequestDetailViewModel viewModel;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    await widget.viewModel.addComment.execute(text);

    if (widget.viewModel.addComment.completed && mounted) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(hintText: 'Add a comment'),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _controller,
                  widget.viewModel.addComment,
                ]),
                builder: (context, _) {
                  final canSend =
                      _controller.text.trim().isNotEmpty &&
                      !widget.viewModel.addComment.running;

                  return IconButton.filled(
                    onPressed: canSend ? _send : null,
                    icon: const Icon(Icons.send, size: 18),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
