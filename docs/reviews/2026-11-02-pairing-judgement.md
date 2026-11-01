# Judgement: review of QR pairing (2026-11-02)

Reviewed commit: 2f98a3b. Raw review: `2026-11-02-pairing-codex.md` (Codex gpt-6.1-sol, medium, labteam, read-only).

| # | Finding | Decision | Why / what changed |
|---|---|---|---|
| 1 | A code silently replaces a host key already pinned for that host:port | Fix | `pair` refuses a code whose host key differs from the pin and names both fingerprints; the person forgets the old key in Settings first if the box was reinstalled |
| 2 | A newline in the name argument adds a second, unrestricted line to authorized_keys | Fix | The name may hold only letters, digits, `.`, `_`, `-`; the public key file must be one line |
| 3 | A signal skips the EXIT trap and leaves the private key in the temp folder | Fix | Cleanup also runs on HUP, INT and TERM |
| 4 | An authorized_keys without a final newline joins our line onto the last one | Fix | A newline is added first when the file does not end in one |
| 5 | Settings shows the app key for a paired machine, which uses its own key | Fix | The form shows the key the machine is reached with and says a paired machine keeps its own key |
| 6 | A failed host key write after the key write loses the old key | Fix | The pin is checked and written before the key; the Keychain updates in place, so a failed key write keeps the old key |
| — | JSON helper leaves tab and CR unescaped | Fix | One awk pass escapes `\`, `"`, tab, CR and joins lines with `\n` (round-trip checked with jq) |
| — | README says the first connect always shows the fingerprint | Fix | README (EN, JA) notes that pairing skips it and never replaces a pinned key |

Not changed: `restrict,command=` limits SSH features, not what herdr-core connect can do (machine.exec runs anything); that is herdr-core's own security model (`docs/security.md`: SSH is the boundary). Removing a machine in the app does not remove its line on the box; README says to delete the line to unpair.

Checked: HerdrKit tests; `pair.sh` against a fake HOME (bad name refused, file without a final newline, code decodes); `testPairWithPastedCode` on the simulator after the fixes (fresh install reaches home without a host key prompt).
