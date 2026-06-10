# cfg-ghostty Specification

Ghostty terminal config: themes, fonts, keybindings, validation.

## Requirements

### Requirement: Theme Management
MUST support theme changes.

#### Scenario: Theme switched
- GIVEN user requests "tokyo-night"
- WHEN cfg-ghostty edits config
- THEN theme updated, `ghostty +validate-config` passes

### Requirement: Font Changes
MUST support font family and size changes.

#### Scenario: Font updated
- GIVEN user requests "JetBrains Mono" size 14
- WHEN cfg-ghostty edits font settings
- THEN font-family and font-size updated

### Requirement: Keybinding Modification
MUST support keybinding changes.

#### Scenario: Keybinding added
- GIVEN user requests `ctrl+shift+t=new_tab`
- WHEN cfg-ghostty edits keybind section
- THEN keybinding appended, validated

### Requirement: Pre-commit Validation
MUST run `ghostty +validate-config` before commit.

#### Scenario: Pass
- GIVEN config staged
- WHEN validation succeeds
- THEN commit proceeds

#### Scenario: Fail
- GIVEN invalid config
- WHEN validation runs
- THEN commit blocked, error reported

### Requirement: Hardware Awareness
SHOULD read AGENTS.md for Broadwell GPU constraints.

#### Scenario: GPU feature flagged
- GIVEN AGENTS.md notes GPU limits
- WHEN GPU-intensive feature requested
- THEN system warns about hardware
