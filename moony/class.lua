--- Simple framework for creating classes.
-- @module moony.class

local M, MT = {}, {}

local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local assert = _G.assert
local rawget = _G.rawget
local pairs = _G.pairs
local type = _G.type

--- Checks whether `some_object` is instance of `some_class`.
-- This function is dual to `class_of`.
-- @function some_object:instance_of
-- @param some_class class to check against
-- @return `true` if `some_object` is instance of `some_class`; `false` otherwise
local function instance_of(self, class)
	if type(self) == 'table' and type(class) == 'table' then
		local cls = getmetatable(self)

		while cls do
			if cls == class then
				return true
			end

			cls = rawget(cls, '_super')
		end
	end

	return false
end

--- Checks whether `some_class` is class of `some_object`.
-- This function is dual to `instance_of`.
-- @function some_class:class_of
-- @param some_object object to check against
-- @return `true` if `some_class` is class of `some_object`; `false` otherwise
local function class_of(self, object)
	if type(self) == 'table' and rawget(self, 'instance_of') then
		return self.instance_of(object, self)
	end

	return false
end

--- Initializes an instance of `some_class`.
-- This function is called when new instance of a class is created.
-- @function some_class:init
-- @param[opt] ... initialization parameters
-- @usage local Foo = class()
-- function Foo:init(bar)
--   -- Bar.init(self, bar) -- call parent initializator if needed
--   self.bar = bar
-- end
--
-- local foo = Foo:new('baz')
-- print(foo.bar) -- prints 'baz'

--- Creates new instance of `some_class`.
-- If defined, `init` function will be called to initialize the newly created instance.
-- @function some_class:new
-- @param[opt] ... parameters passed to the `init` function.
-- @return new instance of `some_class`
-- @usage local Foo = class()
-- function Foo:bar()
--   print('baz')
-- end
--
-- local foo = foo:new()
-- foo:bar() -- prints 'baz'
local function new_object(class, ...)
	assert(type(class) == 'table', 'Class must be a table')

	local object = setmetatable({}, class)
	object._class = class

	if rawget(class, 'init') then
		class.init(object, ...)
	end

	return object
end

local function inherit(child, parent)
	for key, val in pairs(parent) do
		if not child[key] then
			child[key] = val
		end
	end
end

--- Creates new class, derived from a given parent class.
-- Any table can be used as a parent class.
-- @function class
-- @param[opt] super parent class
-- @return new class
local function new_class(super)
	local class = {}

	if type(super) == 'table' then
		inherit(class, super)
		class._super = super
	end

	class.__index = class
	class.instance_of = instance_of
	class.class_of = class_of
	class.new = new_object

	return class
end

function MT.__call(_, ...)
	return new_class(...)
end

setmetatable(M, MT)

return M
