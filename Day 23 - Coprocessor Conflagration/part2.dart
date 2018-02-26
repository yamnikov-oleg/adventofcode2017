import 'dart:async';
import 'dart:io';
import 'dart:convert';

class InsValue {
  String register;
  int constant;

  static InsValue ofRegister(String name) {
    var v = new InsValue();
    v.register = name;
    return v;
  }

  static InsValue ofConstant(int value) {
    var v = new InsValue();
    v.constant = value;
    return v;
  }

  static InsValue parse(String s) {
    try {
      return InsValue.ofConstant(int.parse(s));
    } on FormatException catch (_) {
      if (s.length == 1 &&
          s.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
          s.codeUnitAt(0) <= 'z'.codeUnitAt(0)) {
        return InsValue.ofRegister(s);
      }
    }

    throw new FormatException("Could not parse instruction value \"$s\"");
  }

  bool get isRegister => register != null;

  String toString() {
    if (isRegister) {
      return "Register($register)";
    } else {
      return "Constant($constant)";
    }
  }
}

class Instruction {
  String mnemonic;
  InsValue dst;
  InsValue src;

  static Instruction parse(String s) {
    var parts = s.trim().split(' ');
    if (parts.length != 3) {
      throw new FormatException("Too many parts: \"$s\"");
    }

    var ins = new Instruction();
    ins.mnemonic = parts[0];
    ins.dst = InsValue.parse(parts[1]);
    ins.src = InsValue.parse(parts[2]);
    return ins;
  }

  String toString() {
    return "Instruction(\"$mnemonic\", $dst, $src)";
  }
}

bool isPrime(int n) {
  for (var i = 2; i < n; i++) {
    if (n % i == 0) {
      return false;
    }
  }
  return true;
}

Future main(List<String> args) async {
  if (args.length < 1) {
    print("Input file name is required in arguments");
    return;
  }

  Stream lines = new File(args[0])
      .openRead()
      .transform(UTF8.decoder)
      .transform(new LineSplitter());

  List<Instruction> program = [];
  await for (var line in lines) {
    var ins = Instruction.parse(line);
    program.add(ins);
  }

  if (program.length != 32 ||
      program[0].mnemonic != "set" ||
      program[0].dst.register != "b" ||
      program[0].src.isRegister) {
    throw "This solution only works with inputs, provided by Advent of Code";
  }

  var inputConst = program[0].src.constant;
  var b = inputConst * 100 + 100000;
  var c = b + 17000;
  var h = 0;
  for (var i = b; i <= c; i += 17) {
    if (!isPrime(i)) h++;
  }

  print("h = $h");
}
