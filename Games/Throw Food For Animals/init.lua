local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfigFood.PlaceId then
        return false
    end
    return GameFeaturesFood.Configure(menu)
end

return Game
