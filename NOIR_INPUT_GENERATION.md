# Generating Noir Circuit Inputs with TypeScript

This guide explains how to generate circuit inputs for Noir using the zk-regex compiler's WASM bindings.

## Quick Answer

**Yes, you can generate Noir inputs from TypeScript!** The zk-regex compiler compiles to WASM and exposes a `genCircuitInputs` function that returns all the fields needed for Noir circuits.

## Quick Example

```typescript
import compiler, { genCircuitInputs, ProvingFramework } from "zk-regex/compiler/pkg";

// 1. Compile your regex to get the NFA graph
const regexOutput = compiler.genFromRaw(
    "from:([a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,})",  // email sender regex
    [20],  // max bytes for capture group (email address length)
    "EmailSender",
    ProvingFramework.Noir
);

// 2. Generate circuit inputs for a specific email header
const inputsJson = genCircuitInputs(
    regexOutput.graph,              // NFA graph as JSON string
    "from:alice@example.com",       // your haystack (email header)
    1088,                           // max_haystack_len (matches your circuit)
    36,                             // max_match_len (matches your circuit)
    ProvingFramework.Noir           // IMPORTANT: Use Noir framework
);

// 3. Parse the JSON to get all your circuit inputs
const inputs = JSON.parse(inputsJson);
```

## Output Structure

The `genCircuitInputs` function returns a JSON string with the following structure:

```typescript
{
  "type": "noir",
  "in_haystack": [102, 114, 111, 109, ...],     // UTF-8 bytes padded to max_haystack_len
  "match_start": 0,                              // u32 - where match begins
  "match_length": 23,                            // u32 - length of match
  "curr_states": [0, 1, 2, ...],                // Array padded to max_match_len
  "next_states": [1, 2, 3, ...],                // Array padded to max_match_len
  "capture_group_ids": [[1, 1, 1, 0, ...]],     // One array per capture group
  "capture_group_starts": [[1, 0, 0, 0, ...]],  // One array per capture group
  "capture_group_start_indices": [5]             // One index per capture group
}
```

### Field Descriptions

- **`in_haystack`**: Input string as UTF-8 bytes, padded with zeros to `max_haystack_len`
- **`match_start`**: Starting byte index of the regex match within the haystack
- **`match_length`**: Length of the matched substring
- **`curr_states`**: Array of current states in the NFA for each step of the path, padded with zeros
- **`next_states`**: Array of destination states for each step, padded with zeros
- **`capture_group_ids`**: (Optional) For each capture group, a vector of group IDs at each path step
- **`capture_group_starts`**: (Optional) For each capture group, markers (1 for start, 0 for end/inactive) at each step
- **`capture_group_start_indices`**: (Optional) For each capture group, the byte offset where it starts relative to `match_start`

## Mapping to Noir Circuit Parameters

If your Noir circuit has parameters like this:

```rust
fn main(
    email_sender_match_start: u32,
    email_sender_match_length: u32,
    email_sender_current_states: [Field; 36],
    email_sender_next_states: [Field; 36],
    email_sender_capture_group_1_id: [Field; 36],
    email_sender_capture_group_1_start: [Field; 36],
    email_sender_capture_group_start_indices: [Field; 1],
) { ... }
```

Map the generated inputs like this:

```typescript
const inputs = JSON.parse(inputsJson);

const circuitInputs = {
    email_sender_match_start: inputs.match_start,
    email_sender_match_length: inputs.match_length,
    email_sender_current_states: inputs.curr_states,
    email_sender_next_states: inputs.next_states,
    email_sender_capture_group_1_id: inputs.capture_group_ids[0],        // First group
    email_sender_capture_group_1_start: inputs.capture_group_starts[0],  // First group
    email_sender_capture_group_start_indices: inputs.capture_group_start_indices
};
```

## Complete Integration Example

```typescript
import compiler, { genCircuitInputs, ProvingFramework } from "zk-regex/compiler/pkg";

/**
 * Generate circuit inputs for email sender regex matching
 * @param emailHeader - The email header string to match against
 * @returns Circuit inputs ready for Noir proof generation
 */
function generateEmailSenderInputs(emailHeader: string) {
    // Compile the email sender regex (cache this graph for reuse)
    const regexOutput = compiler.genFromRaw(
        "from:([a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,})",
        [20],  // max email address length
        "EmailSender",
        ProvingFramework.Noir
    );

    // Generate inputs for this specific email
    const inputsJson = genCircuitInputs(
        regexOutput.graph,
        emailHeader,
        1088,  // matches circuit's BoundedVec<u8, 1088> size
        36,    // matches circuit's [Field; 36] array size
        ProvingFramework.Noir
    );

    const inputs = JSON.parse(inputsJson);

    return {
        email_sender_match_start: inputs.match_start,
        email_sender_match_length: inputs.match_length,
        email_sender_current_states: inputs.curr_states,
        email_sender_next_states: inputs.next_states,
        email_sender_capture_group_1_id: inputs.capture_group_ids[0],
        email_sender_capture_group_1_start: inputs.capture_group_starts[0],
        email_sender_capture_group_start_indices: inputs.capture_group_start_indices,
    };
}

// Usage
const inputs = generateEmailSenderInputs("from:alice@example.com\r\n");
console.log(inputs);
```

## Two Methods Available

### Method 1: TypeScript/WASM (Recommended for Runtime)

**Pros:**
- Direct integration in TypeScript/JavaScript applications
- Faster for runtime generation
- No subprocess overhead
- Easy to use in web applications

**Setup:**
```bash
# Build WASM package first
bun run build
```

**Usage:**
```typescript
import { genCircuitInputs, ProvingFramework } from "zk-regex/compiler/pkg";

const inputs = JSON.parse(
    genCircuitInputs(graph, haystack, maxHaystackLen, maxMatchLen, ProvingFramework.Noir)
);
```

### Method 2: Rust CLI Binary (Used in Build Scripts)

**Pros:**
- Better for build-time generation
- Used in existing codebase scripts
- Same underlying logic as WASM

**Usage:**
```bash
cargo run --bin zk-regex -- generate-circuit-input \
    --graph-path ./path/to/graph.json \
    --input "your input string" \
    --max-haystack-len 1088 \
    --max-match-len 36 \
    --output-file-path ./output.json \
    --proving-framework noir
```

**From TypeScript (see `noir/scripts/gen-inputs.ts`):**
```typescript
import { executeCargo } from './utils';

executeCargo('run', [
    '--quiet',
    '--bin', 'zk-regex',
    'generate-circuit-input',
    '--graph-path', graphPath,
    '--input', haystack,
    '--max-haystack-len', '1088',
    '--max-match-len', '36',
    '--output-file-path', outputPath,
    '--proving-framework', 'noir',
]);
```

## Important Notes

### Array Size Constraints

The array sizes in your circuit must match the `max_match_len` parameter:

```rust
// If your circuit has [Field; 36], use max_match_len: 36
email_sender_current_states: [Field; 36],
email_sender_next_states: [Field; 36],
```

```typescript
genCircuitInputs(graph, haystack, 1088, 36, ProvingFramework.Noir)
                                    //  ^^
                                    // Must match circuit array size
```

### Haystack Size Constraints

The haystack size in your circuit must match the `max_haystack_len` parameter:

```rust
// If your circuit has BoundedVec<u8, 1088>, use max_haystack_len: 1088
header: BoundedVec<u8, 1088>,
```

```typescript
genCircuitInputs(graph, haystack, 1088, 36, ProvingFramework.Noir)
                                  ^^^^
                                  // Must match circuit haystack size
```

### Input Must Match

If the regex doesn't match your haystack, `genCircuitInputs` will throw error **E4003**:

```typescript
try {
    const inputs = genCircuitInputs(graph, haystack, 1088, 36, ProvingFramework.Noir);
} catch (error) {
    // Error: E4003: No regex match found in input
    console.error("Regex did not match the input haystack");
}
```

### Build WASM First

Before using the WASM bindings, ensure you've built the package:

```bash
# Development build
bun run build

# Production build (optimized)
bun run build-release
```

## API Reference

### `genCircuitInputs()`

```typescript
function genCircuitInputs(
    regexGraphJson: string,      // JSON-serialized NFA graph from genFromRaw/genFromDecomposed
    haystack: string,            // Input string to match against
    maxHaystackLength: number,   // Maximum haystack length (must match circuit)
    maxMatchLength: number,      // Maximum match length (must match circuit array sizes)
    provingFramework: ProvingFramework  // Use ProvingFramework.Noir
): string  // Returns JSON string, parse with JSON.parse()
```

**Error Codes:**
- **E4001**: Input length exceeds maximum
- **E4003**: No regex match found in input
- **E4004**: Path traversal failed (internal consistency issue)

### `genFromRaw()`

```typescript
function genFromRaw(
    pattern: string,             // Regex pattern
    maxSubstringBytes: number[], // Max bytes for each capture group
    templateName: string,        // Name for the generated template
    provingFramework: ProvingFramework  // Use ProvingFramework.Noir
): {
    template: string,            // Generated Noir circuit code
    graph: string                // JSON-serialized NFA graph (use this for genCircuitInputs)
}
```

## Source Code References

- **WASM Bindings**: [`compiler/src/wasm.rs:194-242`](./compiler/src/wasm.rs)
- **Noir Input Types**: [`compiler/src/backend/noir.rs:12-25`](./compiler/src/backend/noir.rs)
- **Circuit Input Generation Logic**: [`compiler/src/backend/shared.rs:127-228`](./compiler/src/backend/shared.rs)
- **CLI Binary Usage**: [`compiler/src/bin/zk-regex.rs:159-188`](./compiler/src/bin/zk-regex.rs)
- **Noir Input Generation Script**: [`noir/scripts/gen-inputs.ts`](./noir/scripts/gen-inputs.ts)
- **TypeScript Types**: [`scripts/utils/types.ts:24-33`](./scripts/utils/types.ts)
- **Example Test Pattern**: [`circom/circuits/tests/email_addr.test.ts:97-148`](./circom/circuits/tests/email_addr.test.ts)

## TypeScript Type Definitions

```typescript
export interface CircuitInput {
  in_haystack: number[];
  match_start: number;
  match_length: number;
  curr_states: number[];
  next_states: number[];
  capture_group_start_indices?: number[];
  capture_group_ids?: number[][];
  capture_group_starts?: number[][];
}

export enum ProvingFramework {
  Circom = "circom",
  Noir = "noir"
}
```

## Advanced: Multiple Capture Groups

If your regex has multiple capture groups:

```typescript
const regexOutput = compiler.genFromRaw(
    "from:([a-z]+)@([a-z.]+)",  // Two capture groups
    [10, 20],                   // Max bytes for each group
    "EmailParts",
    ProvingFramework.Noir
);

const inputsJson = genCircuitInputs(
    regexOutput.graph,
    "from:alice@example.com",
    1088,
    36,
    ProvingFramework.Noir
);

const inputs = JSON.parse(inputsJson);

// Access each capture group
const group1_id = inputs.capture_group_ids[0];      // Username group
const group2_id = inputs.capture_group_ids[1];      // Domain group
const group1_start = inputs.capture_group_starts[0];
const group2_start = inputs.capture_group_starts[1];
const start_indices = inputs.capture_group_start_indices;  // [5, 11] for "alice" and "example.com"
```

## Troubleshooting

### Error: "Module not found: zk-regex/compiler/pkg"

**Solution:** Build the WASM package first:
```bash
bun run build
```

### Error: "E4003: No regex match found in input"

**Solution:** Verify your regex pattern matches the haystack:
```typescript
// Test your regex first
const regex = /from:([a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})/;
console.log(regex.test("from:alice@example.com"));  // Should be true
```

### Array Size Mismatch

**Error in Noir circuit:** "Array length mismatch"

**Solution:** Ensure `max_match_len` matches your circuit's array size:
```typescript
// Circuit has [Field; 36]
genCircuitInputs(graph, haystack, 1088, 36, ProvingFramework.Noir)
                                    //  ^^ Must be 36
```

### Haystack Too Long

**Error:** "E4001: Input length exceeds maximum"

**Solution:** Either:
1. Increase `max_haystack_len` and update your circuit's `BoundedVec` size
2. Truncate your input to fit within the limit

## Performance Tips

1. **Cache the NFA graph**: Call `genFromRaw()` once and reuse the graph for multiple input generations
2. **Use release builds**: Run `bun run build-release` for production use
3. **Batch processing**: Generate multiple inputs in parallel using `Promise.all()`

```typescript
// Cache the graph
const regexOutput = compiler.genFromRaw(...);
const graph = regexOutput.graph;

// Reuse for multiple inputs
const inputs1 = JSON.parse(genCircuitInputs(graph, "from:alice@example.com", 1088, 36, ProvingFramework.Noir));
const inputs2 = JSON.parse(genCircuitInputs(graph, "from:bob@example.com", 1088, 36, ProvingFramework.Noir));
```
