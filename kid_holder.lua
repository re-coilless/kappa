local entity_id = GetUpdatedEntityID()
local parent = EntityGetParent( entity_id )
local x, y, r = EntityGetTransform( entity_id )
local _, _, _, s_x, s_y = EntityGetTransform( parent )

local d_x, d_y = 0, 0
if( EntityGetFirstComponent( parent, "VelocityComponent" ) ~= nil ) then
    d_x, d_y = GameGetVelocityCompVelocity( parent )
end
EntitySetTransform( entity_id, x + d_x, y + d_y, r, s_x, s_y )