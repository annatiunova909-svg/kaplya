import 'dart:io';
import 'dart:math';

void main() {
  print('===  МОРСКОЙ БОЙ ===\n');

  int playerWins = 0;
  int enemyWins = 0;

  while (true) {
    stdout.write('Введите размер поля (минимум 5): ');
    final n = int.tryParse(stdin.readLineSync() ?? '');
    if (n == null || n < 5) {
      print('Размер поля должен быть не меньше 5.\n');
      continue;
    }

    stdout.write('Играть против компьютера? (y/n): ');
    final vsBot = (stdin.readLineSync() ?? '').toLowerCase().startsWith('y');

    final game = SeaBattle(n, vsBot);
    final winner = game.play();

    // Сохраняем статистику
    game.saveStatistics(winner);

    if (winner == 'player') playerWins++;
    else enemyWins++;

    print('\n Текущий счёт: Игрок $playerWins — Противник $enemyWins\n');

    stdout.write('Сыграть ещё раз? (y/n): ');
    if ((stdin.readLineSync() ?? '').toLowerCase() != 'y') break;
  }

  print('\nСпасибо за игру! ');
}

class SeaBattle {
  final int size;
  final bool vsBot;
  final Random _rnd = Random();

  late List<List<String>> playerField;
  late List<List<String>> enemyField;
  late List<List<String>> enemyVisible;

  int playerShips = 0;
  int enemyShips = 0;

  // Добавлена статистика
  int playerHits = 0;
  int playerMisses = 0;
  int enemyHits = 0;
  int enemyMisses = 0;
  int totalShots = 0;
  DateTime gameStartTime = DateTime.now();

  SeaBattle(this.size, this.vsBot) {
    playerField = List.generate(size, (_) => List.filled(size, '~'));
    enemyField = List.generate(size, (_) => List.filled(size, '~'));
    enemyVisible = List.generate(size, (_) => List.filled(size, '~'));

    print('\nХотите расставить корабли вручную? (y/n): ');
    final manual = (stdin.readLineSync() ?? '').toLowerCase().startsWith('y');

    if (manual) {
      _manualPlacement();
    } else {
      _placeShips(playerField);
    }
    _placeShips(enemyField);
  }

  //  Случайная расстановка кораблей
  void _placeShips(List<List<String>> field) {
    int ships = size ~/ 2;
    int placed = 0;
    while (placed < ships) {
      int x = _rnd.nextInt(size);
      int y = _rnd.nextInt(size);
      if (field[x][y] == '~') {
        field[x][y] = '■';
        placed++;
      }
    }
    if (field == playerField) playerShips = ships;
    else enemyShips = ships;
  }

  //  Ручная расстановка кораблей игроком
  void _manualPlacement() {
    int ships = size ~/ 2;
    int placed = 0;

    print('\nРасставьте $ships кораблей (введите координаты строка столбец, например: 2 3)');
    _printField(playerField);

    while (placed < ships) {
      stdout.write('Корабль №${placed + 1}: ');
      final parts = stdin.readLineSync()?.split(' ');
      if (parts == null || parts.length != 2) {
        print('Введите две координаты через пробел.');
        continue;
      }

      final x = int.tryParse(parts[0]);
      final y = int.tryParse(parts[1]);
      if (x == null || y == null || x < 1 || y < 1 || x > size || y > size) {
        print('Некорректные координаты.');
        continue;
      }

      if (playerField[x - 1][y - 1] != '~') {
        print('Здесь уже стоит корабль.');
        continue;
      }

      playerField[x - 1][y - 1] = '■';
      placed++;
      _printField(playerField);
    }

    playerShips = ships;
    print(' Все корабли расставлены!\n');
  }

  //  Игровой процесс
  String play() {
    while (playerShips > 0 && enemyShips > 0) {
      _printFields();

      print('\nВаш ход (введите "exit" для выхода):');
      int? x, y;
      while (true) {
        stdout.write('Введите координаты (строка столбец, от 1 до $size): ');
        final input = stdin.readLineSync();
        if (input == null) continue;
        if (input.toLowerCase() == 'exit') {
          print('Выход из игры...');
          exit(0);
        }

        final parts = input.split(' ');
        if (parts.length != 2) {
          print('Введите две координаты через пробел.');
          continue;
        }

        x = int.tryParse(parts[0]);
        y = int.tryParse(parts[1]);
        if (x == null || y == null || x < 1 || y < 1 || x > size || y > size) {
          print('Некорректные координаты.');
          continue;
        }

        x--; y--;
        if (enemyVisible[x][y] != '~') {
          print('Вы уже стреляли сюда!');
          continue;
        }
        break;
      }

      totalShots++;
      if (enemyField[x][y] == '■') {
        print(' Попадание!');
        enemyField[x][y] = 'X';
        enemyVisible[x][y] = 'X';
        enemyShips--;
        playerHits++;
      } else {
        print(' Мимо!');
        enemyVisible[x][y] = '*';
        playerMisses++;
      }

      if (enemyShips == 0) break;

      if (vsBot) _botMove();
      else _enemyMove();
    }

    _printFields();

    if (playerShips > 0) {
      print('\n Победа!');
      return 'player';
    } else {
      print('\n Поражение!');
      return 'enemy';
    }
  }

  //  Ход противника (вручную)
  void _enemyMove() {
    print('\nХод противника!');
    stdout.write('Введите координаты (строка столбец): ');
    final parts = stdin.readLineSync()?.split(' ');
    if (parts?.length == 2) {
      final bx = int.tryParse(parts![0]);
      final by = int.tryParse(parts[1]);
      if (bx != null && by != null && bx >= 1 && by >= 1 && bx <= size && by <= size) {
        _enemyShoot(bx - 1, by - 1);
      }
    }
  }

  //  Выстрел противника
  void _enemyShoot(int x, int y) {
    totalShots++;
    if (playerField[x][y] == '■') {
      print(' Противник попал!');
      playerField[x][y] = 'X';
      playerShips--;
      enemyHits++;
    } else {
      print(' Противник промахнулся.');
      playerField[x][y] = '*';
      enemyMisses++;
    }
  }

  //  Ход бота
  void _botMove() {
    int x, y;
    do {
      x = _rnd.nextInt(size);
      y = _rnd.nextInt(size);
    } while (playerField[x][y] == 'X' || playerField[x][y] == '*');

    totalShots++;
    if (playerField[x][y] == '■') {
      print(' Робот стреляет в (${x + 1}, ${y + 1}) — попал!');
      playerField[x][y] = 'X';
      playerShips--;
      enemyHits++;
    } else {
      print(' Робот стреляет в (${x + 1}, ${y + 1}) — мимо.');
      playerField[x][y] = '*';
      enemyMisses++;
    }
  }

  //  Печать только одного поля (для расстановки)
  void _printField(List<List<String>> field) {
    for (int i = 0; i < size; i++) {
      print(field[i].join(' '));
    }
    print('');
  }

  //  Печать обоих полей
  void _printFields() {
    print('\nВаше поле:'.padRight(25) + 'Поле противника:');
    for (int i = 0; i < size; i++) {
      String playerRow = playerField[i].join(' ');
      String enemyRow = enemyVisible[i].join(' ');
      print('$playerRow'.padRight(25) + '$enemyRow');
    }
  }

  // Добавлен метод сохранения статистики
  void saveStatistics(String winner) {
    try {
      // Создаем каталог для статистики
      final statsDir = Directory('game_statistics');
      if (!statsDir.existsSync()) {
        statsDir.createSync();
      }

      // Создаем имя файла с датой и временем
      final now = DateTime.now();
      final fileName = 'sea_battle_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.txt';
      final filePath = 'game_statistics/$fileName';

      // Рассчитываем точность стрельбы
      final playerAccuracy = playerHits + playerMisses > 0 
          ? (playerHits / (playerHits + playerMisses) * 100).toStringAsFixed(1)
          : '0.0';
      
      final enemyAccuracy = enemyHits + enemyMisses > 0
          ? (enemyHits / (enemyHits + enemyMisses) * 100).toStringAsFixed(1)
          : '0.0';

      // Создаем содержимое файла со статистикой
      final statsContent = '''
=== СТАТИСТИКА МОРСКОГО БОЯ ===

ОБЩАЯ ИНФОРМАЦИЯ:
- Дата игры: ${now.day}.${now.month}.${now.year}
- Размер поля: $size x $size
- Режим: ${vsBot ? 'Против компьютера' : 'Против игрока'}
- Победитель: ${winner == 'player' ? 'ИГРОК' : 'ПРОТИВНИК'}

СТАТИСТИКА ИГРОКА:
- Уничтожено кораблей противника: ${size ~/ 2 - enemyShips}
- Потеряно кораблей: ${size ~/ 2 - playerShips}
- Осталось кораблей: $playerShips/${size ~/ 2}
- Попадания: $playerHits
- Промахи: $playerMisses
- Точность стрельбы: $playerAccuracy%

СТАТИСТИКА ПРОТИВНИКА:
- Уничтожено кораблей игрока: ${size ~/ 2 - playerShips}
- Осталось кораблей: $enemyShips/${size ~/ 2}
- Попадания: $enemyHits
- Промахи: $enemyMisses
- Точность стрельбы: $enemyAccuracy%

ОБЩАЯ СТАТИСТИКА:
- Всего выстрелов: $totalShots
- Всего кораблей уничтожено: ${(size ~/ 2 - playerShips) + (size ~/ 2 - enemyShips)}
''';

      // Записываем статистику в файл
      final file = File(filePath);
      file.writeAsStringSync(statsContent);
      
      print('\nСтатистика игры сохранена в файл: $filePath');
      print(statsContent);

    } catch (e) {
      print('Ошибка при сохранении статистики: $e');
    }
  }
}


