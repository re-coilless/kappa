dofile_once( "mods/mnee/lib.lua" )

local speed = 5
local trans_comp = EntityGetFirstComponentIncludingDisabled( GetUpdatedEntityID(), "InheritTransformComponent" )
local origs = { ComponentGetValue2( trans_comp, "Transform" )}
origs[1] = origs[1] + mnee.mnin( "axis", { "kappa", "movement_h" })*speed
origs[2] = origs[2] + mnee.mnin( "axis", { "kappa", "movement_v" })*speed

local limit_x, limit_y = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" )/2, MagicNumbersGetValue( "VIRTUAL_RESOLUTION_Y" )/2
ComponentSetValue2( trans_comp, "Transform",
    math.min( math.abs( origs[1] ), limit_x )*pen.get_sign( origs[1] ),
    math.min( math.abs( origs[2] ), limit_y )*pen.get_sign( origs[2] ),
1, 1, 0 )

local is_done = mnee.mnin( "bind", { "kappa", "melee" }, { pressed = true })
    or mnee.mnin( "bind", { "kappa", "suicide" }, { pressed = true })
    or mnee.mnin( "bind", { "kappa", "spawn" }, { pressed = true })
if( is_done ) then GameRemoveFlagRun( "KAPPA_IS_ACTIVE" ) end