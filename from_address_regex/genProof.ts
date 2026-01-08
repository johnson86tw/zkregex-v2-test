import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { UltraHonkBackend } from '@aztec/bb.js'
import { Noir } from '@noir-lang/noir_js'
import { genCircuitInputs, ProvingFramework } from '@zk-email/zk-regex-compiler'
import graph from './src/email_sender_graph.json' assert { type: 'json' }

const __dirname = path.dirname(fileURLToPath(import.meta.url))

async function main(headerInput?: string) {
	// Check circuit exists
	const circuitPath = path.join(__dirname, './target/zkregex.json')
	if (!fs.existsSync(circuitPath)) {
		console.error('[ERROR]: Circuit not compiled. Run: nargo compile')
		process.exit(1)
	}

	// Load circuit
	const circuit = JSON.parse(fs.readFileSync(circuitPath, 'utf-8'))
	console.log(`Circuit: ${circuitPath}`)
	console.log(`Noir version: ${circuit.noir_version}`)

	// Use provided header or default test case
	const header = headerInput || 'from: Alice <alice@gmail.com>'
	console.log(`\nPreparing inputs for header: "${header}"`)

	// Validate header length
	if (header.length > 36) {
		console.error(`\n[ERROR]: Header too long!`)
		console.error(`  Header length: ${header.length} chars`)
		console.error(`  Circuit max_match_len: 36 chars`)
		console.error(`  The entire matched pattern (including "from: ... <...@...>") must be ≤36 chars`)
		console.error(`\n  Suggestion: Use shorter names/emails (e.g., "from: Jo <jo@x.com>")`)
		process.exit(1)
	}

	// Generate circuit inputs using zk-regex compiler
	const inputsJson = genCircuitInputs(
		JSON.stringify(graph), // NFA graph as JSON string
		header, // haystack (email header)
		1088, // max_haystack_len (matches circuit)
		36, // max_match_len (matches circuit)
		ProvingFramework.Noir, // IMPORTANT: Use Noir framework
	)

	// Parse the generated inputs
	if (!inputsJson) {
		console.error('[ERROR]: Failed to generate circuit inputs')
		process.exit(1)
	}

	const rawInputs = JSON.parse(inputsJson)
	console.log('\nGenerated inputs:')
	console.log(`- match_start: ${rawInputs.match_start}`)
	console.log(`- match_length: ${rawInputs.match_length}`)
	console.log(`- capture groups: ${rawInputs.capture_group_ids.length}`)

	// Map to circuit input format
	const circuitInputs = {
		header: {
			storage: rawInputs.in_haystack,
			len: header.length.toString(),
		},
		email_sender_match_start: rawInputs.match_start.toString(),
		email_sender_match_length: rawInputs.match_length.toString(),
		email_sender_current_states: rawInputs.curr_states.map((s: number) => s.toString()),
		email_sender_next_states: rawInputs.next_states.map((s: number) => s.toString()),
		email_sender_capture_group_1_id: rawInputs.capture_group_ids[0].map((id: number) => id.toString()),
		email_sender_capture_group_1_start: rawInputs.capture_group_starts[0].map((start: number) => start.toString()),
		email_sender_capture_group_start_indices: rawInputs.capture_group_start_indices.map((idx: number) =>
			idx.toString(),
		),
	}

	console.log('\nInitializing Noir and UltraHonk backend...')
	const noir = new Noir(circuit)
	const backend = new UltraHonkBackend(circuit.bytecode)

	try {
		console.log('Executing circuit...')
		const { witness, returnValue } = await noir.execute(circuitInputs)

		console.log('\nCircuit Outputs:')
		if (returnValue) {
			// The circuit returns the captured email sender
			if (typeof returnValue === 'object' && returnValue !== null && 'storage' in returnValue) {
				const storage = returnValue.storage as any[]
				const len = (returnValue.len as number) || 20
				const captured = storage
					.slice(0, len)
					.map((byte: any) => String.fromCharCode(typeof byte === 'string' ? parseInt(byte) : byte))
					.join('')
				console.log(`Captured email sender: "${captured}"`)
			} else {
				console.log(`Return value: ${JSON.stringify(returnValue, null, 2)}`)
			}
		}

		console.log('\nGenerating UltraHonk proof...')
		const startProve = Date.now()
		const proof = await backend.generateProof(witness)
		const proveTime = ((Date.now() - startProve) / 1000).toFixed(2)

		console.log(`✓ Proof generated in ${proveTime}s`)
		console.log(`Proof size: ${(proof.proof.length / 1024).toFixed(2)} KB`)

		// Save outputs
		const targetDir = path.join(__dirname, './target')
		const proofPath = path.join(targetDir, 'proof.bin')
		const publicInputsPath = path.join(targetDir, 'public_inputs.json')

		fs.writeFileSync(proofPath, proof.proof)
		fs.writeFileSync(publicInputsPath, JSON.stringify(proof.publicInputs, null, 2))

		console.log(`\nSaved: ${proofPath}`)
		console.log(`Saved: ${publicInputsPath}`)

		console.log('\nVerifying proof...')
		const startVerify = Date.now()
		const verified = await backend.verifyProof(proof)
		const verifyTime = ((Date.now() - startVerify) / 1000).toFixed(2)

		if (verified) {
			console.log(`✓ Proof verified in ${verifyTime}s`)
		} else {
			console.error('✗ [FAILED]: Proof verification failed')
			process.exit(1)
		}
	} finally {
		await backend.destroy()
	}
}

// Parse command line arguments
const headerArg = process.argv[2]

if (process.argv.includes('--help') || process.argv.includes('-h')) {
	console.log('Usage: bun script/genProof.ts [header-string]')
	console.log('\nExamples:')
	console.log('  bun script/genProof.ts')
	console.log('  bun script/genProof.ts "from: Bob <bob@gmail.com>"')
	process.exit(0)
}

main(headerArg).catch(err => {
	console.error('[ERROR]:', err.message)
	if (err.stack) console.error(err.stack)
	process.exit(1)
})
