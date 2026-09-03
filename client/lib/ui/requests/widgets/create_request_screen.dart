import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/services/api/api_exception.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/ui/core/ui/content_column.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/core/ui/status_chip.dart';
import 'package:app/ui/requests/view_models/create_request_viewmodel.dart';
import 'package:app/utils/result.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, required this.viewModel});

  final CreateRequestViewModel viewModel;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  /// Identifies the form so `validate()` can drive every field at once.
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.submit.addListener(_onSubmitChanged);
  }

  @override
  void dispose() {
    widget.viewModel.submit.removeListener(_onSubmitChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmitChanged() {
    final command = widget.viewModel.submit;
    if (!mounted) return;

    if (command.error) {
      final error = command.exception;
      command.clearResult();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error == null
                  ? 'Could not create the request.'
                  : messageFor(error),
            ),
          ),
        );
      return;
    }

    if (command.completed) {
      final created = command.result?.asOk.value;
      command.clearResult();
      if (created == null) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Request #${created.id} created')),
        );
      context.pop(created);
    }
  }

  void _submit() {
    // `validate()` runs every validator and repaints their error text.
    if (!_formKey.currentState!.validate()) return;

    widget.viewModel.submit.execute((
      title: _titleController.text,
      description: _descriptionController.text,
    ));
  }

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Give the request a short title';
    // Mirrors the server's `min(3).max(120)` so the user finds out here first.
    if (text.length < 3) return 'Use at least 3 characters';
    if (text.length > 120) return 'Keep the title under 120 characters';
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Describe what is happening';
    if (text.length < 10) {
      return 'Add a little more detail — at least 10 characters';
    }
    if (text.length > 5000) return 'That is too long for one request';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: ContentColumn(
        maxWidth: 640,
        child: ListenableBuilder(
          listenable: viewModel.load,
          builder: (context, child) {
            if (viewModel.load.running && viewModel.categoryOptions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.load.error && viewModel.categoryOptions.isEmpty) {
              return ErrorIndicator(
                title: 'Could not load categories',
                error: viewModel.load.exception,
                onPressed: viewModel.load.execute,
              );
            }
            return child!;
          },
          child: ListenableBuilder(
            listenable: Listenable.merge([viewModel, viewModel.submit]),
            builder: (context, _) => Form(
              key: _formKey,
              // Show errors once a field has been touched and changed, rather
              // than only after the first failed submit.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Raised as ${viewModel.requesterName ?? 'unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _FieldLabel('Title'),
                  TextFormField(
                    controller: _titleController,
                    validator: _validateTitle,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Laptop cannot connect to Wi-Fi',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _FieldLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    validator: _validateDescription,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: viewModel.selectedCategory?.description ?? 'What happened, when it started, and anything you have already tried.',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _FieldLabel('RequestCategory'),
                  DropdownButtonFormField<RequestCategory>(
                    initialValue: viewModel.selectedCategory,
                    isExpanded: true,
                    validator: (value) =>
                        value == null ? 'Pick a category' : null,
                    items: [
                      for (final category in viewModel.categoryOptions)
                        DropdownMenuItem(
                          value: category,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: viewModel.selectCategory,
                  ),
                  const SizedBox(height: 20),

                  const _FieldLabel('Priority'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final priority in Priority.values)
                        ChoiceChip(
                          label: Text(priority.label),
                          selected: viewModel.priority == priority,
                          onSelected: (_) => viewModel.selectPriority(priority),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PriorityChip(viewModel.priority, dense: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _priorityHint(viewModel.priority),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: viewModel.canSubmit ? _submit : null,
                    child: viewModel.submit.running
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit request'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _priorityHint(Priority priority) => switch (priority) {
    Priority.low => 'Inconvenient, but you can keep working.',
    Priority.medium => 'Slowing you down. The default for most requests.',
    Priority.high => 'You are blocked on this.',
    Priority.critical => 'Several people are blocked, or something is unsafe.',
  };
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
