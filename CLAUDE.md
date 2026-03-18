# AI Rules

This file provider guidance to AI assistants when working with this repository

## Specifications
Modules and hosts have `SPEC.md` files documenting their purposes, usage examples and necessary setup instructions. **Before working on a module or a host, you MUST ALWAYS read its spec. No exceptions:**
```
modules/system/{module-name}/SPEC.md
modules/user/{module-name}/SPEC.md
hosts/{host-name}/SPEC.md
```

When your changes affect observable behavior (configuration changes, required dependencies, purpose of the module), update the corresponding `SPEC.md` to reflect the changes. A PostToolUse hook will remind you when you modify the files in a module or hosts that has a spec.
