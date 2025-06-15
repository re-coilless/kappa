local entity_id = GetUpdatedEntityID()
local parent = EntityGetParent( entity_id )

local d_x, d_y = 0, 0
if( EntityGetFirstComponent( parent, "VelocityComponent" ) ~= nil ) then
    d_x, d_y = GameGetVelocityCompVelocity( parent )
end

local x, y, r = EntityGetTransform( entity_id )
local _, _, _, s_x, s_y = EntityGetTransform( parent )
EntitySetTransform( entity_id, x + d_x, y + d_y, r, s_x, s_y )