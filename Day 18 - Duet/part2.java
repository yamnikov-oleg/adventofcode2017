package day18;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Queue;
import java.util.ArrayDeque;

interface Instruction {
    void execute(VirtualMachine vm);
}

class VirtualMachine {
    // Internal memory
    Map<Character,Long> registers;
    Instruction[] program;

    // Communication state
    Queue<Long> sendingQueue;
    long sendCounter;
    Value receiver;

    // Execution state
    long nextInstruction;
    boolean halted;
    boolean jumped;

    public VirtualMachine() {
        this.registers = new HashMap<>();
        this.program = null;

        this.sendingQueue = new ArrayDeque<>();
        this.sendCounter = 0;
        this.receiver = null;

        this.nextInstruction = 0;
        this.halted = false;
        this.jumped = false;
    }

    public long getRegister(char name) {
        Long value = registers.get(name);
        if (value != null) {
            return value;
        } else {
            return 0;
        }
    }

    public void setRegister(char name, long value) {
        registers.put(name, value);
    }

    public void setProgram(Instruction[] program) {
        this.program = program;
    }

    public void send(long value) {
        this.sendingQueue.add(value);
        this.sendCounter++;
    }

    public Queue<Long> getSendingQueue() {
        return this.sendingQueue;
    }

    public long getSendCounter() {
        return this.sendCounter;
    }

    public void requestReceiving(Value dst) {
        this.receiver = dst;
    }

    public boolean isWaitingForReceiving() {
        return this.receiver != null;
    }

    public void receive(long value) {
        this.receiver.set(this, value);
        this.receiver = null;
    }

    public void halt() {
        this.halted = true;
    }

    public boolean isHalted() {
        return this.halted;
    }

    public void jumpTo(long rel) {
        this.nextInstruction += rel;
        this.jumped = true;
    }

    public boolean canRun() {
        return !this.isHalted() && !this.isWaitingForReceiving();
    }

    public void executeNext() {
        if (this.isHalted() || this.isWaitingForReceiving()) {
            throw new RuntimeException("Cannot execute instructions while VM is halted or waiting for a receiving");
        }

        this.program[(int)this.nextInstruction].execute(this);

        if (jumped) {
            jumped = false;
        } else {
            this.nextInstruction++;
            if (this.nextInstruction >= this.program.length) {
                this.halt();
            }
        }
    }
}

class TwoMachinesSupervizor {
    VirtualMachine machine0;
    VirtualMachine machine1;

    public TwoMachinesSupervizor(VirtualMachine machine0, VirtualMachine machine1) {
        this.machine0 = machine0;
        this.machine1 = machine1;
    }

    public void run() {
        while (true) {
            if (this.machine0.isWaitingForReceiving() && this.machine1.getSendingQueue().size() > 0) {
                long value = this.machine1.getSendingQueue().remove();
                this.machine0.receive(value);
            }

            if (this.machine1.isWaitingForReceiving() && this.machine0.getSendingQueue().size() > 0) {
                long value = this.machine0.getSendingQueue().remove();
                this.machine1.receive(value);
            }

            if (!this.machine0.canRun() && !this.machine1.canRun()) {
                break;
            }

            if (this.machine0.canRun()) {
                this.machine0.executeNext();
            }

            if (this.machine1.canRun()) {
                this.machine1.executeNext();
            }
        }
    }
}

abstract class Value {
    abstract boolean isSettable();
    abstract long get(VirtualMachine vm);
    abstract void set(VirtualMachine vm, long value);
}

class IntegerLiteral extends Value {
    long value;

    public IntegerLiteral(long value) {
        this.value = value;
    }

    public boolean isSettable() {
        return false;
    }

    public long get(VirtualMachine vm) {
        return this.value;
    }

    public void set(VirtualMachine vm, long value) {
        throw new UnsupportedOperationException("Cannot set value of integer literal");
    }
}

class RegisterReference extends Value {
    char name;

    public RegisterReference(char name) {
        this.name = name;
    }

    public boolean isSettable() {
        return true;
    }

    public long get(VirtualMachine vm) {
        return vm.getRegister(this.name);
    }

    public void set(VirtualMachine vm, long value) {
        vm.setRegister(this.name, value);
    }
}

class SetInstruction implements Instruction {
    Value dst;
    Value src;

    public SetInstruction(Value dst, Value src) {
        this.dst = dst;
        this.src = src;

        if (!dst.isSettable()) {
            throw new IllegalArgumentException("Set's destination must be a settable value");
        }
    }

    public void execute(VirtualMachine vm) {
        this.dst.set(vm, this.src.get(vm));
    }
}

class AddInstruction implements Instruction {
    Value dst;
    Value increment;

    public AddInstruction(Value dst, Value increment) {
        this.dst = dst;
        this.increment = increment;

        if (!dst.isSettable()) {
            throw new IllegalArgumentException("Add's destination must be a settable value");
        }
    }

    public void execute(VirtualMachine vm) {
        long value = this.dst.get(vm);
        long inc = this.increment.get(vm);
        this.dst.set(vm, value + inc);
    }
}

class MulInstruction implements Instruction {
    Value dst;
    Value factor;

    public MulInstruction(Value dst, Value factor) {
        this.dst = dst;
        this.factor = factor;

        if (!dst.isSettable()) {
            throw new IllegalArgumentException("Mul's destination must be a settable value");
        }
    }

    public void execute(VirtualMachine vm) {
        long value = this.dst.get(vm);
        long factor = this.factor.get(vm);
        this.dst.set(vm, value * factor);
    }
}

class ModInstruction implements Instruction {
    Value dst;
    Value divisor;

    public ModInstruction(Value dst, Value divisor) {
        this.dst = dst;
        this.divisor = divisor;

        if (!dst.isSettable()) {
            throw new IllegalArgumentException("Mul's destination must be a settable value");
        }
    }

    public void execute(VirtualMachine vm) {
        long value = this.dst.get(vm);
        long div = this.divisor.get(vm);
        this.dst.set(vm, value % div);
    }
}

class SndInstruction implements Instruction {
    Value value;

    public SndInstruction(Value value) {
        this.value = value;
    }

    public void execute(VirtualMachine vm) {
        vm.send(this.value.get(vm));
    }
}

class RcvInstruction implements Instruction {
    Value dst;

    public RcvInstruction(Value dst) {
        this.dst = dst;
    }

    public void execute(VirtualMachine vm) {
        vm.requestReceiving(this.dst);
    }
}

class JgzInstruction implements Instruction {
    Value cond;
    Value jmpDst;

    public JgzInstruction(Value cond, Value jmpDst) {
        this.cond = cond;
        this.jmpDst = jmpDst;
    }

    public void execute(VirtualMachine vm) {
        long condValue = this.cond.get(vm);
        if (condValue > 0) {
            vm.jumpTo(this.jmpDst.get(vm));
        }
    }
}

class InstructionParser {
    public Instruction parse(String line) {
        String[] parts = line.trim().split(" ");
        String iname = parts[0];

        List<Value> operands = new ArrayList<>();
        for (int i = 1; i < parts.length; i++) {
            try {
                long value = Long.parseLong(parts[i]);
                operands.add(new IntegerLiteral(value));
            } catch (NumberFormatException e) {
                char register = parts[i].charAt(0);
                operands.add(new RegisterReference(register));
            }
        }

        switch(iname) {
        case "snd":
            return new SndInstruction(operands.get(0));
        case "set":
            return new SetInstruction(operands.get(0), operands.get(1));
        case "add":
            return new AddInstruction(operands.get(0), operands.get(1));
        case "mul":
            return new MulInstruction(operands.get(0), operands.get(1));
        case "mod":
            return new ModInstruction(operands.get(0), operands.get(1));
        case "rcv":
            return new RcvInstruction(operands.get(0));
        case "jgz":
            return new JgzInstruction(operands.get(0), operands.get(1));
        default:
            throw new IllegalArgumentException("Undefined instruction " + iname);
        }
    }
}

class Main {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Input file path is required");
            System.exit(1);
        }

        FileInputStream stream = null;
        try {
            stream = new FileInputStream(args[0]);
        } catch (IOException e) {
            System.out.println(e);
            System.exit(1);
        }

        BufferedReader reader = new BufferedReader(new InputStreamReader(stream));
        List<Instruction> instructions = new ArrayList<>();
        InstructionParser parser = new InstructionParser();
        try {
            String line;
            while ((line = reader.readLine()) != null) {
                instructions.add(parser.parse(line));
            }
        } catch (IOException e) {
            System.out.println(e);
            System.exit(1);
        }

        try {
            reader.close();
        } catch (IOException e) {
            System.out.println(e);
            System.exit(1);
        }

        Instruction[] program = new Instruction[instructions.size()];
        instructions.toArray(program);

        VirtualMachine machine0 = new VirtualMachine();
        machine0.setRegister('p', 0);
        machine0.setProgram(program);

        VirtualMachine machine1 = new VirtualMachine();
        machine1.setRegister('p', 1);
        machine1.setProgram(program);

        TwoMachinesSupervizor supervizor = new TwoMachinesSupervizor(machine0, machine1);
        supervizor.run();

        System.out.println("Machine 1 sent a value " + machine1.getSendCounter() + " times");
    }
}