import 'package:app/ui/requests/view_models/request_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CommentComposer extends StatefulWidget {
  final RequestDetailViewModel viewModel;

  const CommentComposer({super.key, required this.viewModel});

  @override
  State<CommentComposer> createState() => CommentComposerState();
}

class CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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
                child: ShadInput(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  placeholder: const Text('Add a comment'),
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
