import 'package:flutter/material.dart';

import '../../data/live_repository.dart';
import '../../domain/live_channel.dart';

class LiveTvPage extends StatefulWidget {
  const LiveTvPage({super.key});

  @override
  State<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends State<LiveTvPage> {
  final repository = LiveRepository();

  List<LiveChannel> allChannels = [];
  List<LiveChannel> filteredChannels = [];

  List<String> categories = [];

  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final channels = await repository.getChannels();

    final cats = channels
        .map((e) => e.category)
        .toSet()
        .toList();

    setState(() {
      allChannels = channels;
      categories = cats;

      if (cats.isNotEmpty) {
        selectedCategory = cats.first;
        filteredChannels =
            channels.where((e) => e.category == selectedCategory).toList();
      }
    });
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;

      filteredChannels = allChannels
          .where((e) => e.category == category)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090909),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            const Text(
              'TV Ao Vivo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  final selected =
                      category == selectedCategory;

                  return GestureDetector(
                    onTap: () => selectCategory(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.red
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: filteredChannels.length,
                itemBuilder: (context, index) {
                  final channel = filteredChannels[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        if (channel.logoUrl.isNotEmpty)
                          Image.network(
                            channel.logoUrl,
                            height: 60,
                            errorBuilder:
                                (_, _, _) =>
                                    const Icon(
                              Icons.tv,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),

                        const SizedBox(height: 12),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          child: Text(
                            channel.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}