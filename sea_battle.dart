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

    if (winner == 'player') playerWins++;
    else enemyWins++;

    print('\n Текущий счёт: Игрок $playerWins — Противник $enemyWins\n');

    stdout.write('Сыграть ещё раз? (y/n): ');
    if ((stdin.readLineSync() ?? '').toLowerCase() != 'y') break;
  }

  print('\nСпасибо за игру! До новых морских побед ');
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
    while (placed < ships) 
    {
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

      if (enemyField[x][y] == '■') {
        print(' Попадание!');
        enemyField[x][y] = 'X';
        enemyVisible[x][y] = 'X';
        enemyShips--;
      } else {
        print(' Мимо!');
        enemyVisible[x][y] = '*';
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
    if (playerField[x][y] == '■') {
      print(' Противник попал!');
      playerField[x][y] = 'X';
      playerShips--;
    } else {
      print(' Противник промахнулся.');
      playerField[x][y] = '*';
    }
  }

  //  Ход бота
  void _botMove() {
    int x, y;
    do {
      x = _rnd.nextInt(size);
      y = _rnd.nextInt(size);
    } while (playerField[x][y] == 'X' || playerField[x][y] == '*');

    if (playerField[x][y] == '■') {
      print(' Робот стреляет в (${x + 1}, ${y + 1}) — попал!');
      playerField[x][y] = 'X';
      playerShips--;
    } else {
      print(' Робот стреляет в (${x + 1}, ${y + 1}) — мимо.');
      playerField[x][y] = '*';
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
}

