#[allow(unused_imports)]

use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::process::{exit, Command, ExitStatus};
use std::thread;

//Apps - nslookup, dnsrecon, dig, wafwoof, whois, whatweb, sublist3r

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
        let file_path = "output.log";

        let hostname = &args[1];
        let host = hostname.to_string();

}
}


