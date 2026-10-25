import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final bool isGenerating;
  final ValueChanged<String> onSendMessage;
  final VoidCallback onCancelGeneration;
  final bool showSuggestions;

  const ChatInputBar({
    super.key,
    required this.isGenerating,
    required this.onSendMessage,
    required this.onCancelGeneration,
    this.showSuggestions = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  final List<Map<String, String>> _suggestions = [
    {
      'label': '📞 Call Assistant Role',
      'prompt': 'Act as an autonomous phone call assistant. A caller says: "Hi, I need to discuss the project schedule urgently." How do you answer?',
    },
    {
      'label': '📝 Summarize Call Notes',
      'prompt': 'Here is a quick call note: "Customer John called regarding invoice #402. Paid yesterday, wants confirmation receipt before 5 PM." Please provide a structured summary with action items.',
    },
    {
      'label': '⚡ Test AI Speed',
      'prompt': 'Provide 3 concise bullet points on how AI phone assistants save time and organize call notes.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) {
        setState(() => _canSend = can);
      }
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSendMessage(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSuggestions)
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    item['label']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: widget.isGenerating
                      ? null
                      : () => widget.onSendMessage(item['prompt']!),
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (_canSend && !widget.isGenerating) _submit();
                    },
                    decoration: InputDecoration(
                      hintText: widget.isGenerating
                          ? 'Generating response...'
                          : 'Message Local AI (Qwen 2.5)...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.isGenerating
                  ? FloatingActionButton.small(
                      heroTag: 'stop_fab',
                      elevation: 1,
                      backgroundColor: Colors.redAccent,
                      onPressed: widget.onCancelGeneration,
                      child: const Icon(Icons.stop_rounded, color: Colors.white),
                    )
                  : FloatingActionButton.small(
                      heroTag: 'send_fab',
                      elevation: 1,
                      backgroundColor: _canSend
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant,
                      onPressed: _canSend ? _submit : null,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: _canSend
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
