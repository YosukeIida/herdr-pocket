# Pending review work

- Citadel 0.12.1 leaves the TCP channel open when the host key is rejected (`docs/reviews/2026-11-01-fixes-judgement.md` #2). Fix in a fork of `orlandos-nl/Citadel` and send upstream as a PR; until then sshd's `LoginGraceTime` bounds the leak.
- Codex review deferred by the owner (2026-11-02): f69ff32 (one ellipsis on the terminal page), f7045f8 and 8ef7b92 (HTML previews run scripts and load from the network; links leave to Safari), aee704a, b2e76b9 and b5316b8 (terminal gestures while a program takes the mouse: one finger is its drag, two fingers its wheel or the pan). Checked on the iPhone by the owner; not covered by UI tests.
