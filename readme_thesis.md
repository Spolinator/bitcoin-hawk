# Instructions for building

The repo contains a dockerfile in order to be able to build specifically for Amazon Linux 2023, which is the version
required for depoyment on AWS. For local use, you can build the code according to the official [build instructions](https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md).

**To build for Amazon Linux 2023:**
1. Build the container and the binaries:
```
DOCKER_BUILDKIT=1 docker build -t bitcoin-hawk-aws --output type=local,dest=./aws-build .
```

# What files were modified?
- for exact changes see the commit history
- Revert to before the "v1.0" tag to not include the uncompatible changes for easy benchmarking.
  
## 1. Adding the new TX Type

### Node

- *script.cpp*
    - `IsWitnessProgram`: A new witness version now also makes sense: 2 (defined by `OP_2`).
- *Interpreter.cpp:*
    - New sigversion added: `QUANTUM`
    -  m_bip143_segwit_ready is also used for quantum TXs
    -  VerifyWitnessProgram: case added for P2QPKH: takes witversion=2 for quantum TX. Behaviour is similar to witversion=0. **No quantum scripts supported, only key hash!**
    -  Quantum sigops also count as 1
    -  Added a `SCRIPT_VERIFY_QUANTUM` flag
    -  `EvalChecksigQuantum()` is added (but unimplemented): handle quantum signatures differently.
- *solver.h/.cpp*
    - new TxoutType added: `TxoutType::WITNESS_V2_QUANTUM_KEYHASH`
    - `Solver()` supports new TxoutType
- *validation.cpp*:
    - `getBlockScriptFlags()`: added `SCRIPT_VERIFY_QUANTUM` flag to default block flags (source of flags in scripts)
- *sign.cpp*:
    - `CreateSig()`: add support for `QUANTUM`; behaves the same as `WITNESS_V0`
    - `SignStep()` : add case for `TxoutType::WITNESS_V2_QUANTUM_KEYHASH`: same as p2wpkh
    - `ProduceSignature()` : add case for `TxoutType::WITNESS_V2_QUANTUM_KEYHASH`: same as p2wpkh
- *addresstype.cpp/.h*:
    - `ExtractDestination()`: add case for `TxoutType::WITNESS_V2_QUANTUM_KEYHASH`
    - Added destination `CTxDestination::WitnessV2QuantumKeyHash` + related functions: represents the hash of the new quantum key-hash type: **HASH160**
    - extend `CScriptVisitor` for `WitnessV2QuantumKeyHash`
- *descriptor.cpp*:
    - new descriptor added `QPKHDescriptor` : behaves the same as WPKH. !OutputType Bech32m.
    - `ParseScript()` : new case added for p2qkh
    - `InferScript()` : new case added for p2qkh
- *key_io.cpp* :
    - Added visitor for `DestinationEncoder::WitnessV2QuantumKeyHash`: bech32m
    - Added case for `DestinationDecoder::WitnessV2QuantumKeyHash`
    - Note: "*false if it is a valid Bech32 address for a different network*"
- *outputtype.cpp*:
    - `OutputTypeFromDestination` updated
- *signingprovider.cpp*
    - `GetKeyForDestination` : add case for `CTxDestination::WitnessV2QuantumKeyHash`

### Wallet
- *addresses.cpp*
    - add instance for `DescribeWalletAddressVisitor`

## 2. Adding PQ Crypto support
A valid signature should not be DER-encoded.
A valid signature should be appended a 1-byte suffix to denote the signature type (https://learnmeabitcoin.com/technical/keys/signature/#sighash).

- *interpreter.h*:
    - Add constant `QUANTUM_PUBKEY_SIZE`
    - Add `VerifyQuantumSignature()` and `CheckQuantumSignature()` methods to `BaseSignatureChecker` and its extentions.
- *interpreter.cpp*:
    - Implement `EvalChecksigQuantum()`
    - `CheckQuantumSignature()`
    - `VerifyQuantumSignature()`
    - `SignatureHash()`: `SeigVersion::QUANTUM` behaves the same as witness_V0
    - `ExecuteWitnessScript()`: different stack item size limit for quantum scripts
- *pubkey.h/cpp*:
    - Add `CQuantumPubKey` class and its implementations
    - `CQuantumPubKey::Verify()`: HAWK setting focusses on speed, not on memory usage
- *script.h*
    - Added constant `MAX_SCRIPT_ELEMENT_SIZE_QUANTUM`: max witness stack element size for quantum scripts
- *Build*
    - Added hawk library files
    - Added hawk function in `src/CMakeList`
    - Added *hawk.cmake* in */cmake*
    - The hawk build.py is run at CMake configuration time. Delete the build directory or manually run build.py to switch between hawk implementations.
- *descriptor.cpp*:
    - `ComboDescriptor::MakeScripts`: add case for p2qkh
## 3. Easy benchmarking
- *src/rpc/rawtransaction_util.cpp*:
    - ParseOutputs: removed duplicate address check to allow for quick chopping in small UTXO for benchmarking
- *src/consensus/validation.cpp* & tx_verify.cpp:
    - maybeupdatemempoolforreorg & checktxinputs: Set coinbase_maturiy to 0: easier for benchmarking
- *policy/policy.h*
    - Increase cluster limits for easy benchmarking setup
- *src/txgraph.h*
    - Increase cluster limit from 100 to 3000