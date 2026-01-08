use regex_automata::meta::Regex;
use std::fs;
use std::path::PathBuf;
use zk_regex_compiler::{ProvingFramework, gen_from_raw};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let pattern = r#"No:\s*(\d+).*\r\nID:\s*(0x[0-9a-fA-F]+)\r\nRecipient:\s*(0x[0-9a-fA-F]+)"#;

    let re = Regex::new(pattern)?;

    let text = r#"--0000000000004de89e06456fe60a
Content-Type: text/plain; charset="UTF-8"

No: 12
ID: 0xaa85f8f1638dee2775f69142859953cc57ef25045e26d66af25421fbbc404c43
Recipient: 0xd78B5013757Ea4A7841811eF770711e6248dC282
Memo: Lorem Ipsum is simply dummy text of the printing and typesetting
industry. Lorem Ipsum has been the industry's standard dummy text ever
since the 1500s, when an unknown printer took a galley of type and
scrambled it to make a type specimen book.

--0000000000004de89e06456fe60a
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

<div dir=3D"ltr">No: 12<div>ID: 0xaa85f8f1638dee2775f69142859953cc57ef25045=
e26d66af25421fbbc404c43<br>Recipient:=C2=A00xd78B5013757Ea4A7841811eF770711=
e6248dC282<br>Memo:=C2=A0Lorem Ipsum is simply dummy text of the printing a=
nd typesetting industry. Lorem Ipsum has been the industry&#39;s standard d=
ummy text ever since the 1500s, when an unknown printer took a galley of ty=
pe and scrambled it to make a type specimen book.</div></div>

--0000000000004de89e06456fe60a--
"#
    .replace("\n", "\r\n");

    let mut caps = re.create_captures();
    re.captures(&text, &mut caps);

    if caps.is_match() {
        let no = &text[caps.get_group(1).unwrap().range()];
        let id = &text[caps.get_group(2).unwrap().range()];
        let recipient = &text[caps.get_group(3).unwrap().range()];

        println!("No: {}", no);
        println!("ID: {}", id);
        println!("Recipient: {}", recipient);

        assert_eq!(no, "12");
        assert_eq!(
            id,
            "0xaa85f8f1638dee2775f69142859953cc57ef25045e26d66af25421fbbc404c43"
        );
        assert_eq!(recipient, "0xd78B5013757Ea4A7841811eF770711e6248dC282");
    }

    let template_name = "rac_body";

    // Step 1: Generate NFA graph and Noir code using gen_from_raw
    println!("Compiling regex pattern...");
    let (nfa, noir_code) = gen_from_raw(
        pattern,
        Some(vec![5, 66, 42]), // max_bytes for each of the 3 capture groups
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
