import 'package:flutter/material.dart';

import '../core/ai/fake_ai_service.dart';
import '../core/data/local_lookbook.dart';
import '../core/data/models.dart';
import '../features/outfits/lookbook_screen.dart';
import '../features/outfits/outfit_request_screen.dart';
import '../features/outfits/outfit_results_screen.dart';
import 'app.dart';

class Garment {
  Garment(this.name, this.category, this.color, this.days, this.icon);
  final String name, category;
  final Color color;
  int days;
  final IconData icon;
}

class AppShell extends StatefulWidget {
  const AppShell({this.lookbook, super.key});

  final LocalLookbook? lookbook;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  String filter = 'All', occasion = 'Everyday', style = 'Casual';
  bool preview = false;
  late final lookbook = widget.lookbook ?? LocalLookbook();
  late Future<void> wardrobeReady = loadWardrobe();
  Outfit? suggestedOutfit;
  int saveButtonVersion = 0;
  final sampleTee = Garment(
    'Daisy tee',
    'Tops',
    const Color(0xFFE59AB6),
    10,
    Icons.local_florist_outlined,
  );
  final removing = <Garment>{};

  Future<void> loadWardrobe() async {
    final data = await lookbook.read();
    if (mounted) {
      clothes.removeWhere((item) => data.deletedItems.contains(item.name));
    }
  }

  Future<void> removeGarment(Garment item) async {
    if (!removing.add(item)) return;
    try {
      await lookbook.deleteItem(item.name);
      if (!mounted) return;
      setState(() => clothes.remove(item));
      notice('Piece removed from your wardrobe.');
    } catch (_) {
      if (mounted) notice('Could not remove this piece. Try again.');
    } finally {
      removing.remove(item);
    }
  }

  final input = TextEditingController();
  final chatScroll = ScrollController();
  final messages = <(String, bool)>[];
  final clothes = <Garment>[
    Garment(
      'Daisy tee',
      'Tops',
      const Color(0xFFE59AB6),
      10,
      Icons.local_florist_outlined,
    ),
    Garment(
      'Linen shirt',
      'Tops',
      const Color(0xFFD9BC77),
      8,
      Icons.checkroom_outlined,
    ),
    Garment(
      'Green sneakers',
      'Shoes',
      const Color(0xFF65816A),
      1,
      Icons.directions_walk,
    ),
    Garment(
      'Everyday shorts',
      'Bottoms',
      const Color(0xFFBEB39A),
      6,
      Icons.checkroom_outlined,
    ),
    Garment(
      'Sunday heels',
      'Shoes',
      const Color(0xFFC6A6B7),
      20,
      Icons.directions_walk,
    ),
    Garment(
      'Floral skirt',
      'Bottoms',
      const Color(0xFFE3BD55),
      40,
      Icons.local_florist_outlined,
    ),
  ];

  @override
  void dispose() {
    input.dispose();
    chatScroll.dispose();
    super.dispose();
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: plum,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.checkroom, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Fitcheck AI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Lookbook',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LookbookScreen(
                            store: lookbook,
                            onRemoved: (id) {
                              if (mounted && id == suggestedOutfit?.id) {
                                setState(() => saveButtonVersion++);
                              }
                            },
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.bookmarks_outlined),
                    ),
                    IconButton(
                      tooltip: 'Home',
                      onPressed: () => setState(() => tab = 0),
                      icon: const Icon(Icons.home_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (tab) {
                  0 => home(),
                  1 => FutureBuilder<void>(
                    future: wardrobeReady,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load your wardrobe.'),
                              TextButton(
                                onPressed: () => setState(() {
                                  wardrobeReady = loadWardrobe();
                                }),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      return wardrobe();
                    },
                  ),
                  2 => capture(),
                  _ => outfits(),
                },
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) => setState(() => tab = value),
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE9DDFB),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard),
          label: 'Today',
        ),
        NavigationDestination(
          icon: Icon(Icons.checkroom_outlined),
          label: 'Wardrobe',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_a_photo_outlined),
          label: 'Add item',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          label: 'Outfits',
        ),
      ],
    ),
  );

  Widget heading(String eyebrow, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: plum,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF81788C), height: 1.5),
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget card(Widget child, {Color color = Colors.white}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEEE8F4)),
    ),
    child: child,
  );

  Future<List<ClothingItem>> loadPlannerCloset() async {
    await wardrobeReady;
    return [
      for (final item in {for (final item in clothes) item.name: item}.values)
        ClothingItem(
          id: item.name,
          photoPath: '',
          tags: ClothingTags(
            category: switch (item.category) {
              'Tops' => 'top',
              'Bottoms' => 'bottom',
              _ => 'shoes',
            },
            color: '',
            pattern: '',
            formality: '',
            season: '',
          ),
          createdAt: DateTime.now(),
          isSample: true,
        ),
    ];
  }

  void openOutfitPlanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutfitRequestScreen(
          loadCloset: loadPlannerCloset,
          ai: FakeAiService(outfitCount: 1),
          lookbook: lookbook,
          initialOccasion: occasion,
        ),
      ),
    );
  }

  Widget home() => ListView(
    key: const PageStorageKey('today'),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    children: [
      heading(
        'YOUR DAILY EDIT',
        'Good outfits start here.',
        'Rediscover your wardrobe. Make every piece count.',
      ),
      OutlinedButton.icon(
        onPressed: openOutfitPlanner,
        icon: const Icon(Icons.wb_cloudy_outlined),
        label: const Text('Plan an outfit with live weather'),
      ),
      const SizedBox(height: 24),
      const Text(
        'What’s on your agenda?',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THE OCCASION',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Everyday', 'Work', 'Party', 'Picnic']
                  .map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: occasion == s,
                      onSelected: (_) => setState(() => occasion = s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'YOUR MOOD',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Casual', 'Minimal', 'Dressy']
                  .map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: style == s,
                      onSelected: (_) => setState(() => style = s),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: () => setState(() => tab = 3),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Put a look together'),
      ),
      const SizedBox(height: 24),
      card(
        Row(
          children: [
            const Icon(Icons.favorite_border, color: plum),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${clothes.length} pieces, endless possibilities.\nYour next favorite outfit is already in your closet.',
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget wardrobe() {
    final visible = clothes
        .where((item) => filter == 'All' || item.category == filter)
        .toList();
    return ListView(
      key: const PageStorageKey('wardrobe'),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        heading(
          'THE CLOSET',
          'Your wardrobe',
          '${clothes.length} pieces to make your own. Tap a piece to see its story.',
        ),
        Wrap(
          spacing: 8,
          children: ['All', 'Tops', 'Bottoms', 'Shoes']
              .map(
                (s) => ChoiceChip(
                  label: Text(s),
                  selected: filter == s,
                  onSelected: (_) => setState(() => filter = s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 238,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, i) {
            final item = visible[i];
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => detail(item),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFEEE8F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Center(child: garment(item, 90))),
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.days == 0
                          ? 'Worn today'
                          : 'Last worn ${item.days} ${item.days == 1 ? 'day' : 'days'} ago',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.days >= 30
                            ? const Color(0xFFB0683C)
                            : Colors.black54,
                      ),
                    ),
                    if (item.days >= 30)
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Time for a comeback',
                          style: TextStyle(
                            color: plum,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => setState(() => tab = 2),
          icon: const Icon(Icons.add),
          label: const Text('Add a new piece'),
        ),
      ],
    );
  }

  Widget garment(Garment item, double size) => Container(
    width: size + 28,
    height: size + 28,
    decoration: BoxDecoration(
      color: item.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Icon(item.icon, size: size, color: item.color),
  );

  void detail(Garment item) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          garment(item, 100),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.days == 0 ? 'Worn today' : 'Last worn ${item.days} days ago',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              setState(() => item.days = 0);
              Navigator.pop(context);
              notice('Marked as worn today.');
            },
            icon: const Icon(Icons.check),
            label: const Text('I wore this today'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removeGarment(item);
            },
            child: const Text('Remove from wardrobe'),
          ),
        ],
      ),
    ),
  );

  Widget capture() => ListView(
    key: const PageStorageKey('capture'),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    children: [
      heading(
        'A LITTLE CLOSET REFRESH',
        'Meet your next staple.',
        'Give each piece a place in your wardrobe.',
      ),
      card(
        Column(
          children: [
            const Row(
              children: [
                Icon(Icons.crop_free, color: plum),
                SizedBox(width: 10),
                Text(
                  'Clothing preview',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 200,
              child: Center(
                child: preview
                    ? garment(sampleTee, 130)
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 90,
                        color: Color(0xFFBEACD8),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              preview ? 'Daisy tee' : 'One piece. A world of possibilities.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a clear photo with the whole item in view.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() => preview = true),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Try a sample photo'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: preview
            ? () {
                setState(() {
                  clothes.add(
                    Garment(
                      'New daisy tee',
                      'Tops',
                      const Color(0xFFE59AB6),
                      0,
                      Icons.local_florist_outlined,
                    ),
                  );
                  preview = false;
                  filter = 'All';
                  tab = 1;
                });
                notice('Sample piece added.');
              }
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Add to wardrobe'),
      ),
      const SizedBox(height: 16),
      const Text(
        'UI preview · Camera and photo uploads are coming later.\nSample uploads are kept during this session.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.6),
      ),
    ],
  );

  void send([String? text]) {
    final value = (text ?? input.text).trim();
    if (value.isEmpty) return;
    setState(() {
      messages.add((value, true));
      messages.add((
        'Here’s a sample look: a linen shirt, everyday shorts, and green sneakers. A relaxed combination for your plans.',
        false,
      ));
      suggestedOutfit = OutfitResultsScreen.sampleOutfit();
    });
    input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScroll.hasClients) {
        chatScroll.animateTo(
          chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget outfits() => Column(
    children: [
      Expanded(
        child: ListView(
          controller: chatScroll,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          children: [
            heading(
              'YOUR PERSONAL STYLING SPACE',
              'Let’s find your fit.',
              '$occasion plans. $style energy. Entirely you.',
            ),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: plum, size: 18),
                SizedBox(width: 8),
                Text(
                  'Stylist preview',
                  style: TextStyle(color: plum, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Text(
                  'Demo chat',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: openOutfitPlanner,
                icon: const Icon(Icons.wb_cloudy_outlined),
                label: const Text('Plan an outfit with live weather'),
              ),
            ),
            bubble(
              'What are you dressing for today? Tell me about the event, the weather, or a piece you’d love to wear.',
              false,
            ),
            if (messages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      [
                            'A picnic in the park',
                            'Style my green sneakers',
                            'Something for a party',
                          ]
                          .map(
                            (s) => ActionChip(
                              label: Text(
                                s,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => send(s),
                            ),
                          )
                          .toList(),
                ),
              ),
            ...messages.map((m) => bubble(m.$1, m.$2)),
            if (messages.isNotEmpty) ...[
              const SizedBox(height: 12),
              card(
                Column(
                  children: [
                    const Row(
                      children: [
                        Text(
                          'THE WEEKEND EDIT',
                          style: TextStyle(
                            color: plum,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.favorite_border, color: plum),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final i in [1, 3, 2])
                          garment(
                            Garment(
                              '',
                              '',
                              [
                                const Color(0xFFD9BC77),
                                const Color(0xFFBEB39A),
                                const Color(0xFF65816A),
                              ][[1, 3, 2].indexOf(i)],
                              0,
                              i == 2
                                  ? Icons.directions_walk
                                  : Icons.checkroom_outlined,
                            ),
                            55,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Easy layers. Fresh perspective.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Linen shirt · Everyday shorts · Green sneakers',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    SaveOutfitButton(
                      key: ValueKey(saveButtonVersion),
                      outfit: suggestedOutfit!,
                      store: lookbook,
                    ),
                    TextButton(
                      onPressed: () => notice(
                        'More outfit combinations will be available when the stylist is connected.',
                      ),
                      child: const Text('Try a different outfit'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: TextField(
          controller: input,
          onSubmitted: (_) => send(),
          decoration: InputDecoration(
            hintText: 'What do you feel like wearing?',
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: IconButton(
              tooltip: 'Send message',
              onPressed: send,
              icon: const Icon(Icons.arrow_upward, color: plum),
            ),
          ),
        ),
      ),
    ],
  );

  Widget bubble(String text, bool user) => Align(
    alignment: user ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 330),
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user ? plum : const Color(0xFFEFE7FA),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(user ? 20 : 4),
          bottomRight: Radius.circular(user ? 4 : 20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: user ? Colors.white : ink,
          height: 1.5,
          fontSize: 14,
        ),
      ),
    ),
  );
}
