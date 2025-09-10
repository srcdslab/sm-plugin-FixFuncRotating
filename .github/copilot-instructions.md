# Copilot Instructions for FixFuncRotating Plugin

## Repository Overview
This repository contains a single SourcePawn plugin **FixFuncRotating** that fixes issues with `func_rotating` entities in Source engine games. The plugin specifically addresses problems with the `StartForward` and `StopAtStartPos` inputs by using DHooks to detour engine functions and modify entity behavior.

**Target Environment:**
- SourceMod 1.11.0+ (currently targeting 1.11.0-git6917)
- Source engine games (primarily Counter-Strike series)
- Linux servers (gamedata includes Linux signatures)

## Project Structure

```
├── .github/
│   ├── workflows/ci.yml          # GitHub Actions CI/CD pipeline
│   └── copilot-instructions.md   # This file
├── addons/sourcemod/
│   ├── gamedata/
│   │   └── FixFuncRotating.games.txt  # Function signatures for DHooks
│   └── scripting/
│       └── FixFuncRotating.sp    # Main plugin source code
├── sourceknight.yaml             # Build configuration
└── .gitignore
```

## Build System & CI/CD

### SourceKnight Build Tool
This project uses **SourceKnight** as its build system:
- Configuration: `sourceknight.yaml`
- Automatic dependency management (downloads SourceMod 1.11.0-git6917)
- Compiles `.sp` files to `.smx` plugins
- Packages plugins with gamedata for distribution

### GitHub Actions Pipeline
The CI/CD pipeline (`.github/workflows/ci.yml`):
1. **Build**: Compiles plugin using SourceKnight action
2. **Package**: Creates distribution with plugins and gamedata
3. **Tag**: Auto-tags builds from main/master branch as "latest"
4. **Release**: Creates GitHub releases with tar.gz packages

To trigger builds:
- Push to any branch triggers build
- Pushes to main/master create releases tagged as "latest"
- Git tags create versioned releases

## SourcePawn Development Guidelines

### Language Standards
- **SourcePawn version**: Latest compatible with SourceMod 1.11+
- **Required pragmas**: Always include at top of files:
  ```sourcepawn
  #pragma semicolon 1
  #pragma newdecls required
  ```

### Code Style & Naming Conventions
- **Indentation**: 4 spaces (converted to tabs)
- **Variables**: 
  - Local variables and parameters: `camelCase` (e.g., `flNewSpeed`, `checkAxis`)
  - Global variables: `PascalCase` with `g_` prefix (e.g., `g_CFuncRotating_StartForward`)
  - Function names: `PascalCase` (e.g., `CFuncRotating_InputStartForward`)
- **Constants**: ALL_CAPS with underscores
- **Remove trailing whitespace**

### Memory Management
- Use `Handle` for DHooks detours (current pattern in codebase)
- **Important**: Use `delete` instead of `CloseHandle()` for newer SourceMod versions
- Never check for null before `delete` - it's safe to call on null handles
- For StringMap/ArrayList: Use `delete` instead of `.Clear()` to prevent memory leaks

### DHooks Implementation Patterns
When working with DHooks in this codebase:

```sourcepawn
// 1. Load gamedata
Handle hGameConf = LoadGameConfigFile("FixFuncRotating.games");
if(hGameConf == INVALID_HANDLE) {
    LogError("Couldn't load gamedata!");
    return;
}

// 2. Get function address
Address pFunction = GameConfGetAddress(hGameConf, "FunctionName");
if(!pFunction) {
    LogError("Could not find function address");
    return;
}

// 3. Create detour
Handle detour = DHookCreateDetour(pFunction, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);

// 4. Add parameters if needed
DHookAddParam(detour, HookParamType_Float);

// 5. Enable detour
if(!DHookEnableDetour(detour, false, CallbackFunction)) {
    LogError("Could not enable detour");
}
```

### Error Handling
- Always check gamedata loading with `INVALID_HANDLE`
- Validate all function addresses before creating detours
- Log meaningful error messages using `LogError()`
- Use proper return values (`MRES_Ignored`, etc.)

## Plugin-Specific Context

### What This Plugin Does
The **FixFuncRotating** plugin fixes two specific issues with `func_rotating` entities:

1. **StartForward Input Fix**: Sets `m_bStopAtStartPos` to false when StartForward is called
2. **StopAtStartPos Behavior Fix**: Prevents rotation overshoot when stopping at start position

### Key Functions
- `CFuncRotating_InputStartForward()`: Detours the StartForward input handler
- `CFuncRotating_UpdateSpeed()`: Detours speed updates to fix stopping behavior
- Both use `MRES_Ignored` return to allow original function execution

### Entity Properties Used
- `m_bStopAtStartPos`: Boolean flag for stopping behavior
- `m_vecMoveAng`: Movement angles vector
- `m_angStart`: Starting angles
- `m_angRotation`: Current rotation angles  
- `m_vecAngVelocity`: Angular velocity vector

### Gamedata Requirements
The plugin requires function signatures in `FixFuncRotating.games.txt`:
- `CFuncRotating::UpdateSpeed`: For speed change detours
- `CFuncRotating::InputStartForward`: For input handling detours

Currently only includes Linux signatures - Windows support would require additional signatures.

## Common Development Tasks

### Adding New Game Support
1. Add new game section to `addons/sourcemod/gamedata/FixFuncRotating.games.txt`
2. Include both Linux and Windows signatures for new game
3. Test function address resolution

### Updating SourceMod Version
1. Modify `sourceknight.yaml` dependency version
2. Test for any API compatibility issues
3. Update backward compatibility code if needed

### Adding Windows Support
1. Find Windows function signatures for target games
2. Add Windows signatures to gamedata file
3. Test on Windows server environment

### Debugging Function Detours
1. Add debug logging to detour callbacks
2. Verify gamedata function signatures match target game version
3. Check entity property names and types with `sm_dump_classes`
4. Use `sm_cvar mp_developer 1` for additional engine debug info

## Testing & Validation

### Local Testing
Since SourceKnight isn't available in all environments:
1. Use a SourceMod development server
2. Load the plugin and test with `func_rotating` entities
3. Verify both StartForward and StopAtStartPos behaviors work correctly
4. Check server logs for any detour errors

### CI Testing
The GitHub Actions pipeline validates:
- Plugin compilation succeeds
- Packaging includes all required files
- No compilation warnings or errors

### Manual Validation Steps
1. Load plugin on test server: `sm plugins load FixFuncRotating`
2. Create test map with `func_rotating` entities
3. Test StartForward input behavior
4. Test StopAtStartPos functionality
5. Monitor server console for errors

## Troubleshooting

### Common Issues
- **Gamedata loading fails**: Check file path and formatting
- **Function address not found**: Verify signatures match game version
- **Detour fails**: Check calling convention and parameter types
- **Entity properties not found**: Verify property names with current SDK

### Debug Commands
- `sm plugins list`: Check if plugin loaded successfully
- `sm plugins info FixFuncRotating`: Show plugin details
- `sm_dump_classes CFuncRotating`: Show entity properties (if available)

### Backward Compatibility
The plugin includes compatibility code for SourceMod < 1.13:
```sourcepawn
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR < 13
// FloatMod implementation for older versions
#endif
```

## Performance Considerations
- DHooks detours add minimal overhead when functions are called
- The UpdateSpeed detour only performs calculations when `m_bStopAtStartPos` is true
- Entity property access is optimized and should not impact server performance
- Consider the frequency of func_rotating entities in target maps

## Documentation Standards
- No unnecessary header comments on plugin files
- Document complex logic sections with inline comments
- Keep gamedata comments minimal and functional
- Update version numbers in plugin info when making changes

## Release Process
1. Update version in plugin info structure
2. Commit changes to main/master branch
3. GitHub Actions automatically creates "latest" release
4. For versioned releases, create git tags (e.g., `v1.0.2`)
5. Monitor release artifacts for completeness

This plugin demonstrates proper SourcePawn development practices including DHooks usage, entity manipulation, gamedata integration, and modern SourceMod compatibility patterns.