-- MIT License
--
-- Copyright (c) 2022 stackdump.com LLC
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- model definitions indexed by schema name
model = {}

-- load a model using internal Lua DSL
function domodel(schema, declaration)

	local def = {
		schema = schema,
		roles = {},
		places = {},
		transitions = {},
		arcs = {},
	}

	local function fn (label, role, position)
		local transition = {
			label=label,
			role=role,
			position = position,
			guards={},
			delta={},
		}
		def.transitions[label] = transition
		return {
			transition = transition,
			tx = function(weight, target)
				assert(target, 'target is nil')
				assert(target.place, 'target node must be a place')
				table.insert(def.arcs, {
					source = { transition = transition },
					target = target, weight = weight
				})
			end,
		}
	end

	local place_count = 0

	local function cell (label, initial, capacity, position)
		place_count = place_count + 1
		local place = {
			label=label,
			initial=initial or 0,
			capacity=capacity or 0,
			position=position or {},
			offset= place_count
		}
		def.places[label] = place

		local function tx(weight, target)
			table.insert(def.arcs, {
				source = { place = place },
				target = target,
				weight = weight or 1
			})
			assert(target.transition, 'target node must be a transition')
			return
		end

		local function guard (weight, target)
			table.insert(def.arcs, {
				source = { place = place },
				target = target,
				weight = weight,
				inhibit = true
			})
			assert(target.transition, 'target node must be a transition')
		end

		return {
			place = place,
			tx = tx,
			guard = guard,
		}
	end

	local function role (label)
		if not def.roles[label] then
			def.roles[label] = { label=label }
		end
		return def.roles[label]
	end

	declaration(fn, cell, role)

	local function empty_vector()
		local v = {}
		for _, p in pairs( def.places ) do
			v[p.offset] = 0
		end
		return v
	end

	local function initial_vector()
		local v = {}
		for _, p in pairs( def.places ) do
			v[p.offset] = p.initial
		end
		return v
	end

	local function capacity_vector()
		local v = {}
		for _, p in pairs( def.places ) do
			v[p.offset] = p.capacity
		end
		return v
	end

	for _, t in pairs( def.transitions ) do
		t.delta = empty_vector() -- right size all deltas
	end

	for _, arc in pairs( def.arcs ) do
		if (arc.inhibit) then
			local g = {
				label = arc.source.place.label,
				delta = empty_vector(),
			}
			g.delta[arc.source.place.offset] = 0-arc.weight
			arc.target.transition.guards[arc.source.place.label] = g
		else
			if (arc.source.transition) then
				arc.source.transition.delta[arc.target.place.offset] = arc.weight
			else
				arc.target.transition.delta[arc.source.place.offset] = 0-arc.weight
			end
		end
	end

	local function vector_add(state, delta, multiple)
		local cap = capacity_vector()
		local out = {}
		local ok = true
		for i in pairs(state) do
			out[i] = state[i] + delta[i] * multiple

			if (out[i] < 0) then
				ok = false -- underflow: contains negative
			elseif (cap[i] > 0 and cap[i] - out[i] < 0) then
				ok = false -- overflow: exceeds capacity
			end
		end
		return { out=out, ok=ok }
	end

	local function guard_fails(state, action, multiple)
		local t = def.transitions[action]
		assert(t, 'action not found: '..action)
		for _, guard in pairs(t.guards) do
			local res = vector_add(state, guard.delta, multiple)
			if res.ok then
				return true -- inhibitor active
			end
		end
		return false -- inhibitor inactive
	end

	local function test_fire(state, action, multiple)
		local t = def.transitions[action]
		if guard_fails(state, action, multiple) then
			return { out = nil, ok = false, role = t.role.label }
		end
		local res = vector_add(state, t.delta, multiple)
		return { out = res.out, ok = res.ok, role = t.role.label }
	end

	local function fire(state, action, multiple, resolve, reject)
		local res = test_fire(state, action, multiple)
		if res.ok then
			for i, v in pairs(res.out) do
				state[i] = v
			end
			if resolve then
				resolve()
			end
		else
			if reject then
				reject()
			end
		end
		return res
	end

	model[schema] = {
		def = def,
		empty_vector = empty_vector,
		initial_vector = initial_vector,
		capacity_vector = capacity_vector,
		test_fire = test_fire,
		fire = fire,
	}
end