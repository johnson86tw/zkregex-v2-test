import { genCircuitInputs, ProvingFramework } from '@zk-email/zk-regex-compiler'
import graph from './src/email_sender_graph.json'

const inputsJson = genCircuitInputs(
	JSON.stringify(graph), // NFA graph as JSON string
	'from: Alice <alice@gmail.com>', // your haystack (email header)
	1088, // max_haystack_len (matches your circuit)
	36, // max_match_len (matches your circuit)
	ProvingFramework.Noir, // IMPORTANT: Use Noir framework
)

// 3. Parse the JSON to get all your circuit inputs
const inputs = JSON.parse(inputsJson)
console.log(inputs)
/*
{
  type: "noir",
  in_haystack: [
    102, 114, 111, 109, 58, 32, 65, 108, 105, 99, 101, 32, 60, 97, 108, 105, 99,
    101, 64, 103, 109, 97, 105, 108, 46, 99, 111, 109, 62, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ... 988 more items
  ],
  match_start: 0,
  match_length: 29,
  curr_states: [
    3, 4, 5, 6, 7, 15, 16, 16, 16, 16, 16, 16, 16, 17, 18, 18, 18, 18, 18, 19, 20,
    21, 22, 23, 31, 32, 33, 34, 35, 0, 0, 0, 0, 0, 0, 0
  ],
  next_states: [
    4, 5, 6, 7, 15, 16, 16, 16, 16, 16, 16, 16, 17, 18, 18, 18, 18, 18, 19, 20, 21,
    22, 23, 31, 32, 33, 34, 35, 36, 0, 0, 0, 0, 0, 0, 0
  ],
  capture_group_ids: [
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]
  ],
  capture_group_starts: [
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]
  ],
  capture_group_start_indices: [ 13 ],
}
*/
