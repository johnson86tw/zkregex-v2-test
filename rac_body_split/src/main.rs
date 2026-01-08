use regex_automata::meta::Regex;
use std::fs;
use std::path::PathBuf;
use zk_regex_compiler::{ProvingFramework, gen_from_raw};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Test text for validation
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

    let output_dir = PathBuf::from("./src");
    fs::create_dir_all(&output_dir)?;

    // ========== Pattern 1: No field ==========
    println!("\n=== Compiling No field regex ===");
    let no_pattern = r#"No:\s*(\d+)"#;
    let no_template_name = "no_regex";

    let re_no = Regex::new(no_pattern)?;
    let mut caps = re_no.create_captures();
    re_no.captures(&text, &mut caps);

    if caps.is_match() {
        let no = &text[caps.get_group(1).unwrap().range()];
        println!("No: {}", no);
        assert_eq!(no, "12");
    }

    let (nfa_no, noir_code_no) = gen_from_raw(
        no_pattern,
        Some(vec![5]), // max_bytes for No field (up to 5 digits)
        no_template_name,
        ProvingFramework::Noir,
    )?;

    let graph_path_no = output_dir.join(format!("{}_graph.json", no_template_name));
    fs::write(&graph_path_no, &nfa_no.to_json()?)?;
    println!("✅ Generated NFA graph: {}", graph_path_no.display());

    let noir_code_path_no = output_dir.join(format!("{}.nr", no_template_name));
    fs::write(&noir_code_path_no, &noir_code_no)?;
    println!("✅ Generated Noir code: {}", noir_code_path_no.display());

    println!("NFA states: {}", nfa_no.state_count());
    println!("NFA transitions: {}", nfa_no.transition_count());
    println!("Capture groups: {}", nfa_no.num_capture_groups);

    // ========== Pattern 2: ID field ==========
    println!("\n=== Compiling ID field regex ===");
    let id_pattern = r#"ID:\s*(0x[0-9a-fA-F]+)"#;
    let id_template_name = "id_regex";

    let re_id = Regex::new(id_pattern)?;
    let mut caps = re_id.create_captures();
    re_id.captures(&text, &mut caps);

    if caps.is_match() {
        let id = &text[caps.get_group(1).unwrap().range()];
        println!("ID: {}", id);
        assert_eq!(
            id,
            "0xaa85f8f1638dee2775f69142859953cc57ef25045e26d66af25421fbbc404c43"
        );
    }

    let (nfa_id, noir_code_id) = gen_from_raw(
        id_pattern,
        Some(vec![66]), // max_bytes for ID field (0x + 64 hex chars)
        id_template_name,
        ProvingFramework::Noir,
    )?;

    let graph_path_id = output_dir.join(format!("{}_graph.json", id_template_name));
    fs::write(&graph_path_id, &nfa_id.to_json()?)?;
    println!("✅ Generated NFA graph: {}", graph_path_id.display());

    let noir_code_path_id = output_dir.join(format!("{}.nr", id_template_name));
    fs::write(&noir_code_path_id, &noir_code_id)?;
    println!("✅ Generated Noir code: {}", noir_code_path_id.display());

    println!("NFA states: {}", nfa_id.state_count());
    println!("NFA transitions: {}", nfa_id.transition_count());
    println!("Capture groups: {}", nfa_id.num_capture_groups);

    // ========== Pattern 3: Recipient field ==========
    println!("\n=== Compiling Recipient field regex ===");
    let recipient_pattern = r#"Recipient:\s*(0x[0-9a-fA-F]+)"#;
    let recipient_template_name = "recipient_regex";

    let re_recipient = Regex::new(recipient_pattern)?;
    let mut caps = re_recipient.create_captures();
    re_recipient.captures(&text, &mut caps);

    if caps.is_match() {
        let recipient = &text[caps.get_group(1).unwrap().range()];
        println!("Recipient: {}", recipient);
        assert_eq!(recipient, "0xd78B5013757Ea4A7841811eF770711e6248dC282");
    }

    let (nfa_recipient, noir_code_recipient) = gen_from_raw(
        recipient_pattern,
        Some(vec![42]), // max_bytes for Recipient field (Ethereum address)
        recipient_template_name,
        ProvingFramework::Noir,
    )?;

    let graph_path_recipient = output_dir.join(format!("{}_graph.json", recipient_template_name));
    fs::write(&graph_path_recipient, &nfa_recipient.to_json()?)?;
    println!("✅ Generated NFA graph: {}", graph_path_recipient.display());

    let noir_code_path_recipient = output_dir.join(format!("{}.nr", recipient_template_name));
    fs::write(&noir_code_path_recipient, &noir_code_recipient)?;
    println!("✅ Generated Noir code: {}", noir_code_path_recipient.display());

    println!("NFA states: {}", nfa_recipient.state_count());
    println!("NFA transitions: {}", nfa_recipient.transition_count());
    println!("Capture groups: {}", nfa_recipient.num_capture_groups);

    println!("\n=== All patterns compiled successfully! ===");

    Ok(())
}
