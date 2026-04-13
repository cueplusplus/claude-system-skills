---
name: ma3-lua-plugin
version: 1.0.0
description: |
  Write Lua plugins for grandMA3 lighting consoles. Covers the complete Lua API (Object-Free
  and Object API), plugin structure (XML + Lua), MessageBox dialogs, layout programming,
  object tree navigation, sequence/preset/group manipulation, debugging with Printf/terminal,
  and MA3-specific patterns. Trigger when user asks to create, write, debug, or modify grandMA3
  Lua plugins, or asks about the MA3 Lua API, handles, MessageBox, or console scripting.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

# grandMA3 Lua Plugin Development

You are an expert grandMA3 Lua plugin developer. You write production-quality plugins for the grandMA3 lighting console platform by MA Lighting. You have deep knowledge of the MA3 Lua API, the object model, UI dialogs, and console-specific patterns.

---

## 1. Plugin Architecture

### File Structure

Every MA3 plugin consists of an **XML manifest** and one or more **Lua components**:

```
gma3_library/datapools/plugins/
└── MyPlugin/
    ├── MyPlugin.xml        # Plugin manifest
    └── MyPlugin.lua        # Main Lua component
```

### XML Manifest

```xml
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="2.0.2.0">
  <UserPlugin Name="MyPlugin" Author="Author Name" Version="1.0.0.0" Path="MyPlugin">
    <ComponentLua Name="MyPlugin" FileName="MyPlugin.lua"/>
    <!-- Additional components -->
    <ComponentLua Name="Utils" FileName="Utils.lua"/>
  </UserPlugin>
</GMA3>
```

### Lua Component Structure

```lua
-- Plugin parameters (available at module level, runs on component load)
local pluginName    = select(1, ...)  -- Plugin name string
local componentName = select(2, ...)  -- Component name string
local signalTable   = select(3, ...)  -- Signal table
local my_handle     = select(4, ...)  -- Handle to this Lua component

-- REQUIRED: Main function - called on Plugin X or pool click
-- display_handle: handle to the display/element that invoked the plugin
-- argument: string passed via Plugin "Name" "argument"
local function Main(display_handle, argument)
    Printf("Plugin started")
    -- Plugin logic here
end

-- OPTIONAL: Cleanup - called after Main completes
local function Cleanup()
    Printf("Cleanup")
end

-- OPTIONAL: Execute - called with action keywords (Go+ Plugin X, On Plugin X)
local function Execute(Type, ...)
    Printf("Execute called with type: %s", Type)
end

return Main, Cleanup, Execute
```

**Alternative simple pattern:**
```lua
return function(display_handle, argument)
    Printf("Hello from plugin")
end
```

### Running Plugins

- **Pool click**: Click the plugin in the Plugin pool
- **Command line**: `Plugin X` or `Plugin "MyPlugin"`
- **With arguments**: `Plugin "MyPlugin" "my_argument"`
- **Specific component**: `Plugin 1.2` (component 2 of plugin 1)
- **Reload after edits**: `ReloadAllPlugins`

---

## 2. Lua Environment

- **Lua version**: 5.4.6 (grandMA3 v2.1+), 5.4.4 (v2.0 and earlier)
- **All standard Lua libraries** are available
- Use `HelpLua` in the command line to export all available functions to `grandMA3_lua_functions.txt`

---

## 3. Object-Free API (Global Functions)

These are standalone functions, not methods on objects.

### Command Execution

| Function | Description |
|----------|-------------|
| `Cmd(string[, handle])` | Execute MA3 command synchronously |
| `CmdIndirect(string[, handle[, handle]])` | Execute command asynchronously in main task |
| `CmdIndirectWait(string[, handle[, handle]])` | Execute command synchronously in main task |
| `CmdObj()` | Returns command line object info |

**Example:**
```lua
Cmd("Go+ Sequence 1")
Cmd('Set Sequence 10 Property "OffWhenOverridden" "No"')
Cmd("Copy DataPool 3 Sequence 1 At DataPool 3 Sequence 100")
```

### Output & Debugging

| Function | Description |
|----------|-------------|
| `Printf(string, ...)` | Print formatted string to Command Line History |
| `Echo(string, ...)` | Print string in System Monitor |
| `ErrPrintf(string, ...)` | Print red error in Command Line History |
| `ErrEcho(string, ...)` | Print red error in System Monitor |

**Example:**
```lua
Printf("Processing %d items", count)
ErrPrintf("Error: sequence %d not found", seqNum)
```

### Object Access & Navigation

| Function | Description |
|----------|-------------|
| `Root()` | Returns handle to the root object |
| `ShowData()` | Returns handle to show data |
| `DataPool()` | Returns handle to current DataPool |
| `Pult()` | Returns handle to console |
| `Patch()` | Returns handle to patch |
| `Programmer()` | Returns handle to programmer |
| `ProgrammerPart()` | Returns handle to programmer part |
| `CurrentUser()` | Returns handle to current user |
| `CurrentProfile()` | Returns handle to current user profile |
| `CurrentExecPage()` | Returns handle to current executor page |
| `CurrentEnvironment()` | Returns handle to current environment |
| `CurrentScreenConfig()` | Returns handle to current screen config |
| `MasterPool()` | Returns handle to master pool |
| `SelectedSequence()` | Returns handle to selected sequence |
| `SelectedLayout()` | Returns handle to selected layout |
| `SelectedTimecode()` | Returns handle to selected timecode |
| `SelectedTimer()` | Returns handle to selected timer |
| `SelectedFeature()` | Returns handle to selected feature |

### Handle Conversion

| Function | Description |
|----------|-------------|
| `FromAddr(string[, handle])` | Convert address string to handle |
| `ToAddr(handle[, boolean])` | Convert handle to address string |
| `HandleToStr(handle)` | Convert handle to hex string |
| `HandleToInt(handle)` | Convert handle to integer |
| `StrToHandle(string)` | Convert hex string to handle |
| `IntToHandle(integer)` | Convert integer to handle |
| `IsObjectValid(handle)` | Check if handle is still valid |

**Example:**
```lua
local seqHandle = FromAddr("Sequences.Default", DataPool())
Printf("Address: %s", seqHandle:Addr())
Printf("Named: %s", seqHandle:AddrNative())
```

### Selection Functions

| Function | Description |
|----------|-------------|
| `Selection()` | Returns handle to selection |
| `SelectionCount()` | Number of selected fixtures |
| `SelectionFirst()` | Index of first selected fixture |
| `SelectionNext(integer)` | Index of next selected fixture |
| `SelectionTable()` | Returns selection as table |

### Fixture & DMX Functions

| Function | Description |
|----------|-------------|
| `AddFixtures(table)` | Add fixtures to the patch |
| `GetSubfixture(integer)` | Get subfixture by index |
| `GetSubfixtureCount()` | Total subfixture count |
| `GetDMXUniverse(integer[, boolean])` | Get DMX universe data |
| `GetDMXValue(integer[, integer, boolean])` | Get current DMX value |
| `CheckDMXCollision(handle, string[, integer[, integer]])` | Check DMX address availability |
| `CheckFIDCollision(integer[, integer[, integer]])` | Check fixture ID availability |
| `FirstDmxModeFixture(handle)` | First fixture matching DMX mode |
| `FixtureType()` | Handle to fixture type at current destination |
| `GetPresetData(handle[, boolean[, boolean]])` | Get preset data |

### Attribute Functions

| Function | Description |
|----------|-------------|
| `GetAttributeCount()` | Total attribute definitions in show |
| `GetAttributeIndex(string)` | Get attribute index by system name |
| `GetAttributeByUIChannel(integer)` | Get attribute by UI channel index |
| `GetSelectedAttribute()` | Currently selected attribute |
| `GetUIChannelCount()` | Total UI channel count |
| `GetUIChannelIndex(integer, integer)` | Get UI channel index |
| `GetUIChannels(integer[, boolean])` | Get UI channels collection |
| `GetRTChannel(integer)` | Get realtime channel |
| `GetRTChannelCount()` | Realtime channel count |
| `GetRTChannels(integer[, boolean])` | Get realtime channels collection |
| `GetChannelFunction(integer, integer)` | Get channel function |

### UI & Dialog Functions

| Function | Description |
|----------|-------------|
| `MessageBox(table)` | Create complex dialog with inputs, selectors, checkboxes |
| `Confirm(string[, string[, integer[, boolean]]])` | Simple yes/no confirmation popup |
| `TextInput([string[, string[, integer[, integer]]]])` | Simple text input popup |
| `PopupInput(table)` | Create popup input dialog |
| `CloseAllOverlays()` | Close all pop-ups/overlays on all screens |
| `GetFocus()` | Handle to currently focused object |
| `GetFocusDisplay()` | Display with current focus |
| `GetTopModal()` | Topmost modal dialog |
| `GetTopOverlay()` | Topmost overlay |
| `DrawPointer(integer, table[, integer])` | Draw red pointer on display |
| `SetBlockInput(boolean)` | Block/unblock user input |

### Variable Functions

| Function | Description |
|----------|-------------|
| `UserVars()` | Handle to user variables set |
| `GlobalVars()` | Handle to global variables set |
| `GetVar(handle, string)` | Get variable value |
| `SetVar(handle, string, value)` | Set variable value (creates if not exists) |
| `DelVar(handle, string)` | Delete variable |
| `PluginVars(string)` | Handle to plugin-specific variables |
| `AddonVars(string)` | Handle to addon variables |

**Example:**
```lua
SetVar(UserVars(), "myVar", 42)
local val = GetVar(UserVars(), "myVar")
Printf("Value: %s", tostring(val))
DelVar(UserVars(), "myVar")
```

### Progress Bar Functions

| Function | Description |
|----------|-------------|
| `StartProgress(string)` | Create progress bar, returns handle |
| `SetProgressRange(handle, integer, integer)` | Set range (start, end) |
| `SetProgressText(handle, string)` | Set progress bar text |
| `SetProgress(handle, integer)` | Set current progress value |
| `IncProgress(handle, integer)` | Increment progress |
| `StopProgress(handle)` | Remove progress bar |

**Example:**
```lua
local pb = StartProgress("Processing")
SetProgressRange(pb, 1, 100)
for i = 1, 100 do
    SetProgress(pb, i)
    SetProgressText(pb, string.format("Item %d/100", i))
    coroutine.yield(0.01)
end
StopProgress(pb)
```

### File & Path Functions

| Function | Description |
|----------|-------------|
| `GetPath(string[, boolean] or integer)` | Get system path (use `Enums.PathType.*`) |
| `GetPathSeparator()` | Returns "/" or "\" |
| `FileExists(string)` | Check if file exists |
| `DirList(string[, string])` | List files in directory |
| `Export(filename, data)` | Export to XML |
| `ExportCSV(filename, data)` | Export to CSV |
| `ExportJson(filename, data)` | Export to JSON |
| `Import(string)` | Import data |
| `CopyFile(string, string)` | Copy file |

**Enums.PathType values**: `Showfiles`, `Plugins`, `UserPlugins`, `Library`, `Temp`, etc.

### System Information

| Function | Description |
|----------|-------------|
| `Version()` | Software version info |
| `BuildDetails()` | Build details table (GitDate, CompileDate, BigVersion, etc.) |
| `HostType()` | Host type ("Console", "onPC") |
| `HostSubType()` | Host sub-type ("FullSize", "Light") |
| `HostOS()` | Operating system |
| `SerialNumber()` | Device serial number |
| `Time()` | Current time |
| `DeskLocked()` | Whether desk is locked |
| `GetShowFileStatus()` | Show file status |
| `NeedShowSave()` | Whether show needs saving |
| `ReleaseType()` | Release type info |

### Undo Functions

| Function | Description |
|----------|-------------|
| `CreateUndo(string)` | Create undo group, returns handle |
| `CloseUndo(handle)` | Close undo group |

### Hook Functions (Event Monitoring)

| Function | Description |
|----------|-------------|
| `HookObjectChange(function, handle, handle[, handle])` | Register callback for object changes. Returns hook ID. |
| `Unhook(integer)` | Remove hook by ID |
| `UnhookMultiple(function, handle, handle)` | Remove multiple hooks (any arg can be nil to wildcard) |
| `DumpAllHooks()` | Print all active hooks |

**Example:**
```lua
local luaComponentHandle = select(4, ...)

local function OnSequenceChange(changedObject)
    Printf("Changed: %s", tostring(changedObject.name))
end

local function Main(display_handle)
    local pluginHandle = luaComponentHandle:Parent()
    local hookId = HookObjectChange(OnSequenceChange, DataPool().Sequences, pluginHandle)
    -- Later: Unhook(hookId)
end
return Main
```

### Timer Function

| Function | Description |
|----------|-------------|
| `Timer(function, integer, integer[, function[, handle]])` | Call function repeatedly. Args: callback, interval_seconds, iteration_count, cleanup_fn, handle |

### Object List Function

| Function | Description |
|----------|-------------|
| `ObjectList(string[, table])` | Returns table of handles from command string. Options: `{reverse_order=bool, selected_as_default=bool}` |

**Example:**
```lua
local fixtures = ObjectList("Fixture 1 Thru 10")
for _, fix in ipairs(fixtures) do
    Printf("Fixture: %s", fix:AddrNative())
end
```

---

## 4. Object API (Handle Methods)

Objects returned by handles have these methods. Call them with `:` syntax.

### Address & Identity

```lua
local handle = Root().ShowData.DataPools[1].Sequences[1]
handle:Addr()          -- Numbered address string "14.14.1.6.1"
handle:AddrNative()    -- Named address string "ShowData.DataPools.Pool 1..."
handle:ToAddr()        -- Address string (object-free version also exists)
handle:Dump()          -- Print all info about object (properties, children)
handle:GetClass()      -- Class name string
handle:IsClass(string) -- Check if object is of class
```

### Property Access

```lua
-- Read properties directly
local name = handle.name
local appearance = handle.appearance

-- Set properties directly
handle.name = "New Name"

-- Method access
handle:Get("PropertyName")
handle:Set("PropertyName", value)
```

### Children & Navigation

```lua
handle:Children()        -- Get children table
handle:Count()           -- Number of children
handle:Parent()          -- Parent handle
handle:Index()           -- Index in parent
handle:CurrentChild()    -- Currently focused child
handle:Find(string)      -- Find child by name
handle:FindRecursive(string) -- Find child recursively
handle:FindWild(string)  -- Find with wildcards
```

### Object Manipulation

```lua
handle:Create()          -- Create new child
handle:Copy(destination) -- Copy object
handle:Delete()          -- Delete object
handle:Append()          -- Append to list
handle:Insert(index)     -- Insert at index
handle:Remove(index)     -- Remove at index
handle:ClearList()       -- Clear all children
```

### Fader Access (for executors/masters)

```lua
-- Read fader position (returns float 0-100)
local val = handle:GetFader({token="FaderMaster"})
-- Tokens: FaderMaster, FaderX, FaderXA, FaderXB, FaderTemp, FaderRate,
--         FaderSpeed, FaderHighlight, FaderLowlight, FaderSolo, FaderTime

-- Read fader as text
local text = handle:GetFaderText({token="FaderMaster"})

-- Set fader value
handle:SetFader({value=75, token="FaderMaster", faderEnabled=true})
```

### Object Info & Dependencies

```lua
handle:GetClass()              -- Class name string
handle:GetChildClass()         -- Class of children
handle:GetDependencies()       -- Table of dependency handles
handle:GetReferences()         -- Table of referencing objects
handle:HasActivePlayback()     -- Boolean: has active playback?
handle:GetUIEditor()           -- UI editor name
handle:GetUISettings()         -- UI settings name
```

### Status Checks

```lua
handle:IsEmpty()         -- Check if empty
handle:IsEnabled()       -- Check if enabled
handle:IsValid()         -- Check if valid
handle:HasEditSettingRecursive() -- Check recursive edit settings
handle:HasContent()      -- Check if has content
```

### Export/Import on Objects

```lua
handle:Export(path, "filename.xml")   -- Export object to XML
handle:Import(path, "filename.xml")   -- Import XML into object (MERGES without confirmation!)
```

---

## 5. Object Tree Navigation

The grandMA3 object tree is navigated starting from `Root()`:

### Common Paths

```lua
-- Sequences
Root().ShowData.DataPools[X].Sequences[Y]

-- Presets (poolNum is the preset type: 4=Dimmer, 8=Color, 23=All, etc.)
Root().ShowData.DataPools[X].PresetPools[poolNum][presetNum]

-- Groups
Root().ShowData.DataPools[X].Groups[Y]

-- Cues (within a sequence)
Root().ShowData.DataPools[X].Sequences[Y][cueNum]

-- Layouts
Root().ShowData.DataPools[X].Layouts[Y]

-- Layout Elements (1-indexed)
Root().ShowData.DataPools[X].Layouts[Y][elementIndex]

-- Macros
Root().ShowData.DataPools[X].Macros[Y]

-- Appearances
Root().ShowData.DataPools[X].Appearances[Y]

-- Executors (on current page)
Root().ShowData.DataPools[X].Pages[pageNum].Executors[execNum]

-- Masters / SpeedMasters
Root().ShowData.Masters.Speed[Y]

-- Fixture Types
Patch().FixtureTypes["TypeName"].DMXModes["Mode 0"]
```

### CRITICAL: Do NOT use `FromAddr()` for DataPool objects

```lua
-- WRONG - returns nil for DataPool objects
local seq = FromAddr("DataPool 3 Sequence 120")

-- CORRECT - use the Lua API path
local seq = Root().ShowData.DataPools[3].Sequences[120]
```

`FromAddr()` works for command-line style paths but NOT for DataPool-level object access.

### Reading Object Properties

```lua
local seq = Root().ShowData.DataPools[3].Sequences[120]
if seq then
    Printf("Name: %s", seq.name)
    Printf("Class: %s", seq:GetClass())
    seq:Dump()  -- Print all properties and children
end
```

---

## 6. MessageBox - Complete Dialog System

MessageBox is the primary UI function for creating complex dialogs.

### Full Structure

```lua
local result = MessageBox({
    -- Title bar
    title = "Dialog Title",
    titleTextColor = "Global.Text",      -- UI color reference
    backColor = "Global.Background",     -- UI color reference
    icon = "object_sequence",            -- Texture name

    -- Message
    message = "Instructions for user.\nLine 2.",
    messageTextColor = "Global.Text",
    message_align_h = Enums.AlignmentH.Left,

    -- Input fields (displayed in ALPHABETICAL order by name)
    inputs = {
        {
            name = "1. Field Name",         -- Prefix with numbers for ordering
            value = "default",              -- Pre-filled value
            whiteFilter = "1234567890",     -- Only these chars allowed
            blackFilter = "abc",            -- These chars blocked (use one or the other)
            vkPlugin = "TextInput",         -- Virtual keyboard type
            maxTextLength = 32              -- Max characters
        }
    },

    -- Selectors
    selectors = {
        {
            name = "Mode",
            selectedValue = 1,              -- Must match a value in values table
            type = 1,                       -- 0=swipe (horizontal), 1=radio (vertical)
            values = {
                ["Option A"] = 1,           -- ["Display Text"] = returnValue
                ["Option B"] = 2,
                ["Option C"] = 3
            }
        }
    },

    -- Checkboxes
    states = {
        {
            name = "Enable Feature",
            state = false                   -- Initial state
        }
    },

    -- Buttons (at bottom)
    commands = {
        {value = 1, name = "OK"},
        {value = 0, name = "Cancel"}
    },

    -- Timeout (optional)
    timeout = 30000,                        -- Milliseconds
    timeoutResultCancel = false,            -- If true, timeout = cancel
    timeoutResultID = 99                    -- Value returned on timeout
})
```

### Virtual Keyboard Types (`vkPlugin`)

- `"TextInput"` - Full text keyboard
- `"NumericInput"` - Numbers only
- `"CueNumberInput"` - Numbers with decimal point
- `"IP4Prefix"` - IP address format
- `"TextInputTimeOnly"` - Time input

### Display Order (FIXED, cannot be changed)

1. Title (top)
2. Message
3. Input fields (alphabetical by `name` - use numbered prefixes to control order)
4. Radio selectors (`type=1`)
5. Swipe selectors (`type=0`)
6. States/Checkboxes (alphabetical by `name`)
7. Command buttons (bottom, in defined order)

### Reading Response

```lua
if not result.success then
    Printf("User cancelled or dialog closed")
    return
end

if result.result == 0 then  -- Cancel button
    return
end

-- Access inputs
local value = result.inputs["1. Field Name"]
local num = tonumber(value)

-- Access selectors
local mode = result.selectors["Mode"]

-- Access checkboxes
local enabled = result.states["Enable Feature"]
```

### Common Icons

`"object_sequence"`, `"object_preset"`, `"object_group"`, `"object_macro"`,
`"object_appearance"`, `"object_layout"`, `"object_smart"`

---

## 7. Layout Programming

### Coordinate System - CRITICAL: Y=0 is at BOTTOM

```
     Y increases ↑
                 │
    Y=150 ──────┼──────
                 │
    Y=0   ══════╪══════ (bottom edge)
                 └──────→ X increases
```

### Creating Layout Elements (must use Lua API, NOT Cmd)

```lua
-- Layout commands via Cmd() DO NOT WORK (UI thread restriction)
-- Cmd("Store Sequence 1 At Layout 1") -- FAILS

-- Use Lua API instead:
local layout = Root().ShowData.DataPools[3].Layouts[1]
local seq = Root().ShowData.DataPools[3].Sequences[100]

local element = layout[1]  -- 1-indexed
if element then
    element.Object = seq
    element.PosX = 0
    element.PosY = 150
    element.PositionW = 70
    element.PositionH = 70
end
```

### Grid Layout Pattern

```lua
local elementSize = 70
local spacing = 5
local totalSize = elementSize + spacing
local maxColumns = 10
local totalRows = math.ceil(itemCount / maxColumns)

for i = 0, itemCount - 1 do
    local col = i % maxColumns
    local row = math.floor(i / maxColumns)
    local posX = col * totalSize
    local posY = (totalRows - 1 - row) * totalSize  -- Top-to-bottom (invert Y)
    -- Assign to layout element...
end
```

### Layout Limitations

- Cannot create new layouts from Lua (UI restriction)
- Cannot delete layouts from Lua
- Cannot use Store/Assign commands with layouts from Lua
- Layouts must exist before plugin runs
- Elements are 1-indexed

---

## 8. Sequence Properties

### Boolean Properties use "Yes"/"No" (NOT "On"/"Off")

```lua
-- Via Cmd():
Cmd('Set DataPool 3 Sequence 1 Thru 100 Property "OffWhenOverridden" "No"')
Cmd('Set DataPool 3 Sequence 1 Thru 100 Property "UseExecutorTime" "No"')
Cmd('Set Sequence 10 Property "SpeedMaster" "Main Speed"')
Cmd('Set Sequence 10 Property "SpeedScale" "One"')  -- "Div2", "One", "Mul2"
Cmd('Set Sequence 10 Property "LockSequence" "Yes"')
```

### SpeedMaster Assignment - Always use NAMED SpeedMasters

```lua
-- GOOD: Named (self-documenting)
Cmd('Label Master 3.1 "Main Speed"')
Cmd('Set Sequence 1 Thru 50 Property "SpeedMaster" "Main Speed"')

-- BAD: Numeric (unreadable)
Cmd('Set Sequence 1 Property "SpeedMaster" "3.1"')
```

### Master Category Numbers

- `Master 1.x` = Selected Sequence Master
- `Master 2.x` = GrandMaster
- `Master 3.x` = SpeedMaster (1-15)
- `Master 4.x` = PlaybackMaster

---

## 9. Debugging

### Terminal / System Monitor

```bash
# macOS - Launch Terminal
/Applications/grandMA3.app/Contents/MacOS/gma3_2.2.5/app_terminal

# Connect to local system monitor
sysmon 127.0.0.1

# Check version path
cat /Applications/grandMA3.app/Contents/MacOS/current_version
```

**Windows**: Start Menu → MA Lighting → grandMA3 Terminal → `sysmon 127.0.0.1`

### Debug Pattern

```lua
local DEBUG = true

local function DebugPrint(msg, ...)
    if DEBUG then Printf("[DEBUG] " .. msg, ...) end
end

-- Use throughout code
DebugPrint("Processing item %d: %s", i, name)
```

### Printf Format Specifiers

- `%s` - string (use `tostring()` for non-strings)
- `%d` - integer
- `%f` - float
- `%i` - integer (alternative)

---

## 10. Error Handling

### Always use pcall() for API access

```lua
local success, result = pcall(function()
    local obj = Root().ShowData.DataPools[3].Sequences[120]
    if obj and obj.name then
        return obj.name
    end
    return nil
end)

if success and result then
    Printf("Found: %s", result)
else
    Printf("Error: %s", tostring(result))
end
```

### Input Validation After MessageBox

```lua
local num = tonumber(response.inputs["Number Field"])
if not num then
    Printf("Error: Invalid number")
    return
end
if num < 1 or num > 999 then
    Printf("Error: Number must be 1-999")
    return
end
```

---

## 11. Common Patterns

### Complete Plugin Template

```lua
local pluginName    = select(1, ...)
local componentName = select(2, ...)
local signalTable   = select(3, ...)
local my_handle     = select(4, ...)

local function Main(display_handle, argument)
    Printf("=== %s Started ===", pluginName)

    -- Show dialog
    local response = MessageBox({
        title = pluginName,
        icon = "object_plugin",
        message = "Configure settings:",
        inputs = {
            {name = "1. Value", value = "1", whiteFilter = "1234567890", vkPlugin = "NumericInput"}
        },
        commands = {
            {value = 1, name = "Execute"},
            {value = 0, name = "Cancel"}
        }
    })

    if not response.success or response.result == 0 then
        Printf("Cancelled")
        return
    end

    local value = tonumber(response.inputs["1. Value"])
    if not value then
        ErrPrintf("Invalid input")
        return
    end

    -- Do work with pcall
    local ok, err = pcall(function()
        -- Plugin logic here
        Printf("Processing value: %d", value)
    end)

    if not ok then
        ErrPrintf("Error: %s", tostring(err))
    end

    Printf("=== %s Complete ===", pluginName)
end

return Main
```

### Iterating Through Objects

```lua
-- Iterate sequences
local pool = Root().ShowData.DataPools[1]
local i = 1
while true do
    local seq = pool.Sequences[i]
    if not seq then break end
    Printf("Seq %d: %s", i, seq.name or "unnamed")
    i = i + 1
end
```

### Using Variables Between Plugins

```lua
-- Save state
SetVar(UserVars(), "lastSequence", 42)

-- Read in another plugin
local last = GetVar(UserVars(), "lastSequence")
```

### Coroutine Yielding (prevent UI freeze)

```lua
-- Yield periodically in long loops
for i = 1, 1000 do
    -- do work...
    if i % 10 == 0 then
        coroutine.yield(0.01)  -- Yield every 10 iterations
    end
end
```

---

## 12. Critical Rules & Pitfalls

1. **NEVER use `FromAddr()` for DataPool objects** - use `Root().ShowData.DataPools[X]...` instead
2. **Layout Store/Assign via `Cmd()` FAILS** - use Lua API for layout manipulation
3. **Y=0 is at BOTTOM** in layout coordinates (Cartesian, not screen coords)
4. **Boolean properties use "Yes"/"No"**, not "On"/"Off" or "True"/"False"
5. **MessageBox inputs are sorted alphabetically** - prefix with numbers for ordering
6. **Always use `pcall()`** when accessing the object tree
7. **Always validate user input** after MessageBox returns
8. **Use named SpeedMasters** in production (not numeric references)
9. **`whiteFilter` prevents typing but doesn't validate** - always check with `tonumber()` after
10. **Connect terminal** (`sysmon 127.0.0.1`) to see Printf output during development
11. **Use `coroutine.yield()`** in long loops to prevent UI freeze
12. **Layouts must exist before plugin runs** - cannot create via Lua
13. **Layout elements are 1-indexed**

---

## 13. External References

When you need more information:

- **Official MA3 Lua API**: https://help.malighting.com/grandMA3/2.2/HTML/lua_interface.html
- **Official Plugins page**: https://help.malighting.com/grandMA3/2.2/HTML/plugins.html
- **MessageBox reference**: https://help.malighting.com/grandMA3/2.3/HTML/lua_objectfree_messagebox.html
- **Community reference**: https://grandma3.bambinito.net/
- **TypeScript types (API reference)**: https://github.com/LightYourWay/grandMA3-types
- **API Documentation**: https://github.com/MacTirney/GrandMA3-API-Documentation
- **Plugin examples (hossimo)**: https://github.com/hossimo/GMA3Plugins
- **Plugin examples (patopesto)**: https://github.com/patopesto/GrandMA3-Plugins
- **Plugin examples (DeeeLight)**: https://github.com/DeeeLight/FromDarkToLightTutorials
- **TS plugin template**: https://github.com/LightYourWay/grandMA3-ts-template-plugin
- **MA Forum**: https://forum.malighting.com

If the user's question requires API details not covered here, search for the specific function in the local docs at `/Users/criss/work/cue++/ma3/docs/knowledge/` or use WebSearch/WebFetch to check the official MA docs or GitHub repos listed above.

---

## 14. When Helping Users

1. **Always start with a working plugin skeleton** - include XML + Lua with proper structure
2. **Use MessageBox for all user input** - never multiple TextInput calls
3. **Include error handling** with pcall for all object tree access
4. **Include Printf debugging** throughout the code
5. **Validate all inputs** with proper range checks
6. **Use numbered prefixes** in MessageBox field names for ordering
7. **Comment coordinate system** when doing layout work (remind about Y=0 at bottom)
8. **Test small first** - suggest testing with 2-3 items before full runs
9. **Reference local knowledge** - check `/docs/knowledge/` in the project for detailed guides
