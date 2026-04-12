# Skill Registry

**Delegator use only.** Any agent that launches sub-agents reads this registry to resolve compact rules, then injects them directly into sub-agent prompts. Sub-agents do NOT read this registry or individual SKILL.md files.

See `_shared/skill-resolver.md` for the full resolution protocol.

## User Skills

| Trigger | Skill | Path |
|---------|-------|------|
| Creating pull requests, opening PRs, preparing changes for review | branch-pr | /home/frandev/.config/opencode/skills/branch-pr/SKILL.md |
| Writing Go tests, using teatest, Bubbletea TUI testing | go-testing | /home/frandev/.config/opencode/skills/go-testing/SKILL.md |
| Creating GitHub issues, reporting bugs, requesting features | issue-creation | /home/frandev/.config/opencode/skills/issue-creation/SKILL.md |
| "judgment day", "review adversarial", "dual review", "juzgar", "que lo juzguen" | judgment-day | /home/frandev/.config/opencode/skills/judgment-day/SKILL.md |
| Creating new AI skills, adding agent instructions, documenting patterns | skill-creator | /home/frandev/.config/opencode/skills/skill-creator/SKILL.md |

## Compact Rules

Pre-digested rules per skill. Delegators copy matching blocks into sub-agent prompts as `## Project Standards (auto-resolved)`.

### branch-pr
- MUST have linked issue before creating PR — issue-first workflow enforced
- Branch naming: `issue-{number}-brief-description` format
- PR description MUST reference issue: "Closes #{number}"
- Include rollback plan for risky changes in PR body
- Assign reviewers based on CODEOWNERS or module ownership
- All CI checks MUST pass before merge

### go-testing
- Use `teatest` for Bubbletea TUI testing — it's the standard
- Model-based testing: test the `Update` function directly, not the view
- Use `tea.Program` with `teatest.WithProgramOptions` for integration tests
- Table-driven tests with `[]struct{name string; input tea.Msg; want tea.Model}`
- Assert on final model state, not intermediate frames
- Use `golden` files for complex TUI output snapshots

### issue-creation
- Check for existing issues before creating duplicates
- Use labels: `bug`, `feature`, `enhancement`, `documentation`
- Include reproduction steps for bugs — minimal example required
- Feature requests MUST explain the "why" not just the "what"
- Assign to appropriate team member or leave unassigned for triage
- Link related issues/PRs with "Related to #{number}"

### judgment-day
- Parallel adversarial review — two independent blind judges
- Judges review SAME target simultaneously, no coordination
- Synthesize findings: merge unique issues, escalate conflicts
- Apply fixes, then RE-JUDGE until both pass OR 2 iterations max
- If still failing after 2 iterations → escalate to human
- Document final verdict and lessons learned

### skill-creator
- Skill files live in `{skill-name}/SKILL.md` with YAML frontmatter
- Frontmatter REQUIRED: name, description, license, metadata (author, version)
- Description MUST include "Trigger:" phrase for auto-detection
- Keep compact rules 5-15 lines — actionable constraints only
- Include concrete examples for critical patterns
- Test skill by running its trigger scenarios

## Project Conventions

| File | Path | Notes |
|------|------|-------|
| AGENTS.md | /home/frandev/Documentos/nexusmail--app/.github/AGENTS.md | Index — references files below |
| rules/architecture.md | /home/frandev/Documentos/nexusmail--app/.github/rules/architecture.md | Referenced by AGENTS.md |
| rules/testing.md | /home/frandev/Documentos/nexusmail--app/.github/rules/testing.md | Referenced by AGENTS.md |

Read the convention files listed above for project-specific patterns and rules. All referenced paths have been extracted — no need to read index files to discover more.
