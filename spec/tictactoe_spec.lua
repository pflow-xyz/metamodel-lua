dofile('././spec/debug.lua')
describe("Metamodel", function()
  dofile('./src/metamodel.lua')

  describe("TicTacToe", function()
    it("should load the model", function()
      dofile('./examples/tictactoe_model.lua')

      local state = model.TicTacToe.initial_vector()
      local history = {}

      local function move(action)
        local res = model.TicTacToe.fire(state, action, 1)
        if res.ok then
          table.insert(history, action)
        end
        return res.ok
      end

      assert.True(move("X11"))
      assert.False(move("O11")) -- move taken
      assert.True(move("O01"))
      assert.False(move("X11")) --  move taken
      assert.True(move("X00"))
      assert.True(move("O02"))
      assert.True(move("X22"))

      assert.are.same(#history, 5)
      print_r(model.TicTacToe.def)

    end)
  end)

end)