import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_model.dart';
import '../providers/voice_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/voice_tuning_sheet.dart';
import '../widgets/server_config_dialog.dart';
import 'history_screen.dart';
import 'voice_studio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceProv = context.watch<VoiceProvider>();
    final playerProv = context.watch<AudioPlayerProvider>();
    final voices = voiceProv.filteredVoices;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text to Voice AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Voice Agents Showcase',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice tuning modal
          IconButton(
            tooltip: 'Voice Tuning (Pitch & Speed)',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const VoiceTuningSheet(),
              );
            },
          ),

          // Saved Audios history with badge
          Badge(
            isLabelVisible: voiceProv.history.isNotEmpty,
            label: Text('${voiceProv.history.length}'),
            backgroundColor: const Color(0xFF6366F1),
            child: IconButton(
              tooltip: 'Saved Audios',
              icon: const Icon(Icons.history_rounded, color: Color(0xFF94A3B8)),
              onPressed: () {
                playerProv.stop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ),

          // Settings modal
          IconButton(
            tooltip: 'Studio Settings & Info',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Showcase Banner
          SliverToBoxAdapter(
            child: _buildShowcaseHeader(context),
          ),

          // Category Filter Tabs
          SliverToBoxAdapter(
            child: _buildCategoryTabs(context, voiceProv),
          ),

          // Search Box
          SliverToBoxAdapter(
            child: _buildSearchBox(context, voiceProv),
          ),

          // Voice Agents Header Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Voice Agents (${voices.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  const Text(
                    'Tap ▶ to hear sample',
                    style: TextStyle(fontSize: 12, color: Color(0xFF22D3EE)),
                  ),
                ],
              ),
            ),
          ),

          // Voice Cards List
          voices.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF64748B)),
                        const SizedBox(height: 12),
                        Text(
                          'No voices found matching "${voiceProv.searchQuery}"',
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final v = voices[index];
                        return _buildVoiceAgentCard(context, v, playerProv, voiceProv);
                      },
                      childCount: voices.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildShowcaseHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6366F1), width: 0.8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic_external_on_rounded, size: 14, color: Color(0xFF22D3EE)),
                SizedBox(width: 6),
                Text(
                  '100% LOCAL AI VOICE STUDIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22D3EE),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pick a Voice & Listen',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap ▶ to hear the built-in sample audio. Tap the arrow ➔ to enter the studio and generate your own voiceovers.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, VoiceProvider prov) {
    final categories = [
      {'id': 'recommended', 'label': 'Recommended', 'icon': '⭐'},
      {'id': 'indian', 'label': 'Indian Voices', 'icon': '🇮🇳'},
      {'id': 'male', 'label': 'Male Voices', 'icon': '♂'},
      {'id': 'female', 'label': 'Female Voices', 'icon': '♀'},
      {'id': 'all', 'label': 'All Voices', 'icon': '🌐'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final isSelected = prov.activeCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Text(cat['icon']!),
              label: Text(cat['label']!),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFF131B2E),
              selectedColor: const Color(0xFF4F46E5),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (_) => prov.setCategory(cat['id']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context, VoiceProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by voice name or language (Hindi, Tamil, Male)...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      prov.setSearchQuery('');
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (val) {
            prov.setSearchQuery(val);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildVoiceAgentCard(
    BuildContext context,
    VoiceModel v,
    AudioPlayerProvider playerProv,
    VoiceProvider voiceProv,
  ) {
    final isPlayingSample =
        playerProv.currentAudioUrl == v.sampleAssetPath && playerProv.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPlayingSample ? const Color(0xFF06B6D4) : const Color(0xFF1E293B),
          width: isPlayingSample ? 1.5 : 1.0,
        ),
        boxShadow: isPlayingSample
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Voice Name & Tags
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: v.isFemale
                        ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
                  ),
                ),
                child: Center(
                  child: Text(
                    v.flagEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            v.simpleName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: v.isFemale
                                ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                                : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                v.isFemale ? Icons.female_rounded : Icons.male_rounded,
                                size: 14,
                                color: v.isFemale ? const Color(0xFFF472B6) : const Color(0xFF60A5FA),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                v.gender,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: v.isFemale ? const Color(0xFFF472B6) : const Color(0xFF60A5FA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.langDisplay} • ${v.tag}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22D3EE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Voice Description & Sample Transcript Preview
          Text(
            v.description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    v.sampleTranscript,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Action Row: Play Sample Button & Arrow Button
          Row(
            children: [
              // Play Sample Button
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isPlayingSample
                          ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                          : const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isPlayingSample ? const Color(0xFF06B6D4) : const Color(0xFF334155),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (isPlayingSample) {
                        playerProv.stop();
                      } else {
                        playerProv.playAsset(v.sampleAssetPath);
                      }
                    },
                    icon: Icon(
                      isPlayingSample ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: isPlayingSample ? const Color(0xFF22D3EE) : Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      isPlayingSample ? 'Playing Sample...' : 'Play Sample',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPlayingSample ? const Color(0xFF22D3EE) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Arrow Mark Button (Go Inside Voice Studio)
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    playerProv.stop();
                    voiceProv.selectVoice(v);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VoiceStudioScreen(voice: v),
                      ),
                    );
                  },
                  label: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  icon: const Text(
                    'Use Voice',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
