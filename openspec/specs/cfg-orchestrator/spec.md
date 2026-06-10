# cfg-orchestrator Specification

Routes user intent to domain skills via parsing, registry, delegation.

## Requirements

### Requirement: Intent Parsing
MUST parse natural-language requests into domain, action, key, value.

#### Scenario: Theme change parsed
- GIVEN "change ghostty theme to tokyo-night"
- WHEN orchestrator processes request
- THEN domain=ghostty, action=modify, key=theme, value=tokyo-night

### Requirement: Domain Routing
MUST discover domain skills from registry and delegate.

#### Scenario: Domain found
- GIVEN registry lists `cfg-ghostty`
- WHEN orchestrator matches domain ghostty
- THEN loads skill, delegates action

#### Scenario: Domain not found
- GIVEN no registry entry for domain
- WHEN orchestrator searches
- THEN reports error with closest-match suggestion

### Requirement: Ambiguity Handling
SHOULD detect ambiguous requests and clarify.

#### Scenario: Ambiguous request
- GIVEN request matches multiple domains
- WHEN orchestrator cannot resolve
- THEN asks user to clarify target
