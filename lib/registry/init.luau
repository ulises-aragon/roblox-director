--// Modules
local Promise = require(script.Parent.Parent.Promise)
--// Types
type Promise = Promise.Promise
type TypedPromise<T...> = Promise.TypedPromise<T...>
--// Registry
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

function registry.info(self: Registry<any>, ...): ()
	print(`[Registry] {self.name}: {...}`)
end

function registry.log(self: Registry<any>, ...): ()
	if not self.debug then
		return
	end
	self:info(...)
end

function registry.warn(self: Registry<any>, ...): ()
	warn(`[Registry] {self.name}: {...}`)
end

function registry.getSize<T>(self: Registry<T>): number
	return self.size
end

function registry.getRecords<T>(self: Registry<T>): { [string]: T }
	return self.records
end

function registry.getEntries<T>(self: Registry<T>): { string }
	return self.entries
end

function registry.fetch<T>(self: Registry<T>, id: string): T?
	local record = self.records[id]
	if not record then
		self:warn(`Couldn't fetch record with id: {id}`)
	end
	return record
end

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

function registry.factorize<T>(self: Registry<T>, factory: (data: any) -> T): ()
	self.factory = factory
end

function registry.load<T>(self: Registry<T>, folder: Folder?): TypedPromise<number>
	local root = folder or self.root
	if not root then
		self:warn("No root folder provided for loading records")
		return Promise.reject(0)
	end

	return Promise.new(function(resolve: (registered: number) -> ())
		self:info(`Loading records from "{root:GetFullName()}"...`)
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

function registry.debug<T>(self: Registry<T>, enable: boolean): Registry<T>
	self.debugEnabled = if enable == nil then true else enable
	return self
end

return registry
