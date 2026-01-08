use zkregex::utils::{
   select_subarray,
   captures::capture_substring,
   sparse_array::SparseArray,
   transitions::check_transition_with_captures
};

global TRANSITION_TABLE: SparseArray<89, Field> = SparseArray {
    keys: [0x00000000, 0x00025654, 0x00025655, 0x00036b6a, 0x00046b6a, 0x00057372, 0x00067c7b, 0x00077776, 0x00087574, 0x0009807f, 0x000a8887, 0x000b1f1f, 0x000b2020, 0x000b2121, 0x000b2222, 0x000b2323, 0x000b3636, 0x000b504f, 0x000b9698, 0x000b969a, 0x000b979b, 0x000b989c, 0x000b999d, 0x000b9a9e, 0x000b9b9c, 0x000b9b9f, 0x000b9ca0, 0x000b9da1, 0x000b9ea2, 0x000b9fa3, 0x000ba0a4, 0x000bb5ba, 0x000bb6b7, 0x000bbec2, 0x000bbfc3, 0x000bc5c9, 0x000cdad9, 0x000d9a9f, 0x000db4b5, 0x000efdfa, 0x000f9ea0, 0x0010a1a2, 0x001204fe, 0x00130800, 0x0013564e, 0x0014a09f, 0x00155a59, 0x00155a5a, 0x00155b5a, 0x00155b5b, 0x00155c5b, 0x00155c5c, 0x00155d5c, 0x00155d5d, 0x00155e5d, 0x00155e5e, 0x00155f5e, 0x00155f5f, 0x0015605f, 0x00156060, 0x00156160, 0x00156161, 0x00156261, 0x00156262, 0x00156362, 0x00156363, 0x00156b6a, 0x00156b6b, 0x00156c6b, 0x00156c6c, 0x00156d6c, 0x00156d6d, 0x00156e6d, 0x00156e6e, 0x00156f6e, 0x00156f6f, 0x0015706f, 0x00157070, 0x00158b8a, 0x00158b8b, 0x00158c8b, 0x00158c8c, 0x00158d8c, 0x00158d8d, 0x00158e8d, 0x00158e8e, 0x00158f8e, 0x00158f8f, 0x0015908f, 0x00159090, 0x00162a29],
    values: [0x00000000, 0x00000000, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000007, 0x00000001, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000005, 0x00000000],
    maximum: 0x00162a29
};

pub global CAPTURE_1_MAX_LENGTH: u32 = 42;
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
    let accept_state_reached = (next_state - 21);
    let accept_state_reached_bool = (accept_state_reached == 0) as Field;

    // check if the haystack index is the asserted match length
    // should equal 1 since haystack_index should be 1 less than asserted_match)length
    let asserted_path_traversed = (asserted_match_length - haystack_index == 1) as Field;

    (1 - (accept_state_reached_bool * asserted_path_traversed))
}

/**
 * RecipientRegexRegex matching function
 * Regex: Recipient:\\s*(0x[0-9a-fA-F]+)
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

