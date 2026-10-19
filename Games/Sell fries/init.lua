local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfig139.PlaceId then
        return false
    end
    return GameFeatures139.Configure(menu)
end

return Game
