# TLSF Tools Temporal Logic Synthesis Format Files
Utilities and tools for the Temporal Logic Synthesis Format (TLSF): A language
for reactive synthesis specifications

## Parser
The `bison`/`flex` parser is stricter than that of
[syfco](https://github.com/reactive-systems/syfco). This is on purpose in
order to keep things simple. For instance, `ASSUME` and `ASSERT` sections of
`MAIN` need to be in the right order according to the [TLSF language
specification](https://arxiv.org/abs/1604.02284).
