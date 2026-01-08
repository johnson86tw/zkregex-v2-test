mod rac_body;

global MAX_EMAIL_BODY_LENGTH: u32 = 1280;
global MAX_MATCH_LENGTH: u32 = 150;

global HEX_CHAR_TABLE: [u8; 128] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

/// Converts a hex ASCII character to its nibble value (0-15)
fn parse_hex_char(c: u8) -> u8 {
    assert(HEX_CHAR_TABLE[c as u32] == 1, "Invalid hex character");

    // Convert ASCII to nibble value
    if (c >= 48) & (c <= 57) {
        // '0'-'9': ASCII 48-57 -> 0-9
        c - 48
    } else if (c >= 65) & (c <= 70) {
        // 'A'-'F': ASCII 65-70 -> 10-15
        c - 65 + 10
    } else {
        // 'a'-'f': ASCII 97-102 -> 10-15
        c - 97 + 10
    }
}

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
) -> pub (Field, Field, [Field; 2]) {
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

    // Convert rac_body_capture_1 from BoundedVec<u8> to Field
    let mut number: Field = 0;
    for i in 0..5 {
        if i < rac_body_capture_1.len() {
            let byte: u8 = rac_body_capture_1.get_unchecked(i);
            let digit: u8 = byte - 48; // Convert ASCII to digit value ('0' is 48)
            number = number * 10 + (digit as Field);
        }
    }

    // Convert rac_body_capture_2 to Ethereum address Field
    // Parse 40 hex characters into 20 bytes (skip "0x" prefix)
    let mut address_bytes: [u8; 20] = [0; 20];

    for i in 0..20 {
        // Each byte is formed from 2 hex characters (starting after "0x")
        let high_char = rac_body_capture_2.get_unchecked(2 + i * 2);
        let low_char = rac_body_capture_2.get_unchecked(2 + i * 2 + 1);

        // Parse hex chars to nibbles and combine
        let high_nibble = parse_hex_char(high_char);
        let low_nibble = parse_hex_char(low_char);

        // Combine: high nibble is upper 4 bits
        address_bytes[i] = (high_nibble * 16) + low_nibble;
    }

    // Convert 20-byte array to Field (big-endian)
    let address_field = Field::from_be_bytes::<20>(address_bytes);

    // Convert rac_body_capture_3 to title hash [Field; 2]
    // Parse 64 hex characters into 32 bytes (skip "0x" prefix)
    let mut hash_bytes: [u8; 32] = [0; 32];

    for i in 0..32 {
        // Each byte is formed from 2 hex characters (starting after "0x")
        let high_char = rac_body_capture_3.get_unchecked(2 + i * 2);
        let low_char = rac_body_capture_3.get_unchecked(2 + i * 2 + 1);

        // Parse hex chars to nibbles and combine
        let high_nibble = parse_hex_char(high_char);
        let low_nibble = parse_hex_char(low_char);

        // Combine: high nibble is upper 4 bits
        hash_bytes[i] = (high_nibble * 16) + low_nibble;
    }

    // Split 32 bytes into two 16-byte chunks and convert to Fields
    let mut upper_bytes: [u8; 16] = [0; 16];
    let mut lower_bytes: [u8; 16] = [0; 16];

    for i in 0..16 {
        upper_bytes[i] = hash_bytes[i];
        lower_bytes[i] = hash_bytes[i + 16];
    }

    let title_hash = [Field::from_be_bytes::<16>(upper_bytes), Field::from_be_bytes::<16>(lower_bytes)];

    (number, address_field, title_hash)
}
