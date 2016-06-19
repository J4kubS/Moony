local class = require('moony.class')

local M, MT = {}, {}
local Enumerable = class()

local setmetatable = _G.setmetatable
local assert = _G.assert
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type

local yield = coroutine.yield
local wrap = coroutine.wrap

function Enumerable:init(iterator)
	assert(type(iterator) == 'function', 'Expected iterator function')

	self._iterator = iterator
end

function Enumerable:iterator()
	return self._iterator()
end

function Enumerable:where(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	return Enumerable:new(function()
		return wrap(function()
			for item in self:iterator() do
				if predicate(item) then
					yield(item)
				end
			end
		end)
	end)
end

function Enumerable:select(selector)
	assert(type(selector) == 'function', 'Expected selector function')

	return Enumerable:new(function()
		return wrap(function()
			for item in self:iterator() do
				yield(selector(item))
			end
		end)
	end)
end

function Enumerable:first_or_nil()
	return self:first() or nil
end

function Enumerable:first()
	return (self:iterator())()
end

function Enumerable:all(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	for item in self:iterator() do
		if not predicate(item) then
			return false
		end
	end

	return true
end

function Enumerable:any(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	for item in self:iterator() do
		if predicate(item) then
			return true
		end
	end

	return false
end

function M.from_dictionary(dictionary)
	assert(type(dictionary) == 'table', 'Expected dictionary')

	return Enumerable:new(function()
		return wrap(function()
			for key, value in pairs(dictionary) do
				yield({ key = key, value = value })
			end
		end)
	end)
end

function M.from_list(list)
	assert(type(list) == 'table', 'Expected list')

	return Enumerable:new(function()
		return wrap(function()
			for _, value in ipairs(list) do
				yield(value)
			end
		end)
	end)
end

function M.from_iterator(iterator)
	return Enumerable:new(iterator)
end

function M.from_nil()
	return M.from_list({})
end

function M.from(auto)
	if Enumerable.class_of(auto) then
		return auto
	end

	if type(auto) == 'table' then
		if auto[1] == nil then
			return M.from_dictionary(auto)
		else
			return M.from_list(auto)
		end
	end

	if type(auto) == 'function' then
		return M.from_iterator(auto)
	end

	return M.from_nil()
end

function MT.__call(_, ...)
	return M.from(...)
end

setmetatable(M, MT)

return M
