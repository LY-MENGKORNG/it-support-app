import 'package:app/ui/core/ui/field_label.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/priority.dart';
import 'package:app/ui/core/ui/error_indicator.dart';
import 'package:app/ui/core/ui/status_chip.dart';
import 'package:app/ui/requests/view_models/create_request_viewmodel.dart';
import 'package:app/utils/result.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CreateRequestScreen extends StatefulWidget {
  final CreateRequestViewModel viewModel;

  const CreateRequestScreen({super.key, required this.viewModel});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<ShadFormState>();

  @override
  void initState() {
    super.initState();
    widget.viewModel.submit.addListener(_onSubmitChanged);
  }

  void _onSubmitChanged() {
    final command = widget.viewModel.submit;
    if (!mounted) return;

    if (command.error) {
      // final error = command.exception;
      command.clearResult();
      return;
    }

    if (command.completed) {
      final created = command.result?.asOk.value;
      command.clearResult();
      if (created == null) return;

      context.pop(created);
    }
  }

  void _submit() {
    final formState = _formKey.currentState!;

    if (!formState.saveAndValidate()) return;

    widget.viewModel.submit.execute((
      title: formState.getFieldValue('title'),
      description: formState.getFieldValue('description'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            builder: (context, _) => ShadForm(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Raised as ${viewModel.requesterName ?? 'unknown'}',
                      style: theme.textTheme.p.copyWith(
                        color: theme.colorScheme.accent,
                      ),
                    ),

                    ShadInputFormField(
                      id: 'title',
                      label: const Text('Title'),
                      validator: viewModel.validator['title'],
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      placeholder: const Text('Laptop cannot connect to Wi-Fi'),
                    ),
                    const SizedBox(height: 16),

                    ShadTextareaFormField(
                      id: 'description',
                      label: const Text('Description'),
                      validator: viewModel.validator['description'],
                      placeholder: Text(
                        viewModel.selectedCategory?.description ?? 'What happened, when it started, and anything you have already tried.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ShadSelectFormField<RequestCategory>(
                        id: 'category',
                        label: const Text('Category'),
                        placeholder: const Text('Pick a category'),
                        initialValue: viewModel.selectedCategory,
                        options: [
                          ...viewModel.categoryOptions.map(
                            (el) => ShadOption(value: el, child: Text(el.name)),
                          ),
                        ],
                        selectedOptionBuilder: (ctx, value) => Text(value.name),
                        onChanged: viewModel.selectCategory,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const FieldLabel('Priority'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final priority in Priority.values)
                          ChoiceChip(
                            label: Text(priority.label),
                            selected: viewModel.priority == priority,
                            onSelected: (_) =>
                                viewModel.selectPriority(priority),
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
                            viewModel.priority.hint,
                            style: theme.textTheme.p.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ShadButton(
                            onPressed: viewModel.canSubmit ? _submit : null,
                            child: viewModel.submit.running
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.viewModel.submit.removeListener(_onSubmitChanged);
    super.dispose();
  }
}

class InvalidRequestScreen extends StatelessWidget {
  const InvalidRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request')),
    body: const Center(child: Text('That request id is not valid.')),
  );
}
