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

  int getValue(VM vm) {
    if (isRegister) {
      return vm.registers[register];
    } else {
      return constant;
    }
  }

  void setValue(VM vm, int val) {
    if (isRegister) {
      vm.registers[register] = val;
    } else {
      throw new Exception("Cannot set value of a constant");
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

class VM {
  Map<String, int> registers;
  int instrPointer;
  int timesMulCalled;

  VM(int regNum) {
    registers = new Map<String, int>();
    for (var i = 0; i < regNum; i++) {
      var regName = new String.fromCharCode('a'.codeUnits[0] + i);
      registers[regName] = 0;
    }

    instrPointer = 0;
    timesMulCalled = 0;
  }

  String toString() {
    return "VM($registers, $instrPointer)";
  }

  void execute(Instruction ins) {
    switch (ins.mnemonic) {
      case "set":
        ins.dst.setValue(this, ins.src.getValue(this));
        instrPointer++;
        break;
      case "sub":
        var dstValue = ins.dst.getValue(this);
        dstValue -= ins.src.getValue(this);
        ins.dst.setValue(this, dstValue);
        instrPointer++;
        break;
      case "mul":
        var dstValue = ins.dst.getValue(this);
        var srcValue = ins.src.getValue(this);
        ins.dst.setValue(this, dstValue * srcValue);
        instrPointer++;
        timesMulCalled++;
        break;
      case "jnz":
        var offset = ins.src.getValue(this);
        var dstValue = ins.dst.getValue(this);
        if (dstValue != 0) {
          instrPointer += offset;
        } else {
          instrPointer++;
        }
        break;
      default:
        throw new Exception("Unknown instruction ${ins.mnemonic}");
    }
  }

  void executeProgram(List<Instruction> program) {
    while (instrPointer >= 0 && instrPointer < program.length) {
      execute(program[instrPointer]);
    }
  }
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

  VM vm = new VM(8);
  vm.executeProgram(program);
  print("MUL has been called ${vm.timesMulCalled} times");
}
