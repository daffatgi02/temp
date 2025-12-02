# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Roblox Studio project using Rojo for synchronization with VS Code. The project is a Roblox game with advanced UI systems, admin functionality, and player features.

## Rojo Configuration

The project uses `default.project.json` for Rojo configuration with the following structure:
- `src/ReplicatedStorage` → ReplicatedStorage
- `src/ServerScriptService` → ServerScriptService
- `src/StarterGui` → StarterGui
- `src/StarterPack` → StarterPack
- `src/StarterPlayer/StarterPlayerScripts` → StarterPlayer/StarterPlayerScripts

## Common Development Commands

### Build and Sync
```bash
# Sync project with Roblox Studio
rojo serve

# Build project (if needed)
rojo build
```

### Testing in Roblox Studio
- Open Roblox Studio
- Use the Rojo plugin to connect to the serving project
- Test functionality in Studio environment

## Architecture Overview

### Core Systems

**TopbarPlus Icon System (`src/ReplicatedStorage/Icon/`)**
- Advanced topbar UI system with theming support
- Manages icon states, dropdowns, menus, and notifications
- Supports controller, mobile, and desktop input
- Key file: `init.lua` - Main Icon module with comprehensive API

**Remote Communication (`src/ReplicatedStorage/Remotes.lua`)**
- Secure remote event/function system with encryption
- Uses SHA1 hashing with job ID for security
- Automatically creates remote events as needed

**Admin System (`src/ServerScriptService/HD Admin/`)**
- Complete admin command system with client/server separation
- Configuration in `Config/Commands/` with separate client and server command files
- Uses HD Admin framework

**Profile Service (`src/ReplicatedStorage/ProfileService.lua`)**
- DataStore profile management system
- Session-locked savable table API
- Handles player data persistence

### Player Features

**Aura System (`src/StarterPlayer/StarterPlayerScripts/AuraClient.client.lua`)**
- Visual effect system with TopbarPlus integration
- Multiple aura types with server-side management
- Mobile-friendly controls

**Music Player (`src/StarterPlayer/StarterPlayerScripts/MusicPlayerSystem.client.lua`)**
- In-game music system with GUI controls

**Settings System (`src/StarterPlayer/StarterPlayerScripts/SettingsSystem.client.lua`)**
- Player preferences and configuration management

### Starter Items

**BoomBox (`src/StarterPack/BoomBox/`)**
- Music playback functionality
- Client-side interface (`Client.client.lua`)
- Server-side script (`Server.server.lua`)

**Speed Coil (`src/StarterPack/SpeedCoil/`)**
- Movement enhancement tool
- Configurable speed boost values

### Event Systems

**Nuke Event (`src/StarterGui/EventGUI/Nuke/`)**
- Cinematic event system with camera shake effects
- Fireworks and visual effects
- Uses CameraShaker system for impact effects

**Carry System (`src/StarterGui/carrygui/`)**
- Player interaction system for carrying other players
- Request/accept/decline GUI with success notifications

## Key Patterns and Conventions

### File Extensions
- `.client.lua` - Client-side scripts
- `.server.lua` - Server-side scripts
- `.lua` - Shared modules
- `init.meta.json` - Rojo metadata files

### Remote Communication
- Use `Remotes.lua` for secure client-server communication
- Remote names are encrypted using SHA1 hashing
- Server creates remotes dynamically if they don't exist

### TopbarPlus Integration
- Many systems integrate with the TopbarPlus Icon system
- Icons support dropdowns, menus, and notifications
- Mobile-responsive design with touch support

### Security Considerations
- Remote events use encryption with job ID
- Studio vs production environment detection
- Input validation on server-side commands

## Development Notes

- The project uses `ProfileService` for data persistence
- `Icon` system provides comprehensive UI capabilities
- Admin system separates client and server command logic
- Mobile compatibility is considered throughout the codebase
- Event systems include visual effects and user feedback

## File Organization

The codebase follows Roblox's service-based structure:
- `StarterPlayer/StarterPlayerScripts/` - Client-side player scripts
- `StarterGui/` - User interface elements
- `StarterPack/` - Tools given to players on spawn
- `ServerScriptService/` - Server-side logic and systems
- `ReplicatedStorage/` - Shared modules and remote communication