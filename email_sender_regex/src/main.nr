mod email_sender_regex;

global MAX_EMAIL_HEADER_LENGTH: u32 = 960;
global MAX_MATCH_LENGTH: u32 = 36; // from:Johnson <johnson86tw@gmail.com>
global MAX_GROUP_1_LENGTH: u32 = 11; // johnson86tw

// acir: 6902
// bb circuit size: 21712
fn main(
    header: BoundedVec<u8, MAX_EMAIL_HEADER_LENGTH>,
    match_start: u32,
    match_length: u32,
    current_states: [Field; MAX_MATCH_LENGTH],
    next_states: [Field; MAX_MATCH_LENGTH],
    capture_group_1_id: [Field; MAX_MATCH_LENGTH],
    capture_group_1_start: [Field; MAX_MATCH_LENGTH],
    capture_group_start_indices: [Field; 1],
) -> pub (BoundedVec<u8, MAX_GROUP_1_LENGTH>) {
    // check the body and header lengths are within bounds
    assert(header.len() <= MAX_EMAIL_HEADER_LENGTH);

    let capture_1 = email_sender_regex::regex_match::<MAX_EMAIL_HEADER_LENGTH, MAX_MATCH_LENGTH>(
        header.storage(),
        match_start,
        match_length,
        current_states,
        next_states,
        capture_group_1_id,
        capture_group_1_start,
        capture_group_start_indices,
    );
    (capture_1)
}
