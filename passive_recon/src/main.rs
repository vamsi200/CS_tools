use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::process::{exit, Command, ExitStatus};
use std::thread;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        let file_path = "output.log";

        let hostname = &args[1];

        let tools = vec![
            ("nslookup", hostname.to_string()),
            ("dnsrecon", format!("-d {}", hostname)),
            ("dig", hostname.to_string()),
            ("wafw00f", hostname.to_string()),
            ("whois", hostname.to_string()),
            ("whatweb", hostname.to_string()),
            ("sublist3r", format!("-d {}", hostname)),
        ];

        let handles: Vec<_> = tools
            .into_iter()
            .map(|(tool, arg)| {
                let file_path = file_path.to_string();
                thread::spawn(move || match run_command(tool, &arg, &file_path) {
                    Ok(status) => {
                        println!("- {} on {} Done {:?}", tool, arg, status);
                    }
                    Err(e) => {
                        eprintln!("Error Running {} on {}: {}", tool, arg, e);
                    }
                })
            })
            .collect();

        for handle in handles {
            handle.join().unwrap();
        }
    } else {
        println!("[*] No Hostname Mentioned.");
        println!("-- Usage: \n ./passive_recon hostname");
        exit(1);
    }
}

fn run_command(
    command: &str,
    argument: &str,
    file_path: &str,
) -> Result<ExitStatus, std::io::Error> {
    let output = Command::new(command).arg(argument).output()?;

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(file_path)?;

    writeln!(
        file,
        "Command: {} {}\nOutput:\n{}",
        command,
        argument,
        String::from_utf8_lossy(&output.stdout)
    )?;
    writeln!(file, "Error:\n{}", String::from_utf8_lossy(&output.stderr))?;
    writeln!(file, "Status: {:?}", output.status)?;

    Ok(output.status)
}
