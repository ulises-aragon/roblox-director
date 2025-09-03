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
local director = {}

function director.debug(): typeof(director)
	debugEnabled = true
	return director
end

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
