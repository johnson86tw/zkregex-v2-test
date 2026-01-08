mod email_sender_regex;

global MAX_EMAIL_HEADER_LENGTH: u32 = 960;

fn main(
    header: BoundedVec<u8, MAX_EMAIL_HEADER_LENGTH>,
    email_sender_match_start: u32,
    email_sender_match_length: u32,
    email_sender_current_states: [Field; 36],
    email_sender_next_states: [Field; 36],
    email_sender_capture_group_1_id: [Field; 36],
    email_sender_capture_group_1_start: [Field; 36],
    email_sender_capture_group_start_indices: [Field; 1],
) -> pub (BoundedVec<u8, 20>) {
    // check the body and header lengths are within bounds
    assert(header.len() <= MAX_EMAIL_HEADER_LENGTH);

    let email_sender_capture_1 = email_sender_regex::regex_match::<MAX_EMAIL_HEADER_LENGTH, 36>(
        header.storage(),
        email_sender_match_start,
        email_sender_match_length,
        email_sender_current_states,
        email_sender_next_states,
        email_sender_capture_group_1_id,
        email_sender_capture_group_1_start,
        email_sender_capture_group_start_indices,
    );
    (email_sender_capture_1)
}
