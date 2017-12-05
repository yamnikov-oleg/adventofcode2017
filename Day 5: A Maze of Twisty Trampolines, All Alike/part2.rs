use std::{env, process};
use std::fs::File;
use std::io::{BufRead, BufReader};

fn read_file(path: String) -> Result<Vec<i64>, String> {
    let file = File::open(path).map_err(|err| format!("Could not open file: {}", err))?;
    let reader = BufReader::new(file);
    let mut steps = Vec::<i64>::new();
    for line in reader.lines() {
        let line = line.map_err(|err| format!("Could not read line: {}", err))?;
        let step = line.parse()
            .map_err(|err| format!("Could not parse step: {}", err))?;
        steps.push(step);
    }
    Ok(steps)
}

fn run() -> Result<(), String> {
    let mut args = env::args();
    let path = args.nth(1).ok_or("Requires one path argument")?;
    let mut steps = read_file(path)?;

    let mut current_step = 0i64;
    let mut step_count = 0;
    while current_step >= 0 && current_step < steps.len() as i64 {
        let next_step = current_step + steps[current_step as usize];
        if steps[current_step as usize] >= 3 {
            steps[current_step as usize] -= 1;
        } else {
            steps[current_step as usize] += 1;
        }
        current_step = next_step;
        step_count += 1;
    }

    println!("Escape in {} steps", step_count);
    Ok(())
}

fn main() {
    match run() {
        Ok(()) => {}
        Err(msg) => {
            eprintln!("{}", msg);
            process::exit(1);
        }
    }
}
