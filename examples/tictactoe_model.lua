domodel("TicTacToe", function (fn, cell, role)

    local function row(n)
        return {
            [0] = cell(n..0, 1, 1),
            [1] = cell(n..1, 1, 1),
            [2] = cell(n..2, 1, 1)
        }
    end

    local board = {
        [0] = row(0),
        [1] = row(1),
        [2] = row(2)
    }

    local X, O = "X", "O"

    local players = {
        [X] = {
            turn = cell(X, 1, 1),
            role = role(X),
            next = O
        },
        [O] = {
            turn = cell(O, 0, 1),
            role = role(O),
            next = X
        }
    }

    for i, board_row in pairs(board) do
        for j in pairs(board_row) do
            for marking, player in pairs(players) do
                local move = fn(marking..i..j, player.role)
                player.turn.tx(1, move)
                board[i][j].tx(1, move)
                move.tx(1, players[player.next].turn)
            end
        end
    end

end)