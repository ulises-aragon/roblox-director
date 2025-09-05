--// Modules
local Promise = require(script.Parent.Parent.Promise)
--// Types
type Promise = Promise.Promise
type TypedPromise<T...> = Promise.TypedPromise<T...>
--// Registry
--[=[
	@class Registry

	A Registry is a collection manager that allows you to load, store, and manage records of a specific type. It supports loading records from ModuleScripts, inserting new records, fetching existing records, and more.
]=]
local registry = {}
registry.__index = registry

export type Factory<A, B> = (data: A) -> B
export type _registry<T> = {
	name: string,
	debugEnabled: boolean,
	root: Folder?,
	records: { [string]: T },
	entries: { string },
	size: number,
	factory: Factory<any, T>?,
}
export type Registry<T> = typeof(setmetatable({} :: _registry<T>, registry))

--[=[
	@method info
	@within Registry
	@private
	@param ... any -- The info message components.
	Outputs an info message prefixed with the registry name.
]=]
function registry.info(self: Registry<any>, ...): ()
	print(`[Registry] {self.name}: {...}`)
end

--[=[
	@method log
	@within Registry
	@private
	@param ... any -- The log message components.
	Outputs a log message prefixed with the registry name if debug mode is enabled.
]=]
function registry.log(self: Registry<any>, ...): ()
	if not self.debug then
		return
	end
	self:info(...)
end

--[=[
	@method warn
	@within Registry
	@private
	@param ... any -- The warning message components.
	Outputs a warning message prefixed with the registry name.
]=]
function registry.warn(self: Registry<any>, ...): ()
	warn(`[Registry] {self.name}: {...}`)
end

--[=[	
	@method getSize
	@within Registry
	@return number -- The number of records in the registry.
	Returns the number of records in the registry.
]=]
function registry.getSize<T>(self: Registry<T>): number
	return self.size
end

--[=[
	@method getRecords
	@within Registry
	@return { [string]: T } -- The records in the registry.
	Returns all records in the registry.
]=]
function registry.getRecords<T>(self: Registry<T>): { [string]: T }
	return self.records
end

--[=[
	@method getEntries
	@within Registry
	@return { string } -- The list of entries' IDs.
	Returns all entry IDs in the registry.
]=]
function registry.getEntries<T>(self: Registry<T>): { string }
	return self.entries
end

--[=[
	@method fetch
	@within Registry
	@param id string -- The ID of the record to fetch.
	@return T? -- The record if found, otherwise nil.
	Fetches a record by its ID.
]=]
function registry.fetch<T>(self: Registry<T>, id: string): T?
	local record = self.records[id]
	if not record then
		self:warn(`Couldn't fetch record with id: {id}`)
	end
	return record
end

--[=[
	@method insert
	@within Registry
	@param id string -- The ID of the record.
	@param entry T -- The record to insert.
	@return boolean -- True if the record was inserted, false if a record with the same ID already exists.
	Inserts a new record into the registry.
]=]
function registry.insert<T>(self: Registry<T>, id: string, entry: T): boolean
	if self.records[id] then
		self:warn(`Record with id: {id} already exists!`)
		return false
	end

	self.records[id] = entry
	table.insert(self.entries, id)
	self.size += 1
	return true
end

--[=[
	@method factorize
	@within Registry
	@param factory (data: any) -> T -- A function that takes raw data and returns a record of type T.
	Sets a factory function for creating records.
]=]
function registry.factorize<T>(self: Registry<T>, factory: (data: any) -> T): ()
	self.factory = factory
end

--[=[
	@method load
	@within Registry
	@param folder Folder? -- Optional Folder to load records from. If not provided, uses the registry's root.
	@return Promise<number> -- A Promise that resolves with the number of records successfully registered.
	Loads records from the specified folder or the registry's root.
]=]
function registry.load<T>(self: Registry<T>, folder: Folder?): TypedPromise<number>
	local root = folder or self.root
	if not root then
		self:warn("No root folder provided for loading records")
		return Promise.reject(0)
	end

	return Promise.new(function(resolve: (registered: number) -> ())
		self:log(`Loading records from "{root:GetFullName()}"...`)
		local registeredRecords = 0

		local descendants = root:GetDescendants()
		for _, descendant in descendants do
			if not descendant:IsA("ModuleScript") then
				return
			end

			local fullName = descendant:GetFullName()
			local success, result = pcall(require, descendant)

			if success then
				local record: T
				if self.factory then
					record = self.factory(result)
				else
					record = result :: T
				end

				local inserted = self:insert(descendant.Name, record)
				if inserted then
					registeredRecords += 1
					self:log(`Registered: {descendant.Name}`)
				else
					self:warn(`Failed to load record: {descendant.Name}`)
				end
			else
				self:warn(`Failed to require ModuleScript: {fullName} - {result}`)
			end
		end

		self:info(`Finished registry, registered {registeredRecords} records!`)
		resolve(registeredRecords)
	end)
end

--[=[
	@method debug
	@within Registry
	@param enable boolean? -- Optional boolean to enable or disable debug mode. Defaults to true if not provided.
	@return Registry<T> -- The registry instance for chaining.
	Enables debug mode for the registry.
]=]
function registry.debug<T>(self: Registry<T>, enable: boolean): Registry<T>
	self.debugEnabled = if enable == nil then true else enable
	return self
end

return registry
