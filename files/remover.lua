dofile_once( "mods/mnee/lib.lua" )

local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform( entity_id )

local kappa_id = pen.magic_storage( entity_id, "kappa", "value_int" ) or ""

local core_tag = "kappaed"..kappa_id
local core_flag = "KAPPA_IS_ACTIVE"..kappa_id

local polied = EntityGetClosestWithTag( x, y, "polymorphed" ) or 0
if( polied > 0 ) then
	local poly_x, poly_y = EntityGetTransform( polied )
	local delta = math.sqrt(( x - poly_x )^2 + ( y - poly_y )^2 )
	if( delta < 0.00001 and not( EntityHasTag( polied, "kappaed" ))) then
		GamePrint( "[TARGET KORRUPTED]" )
		EntityAddTag( polied, "kappaed" )
		EntityAddTag( polied, core_tag )
		pen.magic_comp( polied, "GenomeDataComponent", function( comp_id, v, is_enabled )
			v.herd_id = ComponentGetValue2(
				EntityGetFirstComponentIncludingDisabled( entity_id, "GenomeDataComponent" ), "herd_id" )
		end)
	end
else
	if( kappa_id == "" and ModSettingGetNextValue( "kappa.MANUAL_SELECTION" )) then
		local kid = EntityLoad( "mods/kappa/files/base_kid.xml", x, y )
		EntityAddTag( kid, "kappaed" )
		EntityAddTag( kid, "kappa_ghost" )
		EntityAddComponent( kid, "LuaComponent", 
		{
			script_source_file = "mods/kappa/files/ghost_controller.lua",
			execute_every_n_frame = "1",
		})
		
		local pic_comp = EntityGetFirstComponentIncludingDisabled( kid, "SpriteComponent" )				
		ComponentSetValue2( pic_comp, "image_file", "mods/kappa/files/pics/ghost.png" )
		ComponentSetValue2( pic_comp, "z_index", -9999999 )
		ComponentSetValue2( pic_comp, "offset_x", 0 )
		ComponentSetValue2( pic_comp, "offset_y", 10 )
		ComponentSetValue2( pic_comp, "emissive", true )
		EntityRefreshSprite( kid, pic_comp )
		
		local root_id = EntityCreateNew( "ghost_anchor" )
		EntityAddComponent( root_id, "LuaComponent", 
		{
			script_source_file = "mods/kappa/files/ghost_holder.lua",
			execute_every_n_frame = "1",
		})
		EntityAddChild( root_id, kid )
	else GameRemoveFlagRun( core_flag ) end
	
	GamePrint( "[TARGET KRUSHED]" )
	if( EntityGetIsAlive( entity_id )) then EntityKill( entity_id ) end
end