# Tremble - Complete Implementation Guide

## 🎯 What We're Building

**Tremble** is a 1v1 arena shooter with Quake-like movement and a Beam Gun with vampirism. Players fight to 10 frags in best-of-3 rounds, with competitive ranking and leaderboards.

---

## 🏗️ Core Systems Structure

### 1. Game Manager (Singleton)
**File:** `game_manager.gd`
**Purpose:** Central game state control

**Core Components:**
- Manages current gamemode configuration
- Coordinates all other managers (match, player, UI, network, ranking)
- Controls game flow transitions (menu, lobby, playing, paused)

**Key Functions:**
- Start and end matches with specific gamemode configurations
- Pause and resume game state
- Handle transitions between different game states
- Return to main menu from any game state
- Coordinate communication between all subsystems

### 2. Match Manager
**File:** `match_manager.gd`
**Purpose:** Handle match flow and scoring

**Match State Management:**
- Tracks current round number and maximum rounds (best-of-3)
- Manages round time limits (10 minutes per round)
- Handles frag limits (10 kills to win a round)
- Maintains player score tracking

**Match Flow Control:**
- Starts and ends individual rounds
- Checks win conditions for rounds and matches
- Handles player death events and score updates
- Manages round transitions and match completion

### 3. Player Manager
**File:** `player_manager.gd`
**Purpose:** Handle player spawning and state

**Player Tracking:**
- Maintains dictionary of all connected players
- Manages spawn point locations across maps
- Tracks player states and statistics

**Spawn Management:**
- Handles initial player spawning when joining
- Manages player respawning after death with configurable delays
- Provides spawn protection status for new players
- Ensures fair spawn distribution across available spawn points

### 4. UI Manager
**File:** `ui_manager.gd`
**Purpose:** Control all UI elements

**UI Component Management:**
- Manages references to all UI screens (HUD, menus, lobby, leaderboard)
- Controls visibility and state of different UI elements
- Handles transitions between UI states

**UI Update Functions:**
- Updates HUD elements for specific players (health, ammo, score)
- Shows match end screens with results
- Updates score displays and timers in real-time
- Manages lobby and leaderboard screen visibility
- Handles UI responsiveness and user interactions

### 5. Network Manager
**File:** `network_manager.gd`
**Purpose:** Handle multiplayer connectivity and lobby system

**Network State Management:**
- Tracks whether the player is hosting or joining as a client
- Manages server address and connection information
- Maintains list of players in current lobby

**Network Functions:**
- Hosts games on specified ports with lobby creation
- Joins games by connecting to specific server addresses
- Creates and manages lobby systems for match preparation
- Joins existing lobbies using lobby IDs
- Initiates match starts from lobby state

### 6. Ranking Manager
**File:** `ranking_manager.gd`
**Purpose:** Handle Glicko-2 rating system and leaderboards

**Rating System Management:**
- Maintains player ratings using Glicko-2 algorithm
- Stores leaderboard data with rank-based display
- Tracks player statistics and match history

**Rating Functions:**
- Calculates new ratings after match results
- Updates leaderboard rankings and statistics
- Retrieves player rank information
- Provides paginated leaderboard access

---

## 🎮 Game Modes

### Duel Mode (Primary)
**Config File:** `resources/duel_gamemode.tres`

**Configuration Parameters:**
- Frag limit: 10 kills to win a round
- Round time: 10 minutes maximum per round
- Maximum rounds: Best-of-3 format
- Respawn time: 3 seconds after death
- Spawn protection: 2 seconds of invulnerability
- Available weapons: Beam Gun only
- Available maps: Arena 01 and Arena 02

---

## 🎨 User Interface Systems

### HUD System (Need to Create)
**File:** `scenes/ui/hud.tscn`

#### Health Bar
**File:** `scenes/ui/components/health_bar.tscn`

**Health Display Components:**
- Shows current and maximum health values
- Displays health as both progress bar and numerical text
- Provides visual feedback for damage taken

**Health Bar Functions:**
- Updates health display in real-time
- Animates damage taken with visual effects
- Shows low health warnings when health is critical

#### Crosshair System
**File:** `scenes/ui/components/crosshair.tscn`

**Crosshair Customization:**
- Supports multiple crosshair styles and appearances
- Allows color customization for visibility
- Provides size adjustment options

**Crosshair Functions:**
- Changes crosshair style dynamically
- Updates crosshair color based on preferences
- Animates hit feedback when landing shots
- Shows accuracy indicators for weapon spread

#### HUD Layout
- Health bar (top-left)
- Ammo counter (top-right)
- Score display (center-top)
- Timer (center-top)
- Crosshair (center)
- Round indicator (top-center)
- Kill feed (top-right)
- Spawn protection indicator

### Menu System (Need to Create)

#### Main Menu
**File:** `scenes/ui/main_menu.tscn`

**Main Menu Structure:**
- Play Button with options for Quick Match, Custom Game, and Tournament modes
- Leaderboards Button to view rankings
- Options Button for game settings
- Profile Button for player statistics
- Exit Button to close the game
- News/Updates Panel for announcements
- Server Status Indicator showing connection status

#### Lobby System
**File:** `scenes/ui/lobby_screen.tscn`

**Lobby Screen Structure:**
- Player List showing all players with their ready status
- Chat System for player communication
- Map Selection interface for choosing arena
- Gamemode Selection for different game types
- Start Match Button to begin the game
- Leave Lobby Button to exit lobby
- Player Statistics Preview showing player info

#### Options Menu
**File:** `scenes/ui/options_menu.tscn`

**Options Categories:**
- Graphics Settings including resolution, quality, and field of view
- Audio Settings for master volume, music, sound effects, and voice
- Controls Settings for sensitivity, keybinds, and crosshair customization
- Network Settings for region selection and ping display
- Gameplay Settings for HUD elements and notifications

#### Leaderboard Screen
**File:** `scenes/ui/leaderboard_screen.tscn`

**Leaderboard Features:**
- Global Rankings showing top 100 players worldwide
- Regional Rankings filtered by geographic location
- Seasonal Rankings for competitive seasons
- Personal Statistics for individual player performance
- Match History showing recent games and results
- Achievement Display for unlocked accomplishments

---

## 🌐 Networking & Lobby System

### Connection System
**File:** `scripts/network_manager.gd`

#### Server Discovery

**Server Discovery Functions:**
- Discovers available servers and returns server information
- Measures ping to specific server addresses
- Retrieves detailed server information including player count and gamemode

#### Lobby Management

**Lobby System Functions:**
- Creates lobbies with specific gamemodes and player limits
- Joins existing lobbies using lobby IDs
- Allows players to leave lobbies
- Manages player ready states for match preparation
- Initiates match starts when all players are ready

### Server Architecture Options

#### Option 1: Peer-to-Peer (Current)
- **Pros:** Simple, no server costs
- **Cons:** Host advantage, connection issues
- **Best for:** Small-scale testing

#### Option 2: Dedicated Servers
- **Pros:** Fair play, stable connections
- **Cons:** Server costs, complexity
- **Best for:** Competitive play

#### Option 3: Hybrid System
- **Pros:** Flexible, cost-effective
- **Cons:** Complex implementation
- **Best for:** Mixed casual/competitive

#### Option 4: Steam Integration (Recommended)
- **Pros:** Built-in matchmaking, lobby system, NAT traversal, anti-cheat
- **Cons:** Requires Steam SDK, Steam dependency
- **Best for:** Professional multiplayer games

---

## 🎯 Complete Menu Navigation System

### Main Menu Navigation Flow
**Entry Point:** Game starts at main menu

**Main Menu Options:**
- **Play** → Opens lobby/connect system
- **Leaderboard** → Shows global rankings with rank tiers
- **Options** → Opens settings menu
- **Quit** → Exits game

### Lobby/Connect System Navigation
**From Main Menu → Play:**

**Host Game:**
- **Create Lobby** → Opens lobby creation with map/gamemode selection
- **Steam Matchmaking** → Opens Steam matchmaking interface
- **Direct IP** → Shows IP input field for direct connection

**Join Game:**
- **Browse Servers** → Shows server list with ping and player count
- **Steam Lobby** → Shows Steam lobby browser
- **Enter Lobby ID** → Direct lobby joining with ID input
- **Recent Games** → Shows recently played servers/lobbies

### Lobby Screen Navigation
**Once in Lobby:**

**Lobby Management:**
- **Ready/Unready** → Toggle player ready status
- **Change Map** → Opens map selection (if host)
- **Change Gamemode** → Opens gamemode selection (if host)
- **Kick Player** → Remove player from lobby (if host)
- **Chat** → Opens lobby chat system
- **Start Match** → Begin game (if host and all players ready)
- **Leave Lobby** → Return to main menu

**Player List:**
- Shows all players with ready status
- Displays player ranks and statistics
- Shows connection quality indicators

### In-Game Navigation
**During Match:**

**HUD Elements:**
- **Health Bar** → Shows current health (0-100)
- **Ammo Counter** → Shows current weapon ammo
- **Score Display** → Shows current frags and round info
- **Timer** → Shows round time remaining
- **Crosshair** → Customizable aiming reticle
- **Kill Feed** → Recent kill notifications
- **Spawn Protection** → Visual indicator when spawning

**Pause Menu (ESC):**
- **Resume** → Continue current match
- **Options** → Opens in-game settings
- **Spectate** → Switch to spectator mode (if available)
- **Disconnect** → Leave match and return to main menu

### Match End Navigation
**After Match Completion:**

**Match Results Screen:**
- **Final Score** → Shows match results and statistics
- **Ranking Changes** → Displays rating adjustments
- **Replay** → Watch match replay (if implemented)
- **Rematch** → Challenge same opponent again
- **New Match** → Return to lobby/connect system
- **Main Menu** → Return to main menu

### Options Menu Navigation
**From Main Menu or Pause Menu:**

**Settings Categories:**
- **Graphics** → Resolution, quality, fullscreen, vsync
- **Audio** → Master volume, music, SFX, voice chat
- **Controls** → Key bindings, mouse sensitivity, input device
- **Gameplay** → Crosshair style, HUD elements, auto-sprint
- **Network** → Connection quality, region preferences
- **Steam** → Steam integration settings, privacy options

**Navigation Controls:**
- **Back** → Return to previous menu
- **Apply** → Save current settings
- **Reset to Default** → Restore default settings
- **Cancel** → Discard changes and return

### Leaderboard Navigation
**From Main Menu → Leaderboard:**

**Leaderboard Views:**
- **Global Rankings** → All players sorted by rank tier
- **Friends** → Steam friends only (if Steam integration)
- **Seasonal** → Current season rankings
- **Regional** → Players in same region

**Leaderboard Features:**
- **Player Profiles** → Click player to view detailed stats
- **Search** → Find specific players by username
- **Filter** → Filter by rank tier, region, or activity
- **Refresh** → Update leaderboard data
- **Back** → Return to main menu

### Steam Matchmaking Navigation
**From Lobby/Connect → Steam Matchmaking:**

**Matchmaking Options:**
- **Quick Match** → Find any available opponent
- **Ranked Match** → Find opponent within skill range
- **Custom Match** → Set specific criteria (region, ping, rank)
- **Cancel Search** → Stop matchmaking and return to lobby

**Matchmaking Status:**
- **Searching** → Shows estimated wait time and criteria
- **Match Found** → Shows opponent info and accept/decline
- **Connecting** → Shows connection progress
- **Error** → Shows error message and retry options

### Navigation State Management
**UI Manager Responsibilities:**
- Tracks current menu state and navigation history
- Manages transitions between different screens
- Handles back button functionality throughout the game
- Ensures proper cleanup when switching between states
- Maintains context when returning from sub-menus

**Escape Key Navigation:**
- **Main Menu**: Escape key has no action (already at root level)
- **Sub-menus**: Escape key returns to previous menu or main menu
- **Options Menu**: Escape key returns to previous menu (main menu or pause menu)
- **Lobby Screen**: Escape key shows "Leave Lobby?" confirmation dialog
- **Leaderboard**: Escape key returns to main menu
- **Steam Matchmaking**: Escape key cancels search and returns to lobby/connect
- **In-Game**: Escape key opens pause menu
- **Pause Menu**: Escape key resumes game or returns to previous menu
- **Match End Screen**: Escape key returns to main menu
- **Confirmation Dialogs**: Escape key cancels the dialog and returns to previous state

**Transition Animations:**
- Smooth fade transitions between major screens
- Slide animations for sub-menu navigation
- Loading screens for network operations
- Error state handling with retry options

---

## 🎮 Steam Integration & Matchmaking

### Steam SDK Setup
**File:** `scripts/steam/steam_manager.gd`

**Steam Integration Components:**
- Manages Steam API initialization and connection
- Tracks Steam user ID and username
- Handles lobby management with member tracking
- Controls matchmaking state and search criteria

**Steam Manager Functions:**
- Initializes Steam API on game startup
- Retrieves Steam user information
- Manages lobby creation and member tracking
- Handles matchmaking state transitions

### Steam Lobby System
**File:** `scripts/steam/steam_lobby.gd`

**Steam Lobby Management:**
- Handles lobby creation with different privacy types (private, friends-only, public)
- Manages lobby member tracking and data storage
- Supports friend invitations to lobbies

**Lobby Functions:**
- Creates lobbies with specified player limits and privacy settings
- Joins existing Steam lobbies using lobby IDs
- Sets and retrieves lobby data for game configuration
- Invites Steam friends to current lobby
- Handles lobby departure and cleanup

### Steam Matchmaking System
**File:** `scripts/steam/steam_matchmaking.gd`

**Steam Matchmaking Components:**
- Manages search filters for finding suitable opponents
- Tracks current matchmaking search status
- Implements skill-based matching using Glicko-2 ratings
- Supports region-based filtering for optimal connections

**Matchmaking Functions:**
- Starts matchmaking searches with skill and region filters
- Cancels ongoing matchmaking searches
- Handles match acceptance and decline responses
- Integrates with ranking system for balanced matches

### Steam Networking Integration
**File:** `scripts/steam/steam_networking.gd`

**Steam P2P Networking:**
- Manages peer-to-peer connections between Steam users
- Tracks connection states for all connected peers
- Handles P2P message transmission and reception

**Networking Functions:**
- Establishes P2P connections to other Steam users
- Disconnects from peers and cleans up connections
- Sends and receives P2P messages for game data
- Processes incoming P2P messages for game synchronization

### Steam Integration with Godot Networking
**File:** `scripts/steam/steam_network_bridge.gd`

**Steam-Godot Bridge Components:**
- Bridges Steam networking systems with Godot's multiplayer
- Manages Steam lobby integration with Godot servers
- Handles P2P connections for client-to-host communication

**Bridge Functions:**
- Sets up Steam hosting with lobby creation and Godot server initialization
- Configures Steam client connections through lobby joining and P2P setup
- Bridges Steam lobby events to Godot multiplayer system
- Manages P2P session requests and connections for seamless integration

### Steam Matchmaking UI Integration
**File:** `scripts/ui/steam_matchmaking_ui.gd`

**Steam Matchmaking UI Components:**
- Provides user interface for Steam matchmaking functionality
- Manages matchmaking buttons and status displays
- Shows player count and estimated wait times

**UI Functions:**
- Handles matchmaking button interactions to start searches
- Manages cancel button functionality to stop searches
- Updates UI state based on matchmaking status (idle, searching, found)
- Displays appropriate status messages and button visibility

### Steam Integration Implementation Steps

#### Phase 1: Steam SDK Setup
1. **Download Steam SDK**
   - Get Steamworks SDK from Valve
   - Extract to `addons/steam/` directory
   - Add Steam API bindings for Godot

2. **Configure Project Settings**
   - Add Steam app ID to project configuration
   - Set up Steam manager as autoload singleton

3. **Initialize Steam API**
   - Create `steam_manager.gd` singleton
   - Handle Steam initialization in `_ready()`
   - Add Steam API error handling

#### Phase 2: Lobby System Implementation
1. **Create Steam Lobby Manager**
   - Implement lobby creation/joining
   - Handle lobby data synchronization
   - Add friend invitation system

2. **Lobby UI Integration**
   - Create lobby browser
   - Add lobby settings (public/private)
   - Implement player ready states

#### Phase 3: Matchmaking Implementation
1. **Skill-Based Matchmaking**
   - Integrate with Glicko-2 system
   - Add region-based filtering
   - Implement match acceptance/decline

2. **Matchmaking UI**
   - Create matchmaking screen
   - Add estimated wait time
   - Show match found dialog

#### Phase 4: Networking Bridge
1. **Steam P2P Integration**
   - Bridge Steam P2P to Godot networking
   - Handle connection state management
   - Implement NAT traversal

2. **Fallback Systems**
   - Add direct IP connection fallback
   - Implement connection quality monitoring
   - Add reconnection logic

#### Phase 5: Testing & Polish
1. **Steam Integration Testing**
   - Test lobby creation/joining
   - Verify matchmaking functionality
   - Test P2P connection stability

2. **Performance Optimization**
   - Optimize Steam API calls
   - Implement connection pooling
   - Add error recovery mechanisms

---

## 🏆 Ranking System

### Glicko-2 with Rank Tiers
**File:** `scripts/ranking/glicko2_system.gd`

**Glicko-2 Rating System:**
- Implements Glicko-2 algorithm with rating, deviation, and volatility tracking
- Uses rank tier system similar to competitive games (Unranked to Grandmaster)
- Defines rating thresholds for each rank tier with divisions

**Rank System Functions:**
- Calculates new ratings after match results using Glicko-2 algorithm
- Updates rating deviation based on time since last game
- Determines rank tier from numerical rating
- Provides rank display names and progress within tiers

### Rank Display System
**File:** `scripts/ranking/rank_display.gd`

**Rank Display Components:**
- Manages rank information including tier, division, and progress
- Provides display names, icon paths, and colors for each rank
- Tracks progress within divisions (1-4 within each tier)

**Display Functions:**
- Retrieves complete rank information from numerical rating
- Calculates division within each rank tier
- Provides rank icons and colors for UI display
- Manages rank progression visualization

### Leaderboard System
**File:** `scripts/ranking/leaderboard_manager.gd`

**Leaderboard Components:**
- Manages leaderboard entries with rank-based display (actual ratings hidden)
- Tracks player statistics including matches, wins, losses, and win rates
- Provides rank tier, division, and progress information

**Leaderboard Functions:**
- Retrieves paginated leaderboard data
- Gets individual player rank information
- Updates player statistics after match results
- Maintains hidden rating system while showing rank tiers

### Rank Progression
- **Unranked**: 0-999 rating (placement matches)
- **Bronze**: 1000-1499 rating (Divisions 1-4)
- **Silver**: 1500-1999 rating (Divisions 1-4)
- **Gold**: 2000-2499 rating (Divisions 1-4)
- **Platinum**: 2500-2999 rating (Divisions 1-4)
- **Diamond**: 3000-3499 rating (Divisions 1-4)
- **Master**: 3500-3999 rating (Top tier)
- **Grandmaster**: 4000+ rating (Elite tier)

### Placement System
- New players start with 1500 rating and high deviation
- First 10 matches are placement matches
- Rating changes are larger during placement
- After 10 matches, player gets their initial rank
- Seasonal resets put players back to placement matches

---

## 📋 Implementation Checklist

### Phase 1: Core Game Loop (Priority: Critical)
- [ ] Create `game_manager.gd` (singleton)
- [ ] Create `match_manager.gd`
- [ ] Create `player_manager.gd`
- [ ] Create `ui_manager.gd`
- [ ] Create `network_manager.gd`
- [ ] Create `ranking_manager.gd`
- [ ] Add all managers to project autoload

### Phase 2: UI System (Priority: Critical)
- [ ] Create HUD scene with health bar and crosshair
- [ ] Create main menu system
- [ ] Create lobby/connect system
- [ ] Create options menu
- [ ] Create leaderboard screen
- [ ] Create pause and match end screens
- [ ] Implement UI state management

### Phase 3: Steam Integration (Priority: High)
- [ ] Download and setup Steam SDK
- [ ] Create `steam_manager.gd` singleton
- [ ] Implement Steam API initialization
- [ ] Create `steam_lobby.gd` for lobby management
- [ ] Create `steam_matchmaking.gd` for matchmaking
- [ ] Create `steam_networking.gd` for P2P connections
- [ ] Create `steam_network_bridge.gd` to bridge Steam and Godot networking
- [ ] Add Steam matchmaking UI components
- [ ] Test Steam lobby creation and joining
- [ ] Test Steam matchmaking functionality

### Phase 4: Networking & Lobby (Priority: High)
- [ ] Implement server discovery
- [ ] Create lobby system (Steam-integrated)
- [ ] Add player ready states
- [ ] Implement match start from lobby
- [ ] Add chat system
- [ ] Add server ping display
- [ ] Implement Steam P2P fallback to direct IP

### Phase 5: Ranking System (Priority: High)
- [ ] Implement Glicko-2 system with rank tiers
- [ ] Create rank display system (tiers, divisions, progress)
- [ ] Create leaderboard database (hidden ratings)
- [ ] Add placement match system (10 matches)
- [ ] Implement seasonal resets
- [ ] Create ranking display UI with icons
- [ ] Test ranking accuracy and progression
- [ ] Integrate ranking with Steam matchmaking filters

### Phase 6: Map Blockout (Priority: High)
- [ ] Create `arena_01.tscn` (basic symmetrical)
- [ ] Create `arena_02.tscn` (multi-level)
- [ ] Create `arena_03.tscn` (close-quarters)
- [ ] Create `arena_04.tscn` (open space)
- [ ] Add spawn points and protection zones
- [ ] Add pickup spawn locations
- [ ] Test map flow and balance

### Phase 7: Audio System (Priority: Medium)
- [ ] Create `audio_manager.gd`
- [ ] Design audio pipeline
- [ ] Create weapon sound effects
- [ ] Create UI sound effects
- [ ] Create ambient music system
- [ ] Implement dynamic music
- [ ] Add audio settings and mixing

### Phase 8: Modeling Phase (Priority: Medium)
- [ ] Create player character models
- [ ] Create weapon models
- [ ] Create environmental props
- [ ] Create pickup models
- [ ] Create UI elements (3D)
- [ ] Optimize models for performance
- [ ] Create LOD systems

### Phase 9: Texturing Phase (Priority: Medium)
- [ ] Create material system
- [ ] Design texture pipeline
- [ ] Create player character textures
- [ ] Create weapon textures
- [ ] Create environmental textures
- [ ] Create UI textures
- [ ] Implement texture streaming

### Phase 10: Shader Phase (Priority: Medium)
- [ ] Create weapon effect shaders
- [ ] Create environmental shaders
- [ ] Create UI shaders
- [ ] Create post-processing effects
- [ ] Create damage indicator shaders
- [ ] Optimize shader performance
- [ ] Create shader variants

### Phase 11: Animation Phase (Priority: Medium)
- [ ] Create player character animations (idle, walk, run, jump, shoot, death)
- [ ] Create weapon animations (reload, fire, equip, unequip)
- [ ] Create environmental animations (pickups, doors, moving platforms)
- [ ] Create UI animations (menu transitions, button effects, loading screens)
- [ ] Create particle effect animations (explosions, weapon effects, environmental effects)
- [ ] Implement animation state machines for complex behaviors
- [ ] Create animation blending and transitions
- [ ] Optimize animation performance and memory usage
- [ ] Add animation events for sound effects and gameplay triggers
- [ ] Create animation preview system for development

### Phase 12: Steam Polish & Testing (Priority: Medium)
- [ ] Steam integration stress testing
- [ ] Optimize Steam API calls
- [ ] Implement connection pooling
- [ ] Add error recovery mechanisms
- [ ] Test Steam matchmaking with ranking integration
- [ ] Verify Steam P2P connection stability
- [ ] Add Steam friend invitation system

### Phase 13: Polish & Integration (Priority: Low)
- [ ] Performance optimization
- [ ] Bug fixing and testing
- [ ] UI/UX refinement
- [ ] Audio mixing and balance
- [ ] Visual effects polish
- [ ] Multiplayer stress testing
- [ ] Final integration testing
- [ ] Steam release preparation

---

## 🔧 Technical Implementation

### File Structure
```
tremble/
├── game_manager.gd (new)
├── match_manager.gd (new)
├── player_manager.gd (new)
├── ui_manager.gd (new)
├── network_manager.gd (new)
├── ranking_manager.gd (new)
├── scenes/
│   ├── ui/
│   │   ├── hud.tscn (new)
│   │   ├── main_menu.tscn (new)
│   │   ├── lobby_screen.tscn (new)
│   │   ├── options_menu.tscn (new)
│   │   ├── leaderboard_screen.tscn (new)
│   │   ├── pause_menu.tscn (new)
│   │   ├── match_end_screen.tscn (new)
│   │   ├── steam_matchmaking_screen.tscn (new)
│   │   └── components/
│   │       ├── health_bar.tscn (new)
│   │       ├── crosshair.tscn (new)
│   │       └── kill_feed.tscn (new)
│   └── levels/
│       ├── arena_01.tscn (new)
│       ├── arena_02.tscn (new)
│       ├── arena_03.tscn (new)
│       └── arena_04.tscn (new)
├── addons/
│   └── steam/
│       ├── steam_api.gdextension (new)
│       ├── steam_api.gd (new)
│       └── libsteam_api.so (new)
├── resources/
│   ├── gamemode_config.gd (new)
│   ├── duel_gamemode.tres (new)
│   └── audio/
│       ├── music/
│       ├── sfx/
│       └── ui/
├── scripts/
│   ├── steam/
│   │   ├── steam_manager.gd (new)
│   │   ├── steam_lobby.gd (new)
│   │   ├── steam_matchmaking.gd (new)
│   │   ├── steam_networking.gd (new)
│   │   └── steam_network_bridge.gd (new)
│   ├── ranking/
│   │   ├── glicko2_system.gd (new)
│   │   ├── rank_display.gd (new)
│   │   └── leaderboard_manager.gd (new)
│   ├── ui/
│   │   └── steam_matchmaking_ui.gd (new)
│   ├── audio_manager.gd (new)
│   ├── settings_manager.gd (new)
│   └── pickup_manager.gd (new)
├── assets/
│   ├── models/
│   ├── textures/
│   ├── shaders/
│   ├── audio/
│   ├── animations/
│   │   ├── player/
│   │   │   ├── idle.anim (new)
│   │   │   ├── walk.anim (new)
│   │   │   ├── run.anim (new)
│   │   │   ├── jump.anim (new)
│   │   │   ├── shoot.anim (new)
│   │   │   └── death.anim (new)
│   │   ├── weapons/
│   │   │   ├── beam_gun_fire.anim (new)
│   │   │   ├── beam_gun_reload.anim (new)
│   │   │   ├── equip.anim (new)
│   │   │   └── unequip.anim (new)
│   │   ├── environment/
│   │   │   ├── pickup_spawn.anim (new)
│   │   │   ├── door_open.anim (new)
│   │   │   └── platform_move.anim (new)
│   │   └── ui/
│   │       ├── menu_transition.anim (new)
│   │       ├── button_click.anim (new)
│   │       └── loading_screen.anim (new)
│   └── ui/
│       └── ranks/
│           ├── bronze.png (new)
│           ├── silver.png (new)
│           ├── gold.png (new)
│           ├── platinum.png (new)
│           ├── diamond.png (new)
│           ├── master.png (new)
│           └── grandmaster.png (new)
└── data/
    ├── leaderboard.json (new)
    ├── player_stats.json (new)
    └── match_history.json (new)
```

### Database Structure (for Leaderboards)
```json
{
  "players": {
    "player_id": {
      "username": "string",
      "rating": 1500.0,
      "deviation": 350.0,
      "volatility": 0.06,
      "matches_played": 0,
      "wins": 0,
      "losses": 0,
      "placement_matches_remaining": 10,
      "last_match": "timestamp",
      "season": 1
    }
  },
  "leaderboard": {
    "global": [
      {
        "player_id": "string",
        "username": "string",
        "rank_tier": "GOLD",
        "division": 2,
        "progress": 0.75,
        "matches_played": 25,
        "wins": 15,
        "losses": 10,
        "win_rate": 0.6
      }
    ]
  },
  "rank_icons": {
    "bronze": "res://assets/ui/ranks/bronze.png",
    "silver": "res://assets/ui/ranks/silver.png",
    "gold": "res://assets/ui/ranks/gold.png",
    "platinum": "res://assets/ui/ranks/platinum.png",
    "diamond": "res://assets/ui/ranks/diamond.png",
    "master": "res://assets/ui/ranks/master.png",
    "grandmaster": "res://assets/ui/ranks/grandmaster.png"
  }
}
```

---

## 🚀 Development Workflow

### 1. Core Systems (Weeks 1-2)
1. Create all manager classes
2. Set up autoload system
3. Implement basic game flow
4. Test core functionality

### 2. UI Foundation (Weeks 3-4)
1. Create HUD with health bar and crosshair
2. Build main menu system
3. Implement basic navigation
4. Test UI responsiveness

### 3. Networking & Lobby (Weeks 5-6)
1. Implement server discovery
2. Create lobby system
3. Add player management
4. Test multiplayer connectivity

### 4. Ranking System (Weeks 7-8)
1. Implement Glicko-2 system
2. Create leaderboard database
3. Add rating calculations
4. Test ranking accuracy

### 5. Content Creation (Weeks 9-20)
1. Map blockout and testing
2. Audio design and implementation
3. 3D modeling and texturing
4. Shader development
5. Animation creation and implementation
6. Integration and polish

---

## ✅ Success Criteria

### Minimum Viable Product
- [ ] 1v1 duels work end-to-end
- [ ] Players can join, play, and see results
- [ ] Basic HUD shows health, ammo, score, timer
- [ ] Main menu and lobby system functional
- [ ] Basic ranking system working
- [ ] 2-3 maps available
- [ ] Stable multiplayer performance

### Quality Standards
- [ ] 60 FPS performance
- [ ] <100ms network latency
- [ ] No game-breaking bugs
- [ ] Intuitive controls and UI
- [ ] Balanced gameplay
- [ ] Fair ranking system
- [ ] Responsive UI design

---

This comprehensive guide covers all the systems needed for a complete competitive arena shooter with ranking, networking, and content creation phases. 