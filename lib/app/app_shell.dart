import 'package:flutter/material.dart';

import '../features/closet/add_item_screen.dart';
import '../features/closet/closet_screen.dart';
import 'app.dart';

class Garment {
  Garment(this.name, this.category, this.color, this.days, this.icon);
  final String name, category;
  final Color color;
  int days;
  final IconData icon;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  String occasion = 'Everyday', style = 'Casual';
  bool saved = false;
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
                    const Text(
                      'Fitcheck AI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Spacer(),
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
                  1 => wardrobe(),
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

  Widget home() => ListView(
    key: const PageStorageKey('today'),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    children: [
      heading(
        'YOUR DAILY EDIT',
        'Good outfits start here.',
        'Rediscover your wardrobe. Make every piece count.',
      ),
      card(
        const Row(
          children: [
            Icon(Icons.wb_cloudy_outlined, size: 44, color: plum),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baton Rouge, LA',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Partly cloudy · Sample weather',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              '76°',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        color: const Color(0xFFF0E9FC),
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

  // Member 1's closet, backed by Firestore and the shared AI service.
  Widget wardrobe() => ClosetScreen(onAddItem: () => setState(() => tab = 2));

  Widget garment(Garment item, double size) => Container(
    width: size + 28,
    height: size + 28,
    decoration: BoxDecoration(
      color: item.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Icon(item.icon, size: size, color: item.color),
  );

  Widget capture() => AddItemScreen(onSaved: () => setState(() => tab = 1));

  void send([String? text]) {
    final value = (text ?? input.text).trim();
    if (value.isEmpty) return;
    setState(() {
      messages.add((value, true));
      messages.add((
        'Here’s a sample look: a linen shirt, everyday shorts, and green sneakers. A relaxed combination for your plans.',
        false,
      ));
      saved = false;
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
                    FilledButton.icon(
                      onPressed: saved
                          ? null
                          : () {
                              setState(() => saved = true);
                              notice('Outfit selected for this session.');
                            },
                      icon: Icon(saved ? Icons.check : Icons.favorite_border),
                      label: Text(
                        saved ? 'Outfit selected' : 'Choose this outfit',
                      ),
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
