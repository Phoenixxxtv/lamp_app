import 'package:flutter_test/flutter_test.dart';
import 'package:lamp_app/core/utils/date_formatter.dart';
import 'package:lamp_app/features/protege/habits/habit_model.dart';

void main() {
  group('DateFormatter Tests', () {
    test('format formats DateTime correctly as dd/MM/yyyy', () {
      final date = DateTime(2024, 1, 25);
      expect(DateFormatter.format(date), '25/01/2024');
    });

    test('formatMedium formats DateTime correctly as dd MMM yyyy', () {
      final date = DateTime(2024, 1, 25);
      expect(DateFormatter.formatMedium(date), '25 Jan 2024');
    });

    test('tryFormat parses and formats standard ISO string', () {
      final isoString = '2024-01-25T10:00:00.000Z';
      expect(DateFormatter.tryFormat(isoString), '25/01/2024');
    });

    test('tryFormat returns original string if parsing fails', () {
      const invalidDate = 'not-a-date';
      expect(DateFormatter.tryFormat(invalidDate), invalidDate);
    });

    test('tryFormat returns null for null input', () {
      expect(DateFormatter.tryFormat(null), null);
    });
  });

  group('Habit Model Tests', () {
    test('Habit.fromJson parses valid JSON correctly', () {
      final json = {
        'id': '123',
        'name': 'Meditation',
        'description': 'Daily practice',
        'is_active': true,
        'created_at': '2024-01-01T12:00:00Z',
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, '123');
      expect(habit.name, 'Meditation');
      expect(habit.description, 'Daily practice');
      expect(habit.isActive, true);
      expect(habit.createdAt, isNotNull);
      expect(habit.createdAt?.year, 2024);
    });

    test('Habit.fromJson handles missing optional fields', () {
      final json = {
        'id': '123',
        'name': 'Meditation',
      };

      final habit = Habit.fromJson(json);

      expect(habit.id, '123');
      expect(habit.name, 'Meditation');
      expect(habit.description, null);
      expect(habit.isActive, true); // Default value
    });
  });
}
