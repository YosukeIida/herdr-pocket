# Agent and space views: Chat/Terminal switching and the project file tree

Status: implemented. Decided: space cards show Chat (item 1) without their own switch, following the app-wide mode; Chat opens with the last 150 entries and loads earlier ones on request; after loading, the view stays at the top, at the oldest loaded message.

## What the app does now

| Screen | How it is reached | What it shows | Chat/Terminal switch | Files / Changes |
|---|---|---|---|---|
| Space (`SpaceView`) | the space list | one card per pane; the card body is the terminal's plain-text tail (`TerminalPreview`) | none on the card | toolbar buttons; folder = the terminal on screen (83f9b36) |
| Agent (`AgentScreen`) | tapping an agent row **or a pane card in a space** | Chat or the live terminal | toolbar button, Claude Code and Codex only; the choice is app-wide (`@AppStorage("agentViewMode")`) | none |

So the two paths already meet: a pane card opens the same `AgentScreen` as the agent list, with the switch. What the space page lacks is Chat on the card itself, and what the agent page lacks is Files.

## Proposal

### 1. Chat on the space page

The card body follows the app-wide mode: in Chat mode a Claude Code or Codex pane shows the last few messages instead of the terminal tail; other programs keep the terminal tail. The card header gets the same switch button as `AgentScreen`, and tapping the card opens `AgentScreen` in that mode.

Cost: each visible card reads its transcript on the box (the Chat script). A phone shows one card at a time, but the page view builds its neighbours too; an iPad grid shows all of them. Reads happen when the turn or status changes, as `TerminalPreview` does now.

Rejected: a separate Chat tab inside the space page. It would duplicate `AgentScreen`.

### 2. Files and Changes on the agent page

`AgentScreen` gets Files and Changes, in a `…` menu next to the switch so the title keeps its width.

The root is the agent's project root: `git rev-parse --show-toplevel` run in the agent process's working directory, else that directory when it is not in a git repository. It is resolved when the sheet opens and does not follow later moves.

Why the agent process's directory is stable: Claude Code and Codex run their shell commands in child shells, so their own `cd` does not change the agent process's working directory, which herdr-core reports as `foreground.cwd` (the app's `TerminalRecord.cwd`). It stays the directory the agent was started in. Not checked on the box yet: that `foreground.cwd` is unchanged after Claude Code runs `cd` in a turn.

### 3. One rule for both pages

The space page uses the same root: the project root of the terminal on screen, instead of its current directory. One function, `AppStore.projectRoot(of: address)`, serves Files and Changes on both pages. Changes already resolves the git root itself, so only Files changes behaviour: a terminal sitting in a subfolder opens at the repository root.

## Order of work

1. `projectRoot(of:)`, Files and Changes on `AgentScreen`, the space page switched to the project root. UI test: open Files from an agent and see the repository root.
2. Chat preview on the space cards.
3. Codex review of each step.

## Open question

- Does item 1 of the proposal match what is wanted, or is the existing switch after tapping a card enough? If it is enough, step 2 is dropped.
