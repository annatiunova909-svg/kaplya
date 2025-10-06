import 'dart:io';
import 'dart:math';

void main() {
  while (true) {
    print('=== КРЕСТИКИ-НОЛИКИ ===');

    int size;
    while (true) {
      stdout.write('Введите размер поля (минимум 3): ');
      final input = stdin.readLineSync();
      final n = int.tryParse(input ?? '');
      if (n != null && n >= 3) {
        size = n;
        break;
      } else {
        print('Размер поля должен быть целым числом не меньше 3. Попробуйте снова.');
      }
    }

    stdout.write('Хотите играть против робота? (y/n): ');
    final vsBot = (stdin.readLineSync() ?? '').toLowerCase().startsWith('y');

    final first = Random().nextBool() ? 'X' : 'O';
    print('Первым ходит: $first');

    final game = TicTacToe(size, vsBot, first);
    game.play();

    stdout.write('\nСыграть ещё раз? (y/n): ');
    final again = stdin.readLineSync()?.toLowerCase();
    if (again != 'y' && again != 'yes') break;
  }

  print('Спасибо за игру!');
}

class TicTacToe {
  final int size;
  final bool vsBot;
  String current;
  List<List<String>> board = [];

  TicTacToe(this.size, this.vsBot, this.current) {
    board = List.generate(size, (_) => List.filled(size, ' '));
  }

  void play() {
    while (true) {
      printBoard();

      if (vsBot && current == 'O') {
        botMove();
      } else {
        playerMove();
      }

      if (checkWin(current)) {
        printBoard();
        print('Победил $current!');
        break;
      }

      if (isFull()) {
        printBoard();
        print('Ничья!');
        break;
      }

      current = current == 'X' ? 'O' : 'X';
    }
  }

  void printBoard() {
    print('');
    for (int i = 0; i < size; i++) {
      print(' ${board[i].join(' | ')}');
      if (i < size - 1) print(' ${List.filled(size, '-').join('-+-')}');
    }
    print('');
  }

  void playerMove() {
    while (true) {
      stdout.write('Ваш ход ($current), введите строку и столбец (1-$size), например: 2 3: ');
      final parts = stdin.readLineSync()?.split(' ');
      if (parts == null || parts.length != 2) continue;

      final r = int.tryParse(parts[0]) ?? 0;
      final c = int.tryParse(parts[1]) ?? 0;

      if (r < 1 || r > size || c < 1 || c > size) {
        print('Введите числа от 1 до $size.');
        continue;
      }

      if (board[r - 1][c - 1] != ' ') {
        print('Клетка занята.');
        continue;
      }

      board[r - 1][c - 1] = current;
      break;
    }
  }

  void botMove() {
    // Правило 1: Попытка победить
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') {
          board[i][j] = 'O';
          if (checkWin('O')) {
            print('Робот сделал ход: ${i + 1} ${j + 1}');
            return;
          }
          board[i][j] = ' '; 
        }
      }
    }
    // Правило 2: Блокировка игрока
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') {
          board[i][j] = 'X';
          if (checkWin('X')) {
            board[i][j] = 'O'; 
            print('Робот сделал ход: ${i + 1} ${j + 1}');
            return;
          }
          board[i][j] = ' '; 
        }
      }
    }
    // Правило 3: Случайный ход 
    final empty = <List<int>>[];
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (board[i][j] == ' ') empty.add([i, j]);
      }
    }
    if (empty.isNotEmpty) {
      final move = empty[Random().nextInt(empty.length)];
      board[move[0]][move[1]] = 'O';
      print('Робот сделал ход: ${move[0] + 1} ${move[1] + 1}');
    }
  }
  bool checkWin(String p) {
    for (int i = 0; i < size; i++) {
      if (board[i].every((e) => e == p)) return true;
      if (List.generate(size, (j) => board[j][i]).every((e) => e == p)) return true;
    }
    if (List.generate(size, (i) => board[i][i]).every((e) => e == p)) return true;
    if (List.generate(size, (i) => board[i][size - 1 - i]).every((e) => e == p)) return true;
    return false;
  }

  bool isFull() => board.every((r) => !r.contains(' '));
}