using Gee;

enum Direction {
    LEFT, RIGHT
}

struct Action {
    public bool write_value;
    public Direction move;
    public char next_state;
}

struct Transition {
    public Action if_value_1;
    public Action if_value_0;
}

struct MachineInput {
    public char initial_state;
    public uint diagnostics_in_steps;
    public HashMap<char, Transition?> transitions;
}

public bool startswith(string s, string sub) {
    return s.length >= sub.length && s.substring(0, sub.length) == sub;
}

errordomain ReadError {
    NOT_EXISTS,
    BAD_FORMAT
}

MachineInput read_input(string path) throws Error {
    var input_file = File.new_for_path(path);
    if (!input_file.query_exists ()) {
        throw new ReadError.NOT_EXISTS("Input file doesn't exist");
    }

    var input = MachineInput() {
        transitions = new HashMap<char, Transition?>()
    };
    char in_state = 'A';
    bool if_value = false;

    var input_stream = new DataInputStream(input_file.read());
    string line;
    while ((line = input_stream.read_line (null)) != null) {
        if (line.length == 0) continue;

        if (startswith(line, "Begin in state ")) {
            var char_ix = "Begin in state ".length;
            input.initial_state = line[char_ix];
        } else if (startswith(line, "Perform a diagnostic checksum after ")) {
            var num_start = "Perform a diagnostic checksum after ".length;
            var num_end = line.index_of(" steps");
            var num_str = line.substring(num_start, num_end - num_start);
            input.diagnostics_in_steps = int.parse(num_str);
        } else if (startswith(line, "In state ")) {
            var char_ix = "In state ".length;
            in_state = line[char_ix];
            input.transitions[in_state] = Transition();
        } else if (startswith(line, "  If the current value is ")) {
            var char_ix = "  If the current value is ".length;
            if (line[char_ix] == '1') {
                if_value = true;
            } else if (line[char_ix] == '0') {
                if_value = false;
            } else {
                throw new ReadError.BAD_FORMAT(
                    "Could not parse \"if the current value\": %c".printf(line[char_ix])
                );
            }
        } else if (startswith(line, "    - Write the value ")) {
            var char_ix = "    - Write the value ".length;

            bool write_value;
            if (line[char_ix] == '1') {
                write_value = true;
            } else if (line[char_ix] == '0') {
                write_value = false;
            } else {
                throw new ReadError.BAD_FORMAT(
                    "Could not parse \"write the value\": %c".printf(line[char_ix])
                );
            }

            var transition = input.transitions[in_state];
            if (if_value == true) {
                transition.if_value_1.write_value = write_value;
            } else {
                transition.if_value_0.write_value = write_value;
            }
            input.transitions[in_state] = transition;
        } else if (startswith(line, "    - Move one slot to the ")) {
            var dir_start = "    - Move one slot to the ".length;
            var dir_end = line.index_of(".");
            var dir_str = line.substring(dir_start, dir_end - dir_start);

            Direction dir;
            if (dir_str == "left") {
                dir = Direction.LEFT;
            } else if (dir_str == "right") {
                dir = Direction.RIGHT;
            } else {
                throw new ReadError.BAD_FORMAT(
                    "Could not parse \"move one slot\" direction\": %s".printf(dir_str)
                );
            }

            var transition = input.transitions[in_state];
            if (if_value == true) {
                transition.if_value_1.move = dir;
            } else {
                transition.if_value_0.move = dir;
            }
            input.transitions[in_state] = transition;
        } else if (startswith(line, "    - Continue with state ")) {
            var char_ix = "    - Continue with state ".length;
            var state = line[char_ix];

            var transition = input.transitions[in_state];
            if (if_value == true) {
                transition.if_value_1.next_state = state;
            } else {
                transition.if_value_0.next_state = state;
            }
            input.transitions[in_state] = transition;
        } else {
            throw new ReadError.BAD_FORMAT(
                "I don't know how to deal with this line: %s".printf(line)
            );
        }
    }

    return input;
}

class Machine {
    public char state = 'A';
    public int cursor = 0;
    public HashMap<int, bool> tape = new HashMap<int, bool>();

    public void run_action(Action action) {
        tape[cursor] = action.write_value;

        if (action.move == Direction.LEFT) {
            cursor--;
        } else {
            cursor++;
        }

        state = action.next_state;
    }

    public void run_transition(Transition transition) {
        var cur_value = tape[cursor];
        if (cur_value == true) {
            run_action(transition.if_value_1);
        } else {
            run_action(transition.if_value_0);
        }
    }

    public void run(MachineInput input) {
        state = input.initial_state;
        cursor = 0;
        tape = new HashMap<int, bool>();

        for (var step = 0; step < input.diagnostics_in_steps; step++) {
            var transition = input.transitions[state];
            run_transition(transition);
        }
    }

    public int checksum() {
        var sum = 0;
        foreach (var v in tape.values) {
            if (v) sum++;
        }
        return sum;
    }
}

int main(string[] args) {
    if (args.length != 2) {
        stderr.printf("Only one argument is required: path to the input file\n");
        return 1;
    }

    try {
        var input = read_input(args[1]);
        var machine = new Machine();
        machine.run(input);
        stdout.printf("Checksum: %d\n", machine.checksum());
        return 0;
    } catch (Error e) {
        stderr.printf("%s\n", e.message);
        return 1;
    }
}
