--// Services
local HttpService = game:GetService("HttpService")
--// Modules
local Promise = require(script.Parent.Promise)
local registry = require(script.registry)
--// Types
type Promise = Promise.Promise
type TypedPromise<T...> = Promise.TypedPromise<T...>
type _registry<T> = registry._registry<T>
export type Registry<T> = registry.Registry<T>
--// Local
local debugEnabled = false
local log = function(...): ()
	print(`[Director] {...}`)
end

local warn = function(...): ()
	warn(`[Director] {...}`)
end
--// Director
--[=[
	@class Director
	The Director is responsible for managing the registries.
]=]
local director = {}

--[=[
	@within Director
	@return Director -- The director module for chaining.
	Enables debug mode for the director and all registries created thereafter.
]=]
function director.debug(): typeof(director)
	debugEnabled = true
	return director
end

--[=[
	@within Director
	@param name string? -- If not provided, a GUID will be generated.
	@param root Folder? -- Optional Folder to serve as the root for the registry.
	@return Registry<T> -- A new Registry instance.
	Initializes a new registry.
]=]
function director.createRegistry<T>(name: string?, root: Folder?): Registry<T>
	local newRegistry = setmetatable(
		{
			name = name or HttpService:GenerateGUID(false),
			root = root,
			records = {},
			entries = {},
			size = 0,
			factory = nil,
		} :: _registry<T>,
		registry
	) :: Registry<T>

	return newRegistry
end

--[=[
	@within Director
	@param directory Folder -- The Folder containing registry ModuleScripts.
	@external Promise https://eryn.io/roblox-lua-promise/api/Promise
	@return Promise -- A Promise that resolves when all registries have been processed.
	Runs all registries found within the specified directory.
]=]
function director.run(directory: Folder): Promise
	log(`Running registries from "{directory:GetFullName()}"`)
	local errors = 0
	local promises: { Promise } = {}

	for _, descendant in directory:GetDescendants() do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		local registryModule: Registry<any>
		local success, err = pcall(function()
			registryModule = require(descendant :: ModuleScript) :: Registry<any>
		end)

		if not success then
			warn(`Failed to load registry: "{descendant.Name}" - {err}`)
			errors += 1
			continue
		end

		table.insert(promises, registryModule:debug(debugEnabled):load())
	end

	return Promise.new(function(resolve: () -> ())
		Promise.all(promises):await()
		log(`Finished running registries with {errors} errors`)
		resolve()
	end)
end

return director
