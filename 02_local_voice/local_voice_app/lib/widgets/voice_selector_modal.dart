import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';

class VoiceSelectorModal extends StatefulWidget {
  const VoiceSelectorModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceSelectorModal(),
    );
  }

  @override
  State<VoiceSelectorModal> createState() => _VoiceSelectorModalState();
}

class _VoiceSelectorModalState extends State<VoiceSelectorModal> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<VoiceProvider>();
    _searchController.text = prov.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceProv = context.watch<VoiceProvider>();
    final voices = voiceProv.filteredVoices;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Select Voice Agent',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${voices.length} Available',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by voice, language, or country...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          voiceProv.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => voiceProv.setSearchQuery(val),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip(
                  context: context,
                  label: '⭐ Recommended',
                  category: 'recommended',
                  activeCategory: voiceProv.activeCategory,
                  onSelected: () => voiceProv.setCategory('recommended'),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context: context,
                  label: '🇮🇳 Indian Voices',
                  category: 'indian',
                  activeCategory: voiceProv.activeCategory,
                  onSelected: () => voiceProv.setCategory('indian'),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context: context,
                  label: 'All Voices (${voiceProv.allVoices.length})',
                  category: 'all',
                  activeCategory: voiceProv.activeCategory,
                  onSelected: () => voiceProv.setCategory('all'),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context: context,
                  label: '👩 Female',
                  category: 'female',
                  activeCategory: voiceProv.activeCategory,
                  onSelected: () => voiceProv.setCategory('female'),
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context: context,
                  label: '👨 Male',
                  category: 'male',
                  activeCategory: voiceProv.activeCategory,
                  onSelected: () => voiceProv.setCategory('male'),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Voice List
          Expanded(
            child: voices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No voices found matching "${voiceProv.searchQuery}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: voices.length,
                    itemBuilder: (context, index) {
                      final v = voices[index];
                      final isSelected =
                          v.shortName == voiceProv.selectedVoice.shortName;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.4)
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondaryContainer,
                            foregroundColor: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSecondaryContainer,
                            child: Text(
                              v.flagEmoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  v.simpleName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                v.isFemale ? Icons.female : Icons.male,
                                size: 16,
                                color: v.isFemale
                                    ? Colors.pinkAccent
                                    : Colors.blueAccent,
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${v.langDisplay} • ${v.gender}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (v.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  v.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            voiceProv.selectVoice(v);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required String category,
    required String activeCategory,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final isSelected = category == activeCategory;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}



