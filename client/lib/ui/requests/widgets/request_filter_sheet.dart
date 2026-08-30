import 'package:flutter/material.dart';

import 'package:app/domain/models/priority.dart';
import 'package:app/domain/models/request_sort.dart';
import 'package:app/domain/models/request_status.dart';
import 'package:app/domain/models/request_category.dart';
import 'package:app/domain/models/user.dart';
import 'package:app/domain/models/request_filters.dart';

/// The filter sheet for the requests list.
///
/// It edits a *copy* of the filters and returns it on Apply, so backing out
/// leaves the list exactly as it was. Returns null when dismissed.
class RequestFilterSheet extends StatefulWidget {
  const RequestFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
    required this.currentUser,
  });

  final RequestFilters initial;
  final List<RequestCategory> categories;
  final User currentUser;

  static Future<RequestFilters?> show(
    BuildContext context, {
    required RequestFilters initial,
    required List<RequestCategory> categories,
    required User currentUser,
  }) => showModalBottomSheet<RequestFilters>(
    context: context,
    isScrollControlled: true,
    builder: (context) => RequestFilterSheet(
      initial: initial,
      categories: categories,
      currentUser: currentUser,
    ),
  );

  @override
  State<RequestFilterSheet> createState() => _RequestFilterSheetState();
}

class _RequestFilterSheetState extends State<RequestFilterSheet> {
  late RequestFilters _draft = widget.initial;

  bool get _minesOnly => _draft.requesterId == widget.currentUser.id;
  bool get _assignedToMe => _draft.assigneeId == widget.currentUser.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter requests', style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),

              _Group(
                label: 'Status',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in RequestStatus.values)
                      FilterChip(
                        label: Text(status.label),
                        selected: _draft.status == status,
                        onSelected: (selected) => setState(() {
                          _draft = selected
                              ? _draft.copyWith(status: status)
                              : _draft.copyWith(clearStatus: true);
                        }),
                      ),
                  ],
                ),
              ),

              _Group(
                label: 'Priority',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in Priority.values)
                      FilterChip(
                        label: Text(priority.label),
                        selected: _draft.priority == priority,
                        onSelected: (selected) => setState(() {
                          _draft = selected
                              ? _draft.copyWith(priority: priority)
                              : _draft.copyWith(clearPriority: true);
                        }),
                      ),
                  ],
                ),
              ),

              if (widget.categories.isNotEmpty)
                _Group(
                  label: 'RequestCategory',
                  child: DropdownButtonFormField<int?>(
                    initialValue: _draft.categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Any category'),
                      ),
                      for (final category in widget.categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _draft = value == null
                          ? _draft.copyWith(clearCategory: true)
                          : _draft.copyWith(categoryId: value);
                    }),
                  ),
                ),

              _Group(
                label: 'People',
                child: Column(
                  children: [
                    // `requesterId` and `assigneeId` are independent server-side,
                    // but offering them as free-form pickers would be noise on a
                    // phone. These two shortcuts cover what people actually want.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Raised by me'),
                      value: _minesOnly,
                      onChanged: (on) => setState(() {
                        _draft = on
                            ? _draft.copyWith(
                                requesterId: widget.currentUser.id,
                              )
                            : _draft.copyWith(clearRequester: true);
                      }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Assigned to me'),
                      value: _assignedToMe,
                      onChanged: (on) => setState(() {
                        _draft = on
                            ? _draft.copyWith(
                                assigneeId: widget.currentUser.id,
                                unassignedOnly: false,
                              )
                            : _draft.copyWith(clearAssignee: true);
                      }),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Unassigned only'),
                      value: _draft.unassignedOnly,
                      onChanged: (on) => setState(() {
                        _draft = _draft.copyWith(
                          unassignedOnly: on,
                          clearAssignee: on,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              _Group(
                label: 'Sort by',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sort in RequestSort.values)
                      ChoiceChip(
                        label: Text(sort.label),
                        selected: _draft.sort == sort,
                        onSelected: (_) => setState(
                          () => _draft = _draft.copyWith(sort: sort),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(
                        // Keep the search text; this button clears *filters*.
                        RequestFilters(query: widget.initial.query),
                      ),
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_draft),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
