import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexustwos/widgets/empty_state_widget.dart';

void main() {
  testWidgets('renders empty state title, message and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: Icons.favorite_border,
            title: 'Nenhum favorito ainda',
            message: 'Adicione conteúdos para ver depois.',
            buttonLabel: 'Explorar catálogo',
            onButtonPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nenhum favorito ainda'), findsOneWidget);
    expect(find.text('Adicione conteúdos para ver depois.'), findsOneWidget);
    expect(find.text('Explorar catálogo'), findsOneWidget);
  });
}
