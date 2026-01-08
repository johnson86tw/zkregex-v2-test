use zkregex::utils::{
   select_subarray,
   captures::capture_substring,
   sparse_array::SparseArray,
   transitions::check_transition_with_captures
};

global TRANSITION_TABLE: SparseArray<82, Field> = SparseArray {
    keys: [0x00000000, 0x00024d4b, 0x00024d4c, 0x00034a49, 0x00041111, 0x00041212, 0x00041313, 0x00041414, 0x00041515, 0x00042828, 0x00044241, 0x0004888a, 0x0004888c, 0x0004898d, 0x00048a8e, 0x00048b8f, 0x00048c90, 0x00048d8e, 0x00048d91, 0x00048e92, 0x00048f93, 0x00049094, 0x00049195, 0x00049296, 0x0004a7ac, 0x0004a8a9, 0x0004b0b4, 0x0004b1b5, 0x0004b7bb, 0x0005cccb, 0x00068c91, 0x0006a6a7, 0x0007efec, 0x00089092, 0x00099394, 0x000af6f0, 0x000bf9f2, 0x000c4840, 0x000d9291, 0x000e4c4b, 0x000e4c4c, 0x000e4d4c, 0x000e4d4d, 0x000e4e4d, 0x000e4e4e, 0x000e4f4e, 0x000e4f4f, 0x000e504f, 0x000e5050, 0x000e5150, 0x000e5151, 0x000e5251, 0x000e5252, 0x000e5352, 0x000e5353, 0x000e5453, 0x000e5454, 0x000e5554, 0x000e5555, 0x000e5d5c, 0x000e5d5d, 0x000e5e5d, 0x000e5e5e, 0x000e5f5e, 0x000e5f5f, 0x000e605f, 0x000e6060, 0x000e6160, 0x000e6161, 0x000e6261, 0x000e6262, 0x000e7d7c, 0x000e7d7d, 0x000e7e7d, 0x000e7e7e, 0x000e7f7e, 0x000e7f7f, 0x000e807f, 0x000e8080, 0x000e8180, 0x000e8181, 0x000e8281, 0x000e8282, 0x000f1c1b],
    values: [0x00000000, 0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000007, 0x00000001, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000000],
    maximum: 0x000f1c1b
};

pub global CAPTURE_1_MAX_LENGTH: u32 = 66;
pub global NUM_CAPTURE_GROUPS: u32 = 1;

/**
 * Constrains a start state to be valid
 * @dev start states are hardcoded in this function - "(start_state - {state})" for each start
 *      example: `(start_state - 0) * (start_state - 1) * (start_state - 2)` means 0, 1, or 2
 *      are valid first states
 * 
 * @param start_state - The start state of the NFA
 */
fn check_start_state(start_state: Field) {
    let valid_start_state = (start_state - 0) * (start_state - 1);
    assert(valid_start_state == 0, "Invalid start state");
}
    
/**
 * Constrains the recognition of accept_state being reached. If an aceppt state is reached,
 *      ensures asserted traversal path is valid
 * @dev accept states are hardcoded in this function - "(next_state - {state})" for each accept
 *      example: `(next_state - 19) * (next_state - 20) * (next_state - 21)` means 19, 20, or 21
 *      are valid accept states
 * 
 * @param next_state - The asserted next state of the NFA
 * @param haystack_index - The index being operated on in the haystack
 * @param asserted_match_length - The asserted traversal path length
 * @return - 0 if accept_state is reached, nonzero otherwise
 */
fn check_accept_state(
    next_state: Field,
    haystack_index: Field, 
    asserted_match_length: Field
) -> Field {
    // check if the next state is an accept state
    let accept_state_reached = (next_state - 14);
    let accept_state_reached_bool = (accept_state_reached == 0) as Field;

    // check if the haystack index is the asserted match length
    // should equal 1 since haystack_index should be 1 less than asserted_match)length
    let asserted_path_traversed = (asserted_match_length - haystack_index == 1) as Field;

    (1 - (accept_state_reached_bool * asserted_path_traversed))
}

/**
 * IdRegexRegex matching function
 * Regex: ID:\\s*(0x[0-9a-fA-F]+)
 * @param in_haystack - The input haystack to search from
 * @param match_start - The start index in the haystack for the subarray to match from
 * @param match_length - The length of the subarray to extract from haystack
 * @param current_states - The current states of the NFA at each index in the match subarray
 * @param next_states - The next states of the NFA at each index in the match subarray
 * @param capture_group_<group>_ids - The ids of the capture groups in the match subarray
 * @param capture_group_<group>_starts - The start positions of the capture groups in the match subarray
 * @param capture_group_start_indices - The start indices of the capture groups in the match subarray
 * @return - tuple of substring captures as dictated by the regular expression
 */
pub fn regex_match<let MAX_HAYSTACK_LEN: u32, let MAX_MATCH_LEN: u32>(
    in_haystack: [u8; MAX_HAYSTACK_LEN],
    match_start: u32,
    match_length: u32,
    current_states: [Field; MAX_MATCH_LEN],
    next_states: [Field; MAX_MATCH_LEN],
    capture_group_1_id: [Field; MAX_MATCH_LEN],
    capture_group_1_start: [Field; MAX_MATCH_LEN],
    capture_group_start_indices: [Field; NUM_CAPTURE_GROUPS],
) -> (BoundedVec<u8, CAPTURE_1_MAX_LENGTH>) {
    // resize haystack 
    let haystack: [u8; MAX_MATCH_LEN] = select_subarray::<MAX_HAYSTACK_LEN, MAX_MATCH_LEN>(in_haystack, match_start, match_length);

    check_start_state(current_states[0]);
    for i in 0..MAX_MATCH_LEN-1 {
        // match length - 1 since current states should be 1 less than next states
        let in_range = (i < match_length - 1) as Field;
        let matching_states = current_states[i + 1] - next_states[i];
        assert(in_range * matching_states == 0, "Invalid Transition Input");
    }
    let mut reached_end_state = 1;
    for i in 0..MAX_MATCH_LEN {
        let active_capture_groups_at_index = [capture_group_1_id[i]];
        let active_capture_groups_starts_at_index = [capture_group_1_start[i]];
        check_transition_with_captures(
            TRANSITION_TABLE,
            haystack[i] as Field,
            current_states[i],
            next_states[i],
            active_capture_groups_at_index,
            active_capture_groups_starts_at_index,
            reached_end_state
        );
        reached_end_state = reached_end_state * check_accept_state(next_states[i], i as Field, match_length as Field);
    }
    assert(reached_end_state == 0, "Did not reach a valid end state");

    // Capture Group 1
    let capture_1 = capture_substring::<MAX_MATCH_LEN, CAPTURE_1_MAX_LENGTH, 1>(
       haystack,
       capture_group_1_id,
       capture_group_1_start,
       capture_group_start_indices[0]
    );

    (capture_1)
}

