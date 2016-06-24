--- Query library inspired by LINQ.
-- @module moony.query

local class = require('moony.class')

local M, MT = {}, {}
local Iterable = class()

local setmetatable = _G.setmetatable
local assert = _G.assert
local ipairs = _G.ipairs
local pairs = _G.pairs
local type = _G.type

local yield = coroutine.yield
local wrap = coroutine.wrap

local insert = table.insert

--- Factories
-- @section Factories

--- Creates `Iterable` from given source.
-- Type of the `source` is detected and appropriate factory function is used.
-- @param source data source
-- @return instance of `Iterable`
-- @see from_dictionary
-- @see from_list
-- @see from_iterator
-- @see from_nil
-- @usage local iterable = query({1, 2, 3})
function M.from(source)
	if Iterable.class_of(source) then
		return source
	end

	if type(source) == 'table' then
		if source[1] == nil then
			return M.from_dictionary(source)
		else
			return M.from_list(source)
		end
	end

	if type(source) == 'function' then
		return M.from_iterator(source)
	end

	return M.from_nil()
end

--- Creates `Iterable` from given list.
-- Ordering of the items is maintained.
-- @param list list containing data
-- @return instance of `Iterable`
function M.from_list(list)
	assert(type(list) == 'table', 'Expected list')

	return Iterable:new(function()
		return wrap(function()
			for _, value in ipairs(list) do
				yield(value)
			end
		end)
	end)
end

--- Creates `Iterable` from given dictionary.
-- All key/value pairs are converted to a list of `KeyValuePair` tables with arbitrary order.
-- @param dictionary dictionary containing data
-- @return instance of `Iterable`
function M.from_dictionary(dictionary)
	assert(type(dictionary) == 'table', 'Expected dictionary')

	return Iterable:new(function()
		return wrap(function()
			for key, value in pairs(dictionary) do
				yield({ key = key, value = value })
			end
		end)
	end)
end

--- Creates `Iterable` from given iterator.
-- @param iterator iterator to be used as data source
-- @return instance of `Iterable`
function M.from_iterator(iterator)
	return Iterable:new(iterator)
end

--- Creates empty `Iterable`.
-- @return instance of `Iterable`
function M.from_nil()
	return M.from_list({})
end

--- Iterable
-- @section Iterable

function Iterable:init(iterator)
	assert(type(iterator) == 'function', 'Expected iterator function')

	self._iterator = iterator
end

--- Filters
-- @section Filters

--- Filters `Iterable` based on a predicate.
-- @param predicate A function to test each item
-- @return filtered `Iterable`
function Iterable:where(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	return Iterable:new(function()
		return wrap(function()
			for item in self._iterator() do
				if predicate(item) then
					yield(item)
				end
			end
		end)
	end)
end

--- Transformations
-- @section Transformations

--- Transforms each item of `Iterable`.
-- @param selector A function to transform each item
-- @return transformed `Iterable`
function Iterable:select(selector)
	assert(type(selector) == 'function', 'Expected selector function')

	return Iterable:new(function()
		return wrap(function()
			for item in self._iterator() do
				yield(selector(item))
			end
		end)
	end)
end

--- Predicates
-- @section Predicates

--- Checks whether all items of `Iterable` satisfy a predicate.
-- @param predicate A function to test each item
-- @return `true` if all items of `Iterable` satisfy the predicate; `false` otherwise
function Iterable:all(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	for item in self._iterator() do
		if not predicate(item) then
			return false
		end
	end

	return true
end

--- Checks whether any item of `Iterable` satisfies a predicate.
-- @param predicate A function to test each item
-- @return `true` if any item of `Iterable` satisfies the predicate; `false` otherwise
function Iterable:any(predicate)
	assert(type(predicate) == 'function', 'Expected predicate function')

	for item in self._iterator() do
		if predicate(item) then
			return true
		end
	end

	return false
end

--- Evaluation
-- @section Evaluation

--- Creates a list from `Iterable`.
-- @return list containing all items from `Iterable`
function Iterable:to_list()
	local list = {}

	for item in self:_iterator() do
		insert(list, item)
	end

	return list
end

--- Creates a dictionary from `Iterable`.
-- @return dictionary created from all `KeyValuePair` items of `Iterable`
function Iterable:to_dictionary()
	local dictionary = {}

	for item in self:_iterator() do
		if type(item) == 'table' and item.key ~= nil then
			dictionary[item.key] = item.value
		end
	end

	return dictionary
end

--- Get the iterator of `Iterable`.
-- @return iterator function
function Iterable:to_iterator()
	return self:_iterator()
end

--- Get the first item of `Iterable` or `nil` if no item is found.
-- @return the first item of `Iterable` or `nil` if `Iterable` is empty
function Iterable:first_or_nil()
	return self:first() or nil
end

--- Get the first item of `Iterable`.
-- @return the first item of `Iterable`
function Iterable:first()
	return (self._iterator())()
end

--- Key/Value Pair
-- @section KeyValuePair

--- Table holding a key/value pair.
-- @table KeyValuePair
-- @field key key from the original dictionary
-- @field value value from the original dictionary

function MT.__call(_, ...)
	return M.from(...)
end

return setmetatable(M, MT)
