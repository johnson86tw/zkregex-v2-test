use regex_automata::meta::Regex;
use std::fs;
use std::path::PathBuf;
use zk_regex_compiler::{gen_from_raw, ProvingFramework};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let pattern = r#"(?:\r\n|^)from:[^<]*<([A-Za-z0-9._%+-]+@gmail.com)>"#;
    // let pattern = r#"(?:\r\n|^)from:[^\r\n]+<([A-Za-z0-9._%+-]+)@gmail.com>"#;

    let re = Regex::new(pattern)?;

    let text = "to:chnejohnson@gmail.com\r\nsubject:=?UTF-8?B?56K66KqN5bey5pS25Yiw5oqV56i/OiBUZXN0IGJ5IEFsaWNl?=\r\nmessage-id:<CAAcMZv-OSh4v2hs=tgfr=+wZHK42Qm0z5fYNg3Yb59B3ybj15A@mail.gmail.com>\r\ndate:Mon, 8 Dec 2025 20:25:56 +0800\r\nfrom:Johnson <johnson86tw@gmail.com>\r\nmime-version:1.0\r\ndkim-signature:v=1; a=rsa-sha256; c=relaxed/relaxed; d=gmail.com; s=20230601; t=1765196768; x=1765801568; dara=google.com; h=to:subject:message-id:date:from:mime-version:from:to:cc:subject :date:message-id:reply-to; bh=nHH483zVoxxP1bGva2cvXNzPl4sE3M+YUQXtr7AwtHk=; b=";

    let mut caps = re.create_captures();
    re.captures(text, &mut caps);

    if caps.is_match() {
        let sender = &text[caps.get_group(1).unwrap()];

        println!("from_address: {}", sender);
    }

    let template_name = "from_address_regex";

    // Step 1: Generate NFA graph and Noir code using gen_from_raw
    println!("Compiling regex pattern...");
    let (nfa, noir_code) = gen_from_raw(
        pattern,
        Some(vec![21]), // max_bytes for each of the 3 capture groups
        template_name,
        ProvingFramework::Noir,
    )?;

    // Step 2: Create output directory
    let output_dir = PathBuf::from("./src");
    fs::create_dir_all(&output_dir)?;

    // Step 3: Serialize NFA graph to JSON and save it
    let graph_json = nfa.to_json()?;
    let graph_path = output_dir.join(format!("{}_graph.json", template_name.to_lowercase()));
    fs::write(&graph_path, &graph_json)?;
    println!("✅ Generated NFA graph: {}", graph_path.display());

    // Step 4: Save Noir code to .nr file
    let noir_code_path = output_dir.join(format!("{}.nr", template_name.to_lowercase()));
    fs::write(&noir_code_path, &noir_code)?;
    println!("✅ Generated Noir code: {}", noir_code_path.display());

    // Step 5: Print summary
    println!("\n=== Compilation Summary ===");
    println!("Template name: {}", template_name);
    println!("NFA states: {}", nfa.state_count());
    println!("NFA transitions: {}", nfa.transition_count());
    println!("Capture groups: {}", nfa.num_capture_groups);
    println!("Graph file: {}", graph_path.display());
    println!("Noir file: {}", noir_code_path.display());

    Ok(())
}
