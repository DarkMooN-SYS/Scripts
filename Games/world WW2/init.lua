local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfigWW2.PlaceId then
        return false
    end
    return GameFeaturesWW2.Configure(menu)
end

return Game
