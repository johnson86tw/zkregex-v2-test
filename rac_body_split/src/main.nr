mod no_regex;
mod id_regex;
mod recipient_regex;

global MAX_EMAIL_BODY_LENGTH: u32 = 1280;
global MAX_NO_MATCH_LENGTH: u32 = 20;
global MAX_ID_MATCH_LENGTH: u32 = 80;
global MAX_RECIPIENT_MATCH_LENGTH: u32 = 60;

fn main(
    body: BoundedVec<u8, MAX_EMAIL_BODY_LENGTH>,

    // No field regex parameters
    no_match_start: u32,
    no_match_length: u32,
    no_current_states: [Field; MAX_NO_MATCH_LENGTH],
    no_next_states: [Field; MAX_NO_MATCH_LENGTH],
    no_capture_group_1_id: [Field; MAX_NO_MATCH_LENGTH],
    no_capture_group_1_start: [Field; MAX_NO_MATCH_LENGTH],
    no_capture_group_start_indices: [Field; 1],

    // ID field regex parameters
    id_match_start: u32,
    id_match_length: u32,
    id_current_states: [Field; MAX_ID_MATCH_LENGTH],
    id_next_states: [Field; MAX_ID_MATCH_LENGTH],
    id_capture_group_1_id: [Field; MAX_ID_MATCH_LENGTH],
    id_capture_group_1_start: [Field; MAX_ID_MATCH_LENGTH],
    id_capture_group_start_indices: [Field; 1],

    // Recipient field regex parameters
    recipient_match_start: u32,
    recipient_match_length: u32,
    recipient_current_states: [Field; MAX_RECIPIENT_MATCH_LENGTH],
    recipient_next_states: [Field; MAX_RECIPIENT_MATCH_LENGTH],
    recipient_capture_group_1_id: [Field; MAX_RECIPIENT_MATCH_LENGTH],
    recipient_capture_group_1_start: [Field; MAX_RECIPIENT_MATCH_LENGTH],
    recipient_capture_group_start_indices: [Field; 1],
) -> pub (BoundedVec<u8, 5>, BoundedVec<u8, 66>, BoundedVec<u8, 42>) {
    // check the body length is within bounds
    assert(body.len() <= MAX_EMAIL_BODY_LENGTH);

    // Match No field
    let no_capture = no_regex::regex_match::<MAX_EMAIL_BODY_LENGTH, MAX_NO_MATCH_LENGTH>(
        body.storage(),
        no_match_start,
        no_match_length,
        no_current_states,
        no_next_states,
        no_capture_group_1_id,
        no_capture_group_1_start,
        no_capture_group_start_indices,
    );

    // Match ID field
    let id_capture = id_regex::regex_match::<MAX_EMAIL_BODY_LENGTH, MAX_ID_MATCH_LENGTH>(
        body.storage(),
        id_match_start,
        id_match_length,
        id_current_states,
        id_next_states,
        id_capture_group_1_id,
        id_capture_group_1_start,
        id_capture_group_start_indices,
    );

    // Match Recipient field
    let recipient_capture = recipient_regex::regex_match::<MAX_EMAIL_BODY_LENGTH, MAX_RECIPIENT_MATCH_LENGTH>(
        body.storage(),
        recipient_match_start,
        recipient_match_length,
        recipient_current_states,
        recipient_next_states,
        recipient_capture_group_1_id,
        recipient_capture_group_1_start,
        recipient_capture_group_start_indices,
    );

    (no_capture, id_capture, recipient_capture)
}
