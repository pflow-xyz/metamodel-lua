domodel("TicTacToe", function (fn, cell, role)

    local function space(row, col)
        return cell(row..col, 1, 1)
    end

    local board = {
        [0] = {
            [0] = space(0,0),
            [1] = space(0,1),
            [2] = space(0,2)
        },
        [1] = {
            [0] = space(1,0),
            [1] = space(1,1),
            [2] = space(1,2)
        },
        [2] = {
            [0] = space(2,0),
            [1] = space(2,1),
            [2] = space(2,2)
        }
    }

    local X = "X"
    local O = "O"

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

    for i, row in pairs(board) do
        for j in pairs(row) do
            for label, player in pairs(players) do
                local move = fn(label..i..j, player.role)
                player.turn.tx(1, move)
                board[i][j].tx(1, move)
                move.tx(1, players[player.next].turn)
            end
        end
    end

end)