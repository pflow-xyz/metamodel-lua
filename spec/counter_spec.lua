dofile('./spec/debug.lua')

describe("Metamodel", function()
  dofile('./src/metamodel.lua')

  describe("counter", function()
    it("should load the model", function()
      dofile('./examples/counter_model.lua')
      local state = model.counter.initial_vector()
      local history = {}

      local function fire(action, multiple)
        local res = model.counter.fire(state, action, multiple or 1)
        if res.ok then
          table.insert(history, action)
        end
        return res.ok
      end

      local function is_live(action, multiple)
        return model.counter.test_fire(state, action, multiple or 1).ok
      end

      -- unbounded increment
      assert.True(is_live('inc0'))
      assert.are.same(state, {1, 0, 0})
      assert.True(fire('inc0'))
      assert.are.same(state, {2, 0, 0})

      -- with multiple
      assert.True(fire('inc0', 3))

      -- test guard clause
      assert.True(fire('inc2'))
      assert.are.same(state, {5, 0, 1})
      assert.False(is_live('inc0'))
      assert.False(fire('inc0'))

      -- test capacity limit
      assert.False(fire('inc2'))

      -- test decrement to remove guard
      assert.True(fire('dec2'))
      assert.True(is_live('inc0'))

    end)
  end)
end)
