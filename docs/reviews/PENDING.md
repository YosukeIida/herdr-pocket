# Pending review work

- Citadel 0.12.1 leaves the TCP channel open when the host key is rejected (`docs/reviews/2026-11-01-fixes-judgement.md` #2). Fix in a fork of `orlandos-nl/Citadel` and send upstream as a PR; until then sshd's `LoginGraceTime` bounds the leak.
