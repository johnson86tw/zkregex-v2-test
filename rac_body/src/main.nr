mod rac_body;

global MAX_EMAIL_BODY_LENGTH: u32 = 1280;
global MAX_MATCH_LENGTH: u32 = 150;

fn main(
    body: BoundedVec<u8, MAX_EMAIL_BODY_LENGTH>,
    rac_body_match_start: u32,
    rac_body_match_length: u32,
    rac_body_current_states: [Field; MAX_MATCH_LENGTH],
    rac_body_next_states: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_1_id: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_2_id: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_3_id: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_1_start: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_2_start: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_3_start: [Field; MAX_MATCH_LENGTH],
    rac_body_capture_group_start_indices: [Field; 3],
) -> pub (BoundedVec<u8, 5>, BoundedVec<u8, 66>, BoundedVec<u8, 42>) {
    // check the body length is within bounds
    assert(body.len() <= MAX_EMAIL_BODY_LENGTH);

    let (rac_body_capture_1, rac_body_capture_2, rac_body_capture_3) = rac_body::regex_match::<MAX_EMAIL_BODY_LENGTH, MAX_MATCH_LENGTH>(
        body.storage(),
        rac_body_match_start,
        rac_body_match_length,
        rac_body_current_states,
        rac_body_next_states,
        rac_body_capture_group_1_id,
        rac_body_capture_group_2_id,
        rac_body_capture_group_3_id,
        rac_body_capture_group_1_start,
        rac_body_capture_group_2_start,
        rac_body_capture_group_3_start,
        rac_body_capture_group_start_indices,
    );

    (rac_body_capture_1, rac_body_capture_2, rac_body_capture_3)
}
