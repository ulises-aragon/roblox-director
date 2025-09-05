<div align="center">
	<h1>Director</h1>
</div>

The Director module for Roblox provides organized loading and management of data components.
<!--moonwave-hide-before-this-line-->


# Director and Registry System

When building data-driven games, you often create many ModuleScripts containing configurations for weapons, skills, NPCs, etc. Normally, you'd need to manually `require()` each one and hope the data structure is correct.

**Director and Registries solve this by:**
- Automatically discovering and loading all your data modules from folders
- Ensuring type safety so you catch data structure mistakes before runtime
- Organizing everything with simple ID-based lookup

## How Registries Work

Think of a Registry as a **typed container** for related data:

1. **Point it at a folder** containing your ModuleScripts
2. **Registry automatically loads** each ModuleScript and assigns it an ID (the script's name)
3. **Fetch data by ID** with full type safety - your code knows exactly what data structure to expect

### Example
```lua
-- Create a registry for weapon data
local weaponRegistry: Registry<WeaponData> = director.createRegistry("Weapons", weaponsFolder)

-- Registry loads all ModuleScripts in weaponsFolder automatically
weaponRegistry:load() -- This is a manual load for registry, you wouldn't use this on a normal setup.

-- Fetch specific weapons with type safety
local sword: WeaponData? = weaponRegistry:fetch("Sword")  -- Returns WeaponData or nil
local bow: WeaponData? = weaponRegistry:fetch("Bow")

-- Luau/TypeScript ensures your data matches WeaponData structure
```

## Benefits

- **No manual requires** - Just point at folders and let Registry handle loading
- **Type safety** - Catch data structure errors at compile-time, not runtime
- **Clean organization** - ID-based lookup instead of scattered require() calls
- **Factory support** - Transform raw module data into proper class instances