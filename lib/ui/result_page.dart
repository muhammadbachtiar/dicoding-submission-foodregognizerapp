import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/result_controller.dart';
import '../widget/classification_item.dart';
import '../widget/meal_detail_card.dart';

class ResultPage extends StatefulWidget {
  final String imagePath;

  const ResultPage({super.key, required this.imagePath});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ResultController>().analyze(widget.imagePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Hasil Analisis'),
        centerTitle: true,
      ),
      body: _ResultBody(imagePath: widget.imagePath),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final String imagePath;

  const _ResultBody({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Consumer<ResultController>(
      builder: (context, controller, _) {
        if (controller.isLoadingML) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menganalisis gambar...'),
              ],
            ),
          );
        }

        if (controller.errorMessage != null) {
          return Center(child: Text(controller.errorMessage!));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hasil Prediksi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...controller.results.map(
                (r) => ClassificatioinItem(
                  item: r.label,
                  value: r.confidencePercent,
                  isTop: controller.results.indexOf(r) == 0,
                ),
              ),
              const SizedBox(height: 24),
              _MealSection(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _MealSection extends StatelessWidget {
  final ResultController controller;

  const _MealSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingMeals) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.meals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resep Terkait',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...controller.meals.take(3).map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MealDetailCard(meal: meal),
              ),
            ),
      ],
    );
  }
}
