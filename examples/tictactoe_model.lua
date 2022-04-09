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
            turn = cell(X, 1, 1), -- track turns, X goes first
            role = role(X), -- player X can only mark X's
            next = O -- O moves next
        },
        [O] = {
            turn = cell(O, 0, 1), -- track turns, moves second
            role = role(O), -- player O can only mark O's
            next = X -- X moves next
        }
    }

    for i, board_row in pairs(board) do
        for j in pairs(board_row) do
            for marking, player in pairs(players) do
                local move = fn(marking..i..j, player.role) -- make a move
                player.turn.tx(1, move) -- take turn
                board[i][j].tx(1, move) -- take board space
                move.tx(1, players[player.next].turn) -- mark next turn
            end
        end
    end

end)