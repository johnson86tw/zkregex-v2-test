use zkemail::{headers::email_address::get_email_address, MAX_EMAIL_ADDRESS_LENGTH, Sequence};

global MAX_EMAIL_HEADER_LENGTH: u32 = 960;

// acir: 15522
// bb circuit size: 22425
fn main(
    header: BoundedVec<u8, MAX_EMAIL_HEADER_LENGTH>,
    // from address extraction
    from_header_seq: Sequence,
    from_address_seq: Sequence,
) -> pub (BoundedVec<u8, MAX_EMAIL_ADDRESS_LENGTH>) {
    // check the header and body lengths are within bounds
    assert(header.len() <= MAX_EMAIL_HEADER_LENGTH, "Header exceeds maximum length");

    let from = comptime { "from".as_bytes() };
    let from_address = get_email_address(header, from_header_seq, from_address_seq, from);
    (from_address)
}
