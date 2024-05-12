dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once( "mods/mnee/lib.lua" )

local entity_id = GetUpdatedEntityID()
local x, y, r, s_x, s_y = EntityGetTransform( entity_id )

input_memo = input_memo or {}
input_memo[ entity_id ] = input_memo[ entity_id ] or false
kick_tbl = kick_tbl or {}
kick_tbl[entity_id] = kick_tbl[entity_id] or { 0, 0, 0, 0, 0 }

local frame_num = GameGetFrameNum()
local timer = ComponentGetValue2( GetUpdatedComponentID(), "mTimesExecuted" )

local storage_ranged = pen.get_storage( entity_id, "kappa_ranged_cooldown" )
local ranged_cooldown = ComponentGetValue2( storage_ranged, "value_int" )
local storage_melee = pen.get_storage( entity_id, "kappa_melee_cooldown" )
local melee_cooldown = ComponentGetValue2( storage_melee, "value_int" )
local storage_dash = pen.get_storage( entity_id, "kappa_dash_cooldown" )
local dash_cooldown = ComponentGetValue2( storage_dash, "value_int" )
local storage_gun = pen.get_storage( entity_id, "kappa_current_gun" )
local current_gun = ComponentGetValue2( storage_gun, "value_int" )

local ai_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "AnimalAIComponent" )
if( ComponentGetIsEnabled( ai_comp )) then
	EntitySetComponentIsEnabled( entity_id, ai_comp, false )
end

local hands_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "ItemPickUpperComponent" )
local char_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterDataComponent" )
local plat_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "CharacterPlatformingComponent" )
local dmg_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
local hitbox_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "HitboxComponent" )
local attack_comps = EntityGetComponentIncludingDisabled( entity_id, "AIAttackComponent" ) or {}
local attack_comp = attack_comps[current_gun]

local kappa_id = 0
local storage_kappa = pen.get_storage( entity_id, "kappa" ) or 0
if( storage_kappa > 0 ) then kappa_id = ComponentGetValue2( storage_kappa, "value_int" ) end
local mod_id = "kappa"..( kappa_id > 1 and ":p"..( kappa_id + 1 ) or "" )

local ctrl_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "ControlsComponent" )
ComponentSetValue2( ctrl_comp, "mButtonDownRun", true )
local axis_state = mnee.mnin( "stick", {mod_id,"movement"}, {dirty=true})
local move_left, move_right = axis_state[1] < 0, axis_state[1] > 0
ComponentSetValue2( ctrl_comp, "mButtonDownLeft", move_left )
ComponentSetValue2( ctrl_comp, "mButtonDownRight", move_right )
local move_down, move_up = axis_state[2] > 0, axis_state[2] < 0
ComponentSetValue2( ctrl_comp, "mButtonDownDown", move_down )
if( move_left or move_right ) then GamePlayAnimation( entity_id, "stand", 0.1 ) end

local inv_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "Inventory2Component" )
local wand_in_hand = -1
if( inv_comp ~= nil ) then
	wand_in_hand = tonumber( ComponentGetValue2( inv_comp, "mActiveItem" ) or -1 )
end

local is_coop = ModSettingGet( "kappa.GLOBAL_MODE" ) ~= 1
if( is_coop ) then
	local hooman = EntityGetClosestWithTag( x, y, "player_unit" ) or 0
	if( hooman > 0 ) then
		local player_x, player_y = EntityGetTransform( hooman )
		if( mnee.mnin( "bind", {"kappa","rally"}, {pressed=true,dirty=true})) then
			EntityLoad( "data/entities/particles/teleportation_source.xml", x, y )
			EntityLoad( "data/entities/particles/teleportation_target.xml", player_x, player_y )
			EntitySetTransform( entity_id, player_x, player_y )
		end

		if( kappa == 0 ) then
			local d_x, d_y = player_x - x, player_y - y
			local dist = math.sqrt( d_x^2 + d_y^2 )
			if( dist < tonumber( MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ))) then
				local shooter_comp = EntityGetFirstComponentIncludingDisabled( hooman, "PlatformShooterPlayerComponent" )
				if( shooter_comp ~= nil ) then
					local cam_pos = { ComponentGetValue2( shooter_comp, "mSmoothedCameraPosition" )}
					local wanna_pos = { player_x - d_x/2, player_y - d_y/2 }
					local smoothing = 15
					ComponentSetValue2( shooter_comp, "mSmoothedCameraPosition", cam_pos[1] + ( wanna_pos[1] - cam_pos[1] )/smoothing, cam_pos[2] + ( wanna_pos[2] - cam_pos[2] )/smoothing )
				end
			end
		else
			local core_x, core_y = pen.get_creature_centre( entity_id, x, y )
			local money = EntityGetInRadiusWithTag( core_x, core_y, 10, "gold_nugget" ) or {}
			for i,gold in ipairs( money ) do
				EntitySetTransform( gold, player_x, player_y )
				EntityApplyTransform( gold, player_x, player_y )
			end
		end
	end
end



local a_dist = 100
local a_speed = math.rad( ModSettingGetNextValue( "kappa.AIM_SPEED" ))
local a_limit = math.rad( 85 )

local aim,_,is_buttoned = mnee.mnin( "stick", {mod_id,"aim"}, {dirty=true})
local controller_moment = not( is_buttoned[1] and is_buttoned[2])
if( plat_comp ~= nil ) then
	if( aim[2] ~= 0 or move_left or move_right or controller_moment ) then
		ComponentSetValue2( plat_comp, "keyboard_look", not( input_memo[ entity_id ]))
		ComponentSetValue2( plat_comp, "mouse_look", input_memo[ entity_id ])
	end
end

local show_aim = ModSettingGetNextValue( "kappa.SHOW_AIM" )
local aim_data = {
	tag_tbl = not( is_coop ) and {"player_unit"} or nil,
	pic = not( show_aim ) and "" or nil,
}
local has_weapon = wand_in_hand > 0 or ComponentGetValue2( ai_comp, "attack_ranged_enabled" ) or attack_comp ~= nil
local autoaim = has_weapon and ModSettingGetNextValue( "kappa.AUTOAIM" ) and not( mnee.mnin( "bind", {mod_id,"halt_autoaim"}, {dirty=true}))
local storage_angle = pen.get_storage( entity_id, "kappa_angle" )
local angle = ComponentGetValue2( storage_angle, "value_float" )
if( aim[2] ~= 0 or controller_moment ) then
	if( controller_moment ) then
		angle = mnee.aim_assist( entity_id, {pen.get_creature_centre( entity_id, x, y )}, math.atan2( aim[2], aim[1]), autoaim, aim_data )
	else
		angle = math.max( math.min( angle - ( aim[2] < 0 and 1 or -1 )*a_speed, a_limit ), -a_limit )
	end
	input_memo[ entity_id ] = controller_moment 
	ComponentSetValue2( storage_angle, "value_float", angle )
	
	if( attack_comp ~= nil and ComponentGetValue2( attack_comp, "attack_ranged_aim_rotation_enabled" )) then
		GameEntityPlaySoundLoop( entity_id, "turret_rotate_sound", 1.0 )
	end
end
local aim_sign = input_memo[ entity_id ] and 1 or s_x
local a_vector = { aim_sign*math.cos( angle )*a_dist, s_y*math.sin( angle )*a_dist }
angle = math.atan2( a_vector[2], a_vector[1])
if( not( controller_moment ) and autoaim ) then
	angle = mnee.aim_assist( entity_id, {pen.get_creature_centre( entity_id, x, y )}, angle, aim_data )
	a_vector = { math.cos( angle )*a_dist, s_y*math.sin( angle )*a_dist }
end
ComponentSetValue2( ctrl_comp, "mAimingVector", a_vector[1], a_vector[2] )
ComponentSetValue2( ctrl_comp, "mMousePosition", a_vector[1]*1000, a_vector[2]*1000 )

local next_gun = mnee.mnin( "bind", {mod_id,"next_gun"}, {pressed=true,dirty=true})
local previous_gun = mnee.mnin( "bind", {mod_id,"previous_gun"}, {pressed=true,dirty=true})
if( next_gun or previous_gun ) then
	current_gun = current_gun + ( next_gun and 1 or -1 )
	if( current_gun < 1 ) then
		current_gun = #attack_comps
	elseif( current_gun > #attack_comps ) then
		current_gun = 1
	end
	ComponentSetValue2( storage_gun, "value_int", math.max( current_gun, 1 ))
	
	GamePlaySound( "mods/kappa/files/sfx/kappa.bank", "gun_switch", x, y )
end

local gonna_shoot = mnee.mnin( "bind", {mod_id,"shoot"}, {dirty=true})
local gonna_melee = mnee.mnin( "bind", {mod_id,"melee"}, {dirty=true})

local gun_dude = entity_id
local bangle = angle + math.rad( 90 - 90*s_x )
if( attack_comp ~= nil ) then
	local kids = EntityGetAllChildren( entity_id ) or {}
	if( #kids > 0 ) then
		for i,kid in ipairs( kids ) do
			if( EntityGetName( kid ) == "gun_kid" ) then
				gun_dude = kid
				break
			end
		end
		if( gun_dude ~= entity_id ) then
			local trans_comp = EntityGetFirstComponentIncludingDisabled( gun_dude, "InheritTransformComponent" )
			local origs = { ComponentGetValue2( trans_comp, "Transform" ) }
			ComponentSetValue2( trans_comp, "Transform", origs[1], origs[2], origs[3], origs[4], bangle )
			
			if( not( gonna_shoot )) then
				EntityRefreshSprite( gun_dude, EntityGetFirstComponentIncludingDisabled( gun_dude, "SpriteComponent", "kids_gun" ))
				GamePlayAnimation( gun_dude, "stand", 0.1 )
			end
		end
	end
end

if( wand_in_hand > 0 ) then
	ComponentSetValue2( ctrl_comp, "mButtonDownFire", gonna_shoot )
	ComponentSetValue2( EntityGetFirstComponentIncludingDisabled( entity_id, "PlatformShooterPlayerComponent" ), "mForceFireOnNextUpdate", gonna_shoot )
elseif( ComponentGetValue2( ai_comp, "attack_ranged_enabled" ) or attack_comp ~= nil ) then
	if( ranged_cooldown < frame_num and gonna_shoot ) then
		local barrel_x, barrel_y, amount, cooldown, path, anim = 0, 0, 1, 0, "", "attack_ranged"
		if( attack_comp ~= nil ) then
			local off_x, off_y = ComponentGetValue2( attack_comp, "attack_ranged_offset_x" ), ComponentGetValue2( attack_comp, "attack_ranged_offset_y" )
			barrel_x, barrel_y = off_x*math.cos( s_x*bangle ), off_x*math.sin( s_x*bangle )
			barrel_x, barrel_y = barrel_x + off_y*math.cos( bangle + math.rad( 90 )), barrel_y + off_y*math.sin( bangle + math.rad( 90 ))
			barrel_x, barrel_y = barrel_x + ComponentGetValue2( attack_comp, "attack_ranged_root_offset_x" ), barrel_y + ComponentGetValue2( attack_comp, "attack_ranged_root_offset_y" )
			
			amount = math.random( ComponentGetValue2( attack_comp, "attack_ranged_entity_count_min" ), ComponentGetValue2( attack_comp, "attack_ranged_entity_count_max" ))
			
			cooldown = ( 2*ComponentGetValue2( attack_comp, "frames_between_global" ) + ComponentGetValue2( attack_comp, "frames_between" ))/3
			path = ComponentGetValue2( attack_comp, "attack_ranged_entity_file" )
			anim = ComponentGetValue2( attack_comp, "animation_name" )
		else
			barrel_x, barrel_y = ComponentGetValue2( ai_comp, "attack_ranged_offset_x" ), ComponentGetValue2( ai_comp, "attack_ranged_offset_y" )
			amount = math.random( ComponentGetValue2( ai_comp, "attack_ranged_entity_count_min" ), ComponentGetValue2( ai_comp, "attack_ranged_entity_count_max" ))
			cooldown = ComponentGetValue2( ai_comp, "attack_ranged_frames_between" )
			path = ComponentGetValue2( ai_comp, "attack_ranged_entity_file" )
		end
		
		barrel_x, barrel_y = x + s_x*barrel_x, y + s_y*barrel_y
		for i = 1,amount do
			local proj_id = shoot_projectile( entity_id, path, barrel_x, barrel_y, 0, 0 )
			edit_component( proj_id, "ProjectileComponent", function(comp,vars)
				if( not( ComponentGetValue2( ai_comp, "tries_to_ranged_attack_friends" ))) then
					ComponentSetValue2( comp, "never_hit_player", is_coop or ComponentGetValue2( comp, "never_hit_player" ))
				end
				
				local shoot_speed = math.random( ComponentGetValue2( comp, "speed_min" ), ComponentGetValue2( comp, "speed_max" ))
				local v_x, v_y = shoot_speed*a_vector[1]/100, shoot_speed*a_vector[2]/100
				
				local shape_comp = EntityGetFirstComponentIncludingDisabled( proj_id, "PhysicsImageShapeComponent" )
				if( shape_comp ~= nil ) then
					local proj_x, proj_y = EntityGetTransform( proj_id )
					local drift_x, drift_y = ComponentGetValue2( shape_comp, "offset_x" ), ComponentGetValue2( shape_comp, "offset_y" )
					proj_x, proj_y = proj_x - drift_x, proj_y - drift_y
					drift_x, drift_y = 1.5*drift_x, 1.5*drift_y
					
					local function get_phys_mass( entity_id )
						local mass = 0
						local function calculate_force_for_body( entity, body_mass, body_x, body_y, body_vel_x, body_vel_y, body_vel_angular )
							if( math.abs( proj_x - body_x ) < 0.001 and math.abs( proj_y - body_y ) < 0.001 ) then
								mass = body_mass
							end
							return body_x, body_y, 0, 0, 0
						end
						PhysicsApplyForceOnArea( calculate_force_for_body, nil, proj_x - drift_x, proj_y - drift_y, proj_x + drift_x, proj_y + drift_y )
						
						return mass
					end
					local gravity = 60
					local weight = gravity*get_phys_mass( proj_id )
					v_x, v_y = GameVecToPhysicsVec( weight*v_x, weight*v_y )
					PhysicsApplyForce( proj_id, 2*v_x, 2*v_y )
				elseif( EntityGetFirstComponentIncludingDisabled( proj_id, "VerletWeaponComponent" ) ~= nil ) then
					EntityKill( proj_id )
					shoot_projectile( entity_id, path, barrel_x, barrel_y, v_x, v_y )
				else
					edit_component( proj_id, "VelocityComponent", function(comp,vars)
						ComponentSetValueVector2( comp, "mVelocity", v_x, v_y )
					end)
				end
			end)
		end
		
		local kid_pic = EntityGetFirstComponentIncludingDisabled( gun_dude, "SpriteComponent", "kids_gun" )
		if( kid_pic ~= nil ) then
			EntityRefreshSprite( gun_dude, kid_pic )
		end
		
		GamePlayAnimation( gun_dude, anim, 1 )
		ComponentSetValue2( storage_ranged, "value_int", frame_num + cooldown )
	end
else
	gonna_melee = gonna_melee or gonna_shoot
end
if( ComponentGetValue2( ai_comp, "attack_melee_enabled" )) then
	ComponentSetValue2( ctrl_comp, "mButtonDownKick", gonna_melee )
	if( melee_cooldown < frame_num and gonna_melee ) then
		local barrel_x, barrel_y = s_x*ComponentGetValue2( ai_comp, "attack_melee_offset_x" ), s_y*ComponentGetValue2( ai_comp, "attack_melee_offset_y" )
		local force = ComponentGetValue2( ai_comp, "attack_melee_impulse_multiplier" )
		local force_x, force_y = force*s_x*ComponentGetValue2( ai_comp, "attack_melee_impulse_vector_x" ), -force*s_y*ComponentGetValue2( ai_comp, "attack_melee_impulse_vector_y" )
		local dmg = { ComponentGetValue2( ai_comp, "attack_melee_damage_min" ), ComponentGetValue2( ai_comp, "attack_melee_damage_max" ), }
		local radius = ComponentGetValue2( ai_comp, "attack_melee_max_distance" )
		local fuck_player = true
		
		if( ComponentGetValue2( ai_comp, "attack_dash_enabled" )) then
			local extra_damage = ComponentGetValue2( ai_comp, "attack_dash_damage" )
			dmg = { dmg[1] + extra_damage, dmg[2] + extra_damage, }
		end
		
		local meats = EntityGetInRadius( x + barrel_x, y + barrel_y, radius ) or {}
		if( #meats > 0 ) then
			for i,meat in ipairs( meats ) do
				if( meat ~= entity_id and EntityGetRootEntity( meat ) == meat ) then
					if( EntityGetFirstComponentIncludingDisabled( meat, "DamageModelComponent" ) ~= nil ) then
						local gene_comp = EntityGetFirstComponentIncludingDisabled( meat, "GenomeDataComponent" )
						if( gene_comp ~= nil and not( is_coop and ComponentGetValue2( gene_comp, "herd_id" ) == StringToHerdId( "player" ))) then
							local m_x, m_y = EntityGetTransform( meat )
							EntityInflictDamage( meat, math.random( dmg[1], dmg[2] ), "DAMAGE_MELEE", "Gotcha", "BLOOD_SPRAY", force_x, force_y, entity_id, m_x, m_y, force )
						end
					end
				end
			end
		end
		
		local kick_comp = EntityGetFirstComponentIncludingDisabled( entity_id, "KickComponent" )
		if(( kick_tbl[entity_id][1] + 5 ) < frame_num and kick_comp ~= nil and ComponentGetValue2( kick_comp, "can_kick" )) then
			local kick_x, kick_y = x, y
			local kick_spot = EntityGetFirstComponentIncludingDisabled( entity_id, "HotspotComponent", "kick_pos" )
			if( kick_spot ~= nil ) then
				local dx, dy = ComponentGetValue2( kick_spot, "offset" )
				kick_x, kick_y = kick_x + s_x*dx, kick_y + dy
			end
			local radius, force = ComponentGetValue2( kick_comp, "kick_radius" ), ComponentGetValue2( kick_comp, "player_kickforce" )
			kick_tbl[entity_id] = { frame_num + 20, kick_x, kick_y, radius, force }
		end

		GamePlayAnimation( entity_id, "attack", 2 )
		ComponentSetValue2( storage_melee, "value_int", frame_num + ComponentGetValue2( ai_comp, "attack_melee_frames_between" ))
	end
end

if( kick_tbl[entity_id][1] > 0 and kick_tbl[entity_id][1] < frame_num ) then
	local kick_x, kick_y = kick_tbl[entity_id][2], kick_tbl[entity_id][3]
	local radius = kick_tbl[entity_id][4]
	PhysicsApplyForceOnArea( function( body_id, mass, pos_x, pos_y, vel_x, vel_y, vel_angular )
		local k = 15
		local force_x = k*mass*kick_tbl[entity_id][5]*math.cos( angle )
		local force_y = k*mass*kick_tbl[entity_id][5]*math.sin( angle )
		return pos_x, pos_y, force_x, force_y, 0
	end, 0, kick_x - radius, kick_y - radius, kick_x + radius, kick_y + radius )
	kick_tbl[entity_id][1] = 0
end

if( move_up ) then ComponentSetValue2( plat_comp, "mSmoothedFlyingTargetY", -999999 ) end
if( ComponentGetValue2( ai_comp, "can_fly" )) then
	ComponentSetValue2( ctrl_comp, "mButtonDownFly", move_up )
	GamePlayAnimation( entity_id, "fly_"..(( move_left or move_right ) and "move" or "idle" ), 0.5 )
elseif( dash_cooldown < frame_num and not( ComponentGetValue2( dmg_comp, "mAirAreWeInWater" )) and ComponentGetValue2( char_comp, "is_on_ground" ) and move_up ) then
	local cooldown = 0
	local j_x, j_y = 0, 0
	if( ComponentGetValue2( ai_comp, "attack_dash_enabled" )) then
		local speed = math.max( ComponentGetValue2( ai_comp, "attack_dash_speed" ), 200 )
		j_x, j_y = speed*math.cos( angle - math.rad( 10 )), speed*s_y*math.sin( angle - math.rad( 10 ))
		cooldown = ComponentGetValue2( ai_comp, "attack_dash_frames_between" )/2
	else
		j_x, j_y = ComponentGetValue2( plat_comp, "jump_velocity_x" ), math.min( ComponentGetValue2( plat_comp, "jump_velocity_y" ), -200 )
		cooldown = 20
	end
	local v_x, v_y = ComponentGetValue2( char_comp, "mVelocity" )
	ComponentSetValueVector2( char_comp, "mVelocity", v_x + j_x, v_y + j_y )
	GamePlayAnimation( entity_id, "jump_up", 1 )
	ComponentSetValue2( storage_dash, "value_int", frame_num + cooldown )
end

if( kappa_id == 0 and timer < 10 ) then
	if( ModSettingGetNextValue( "kappa.KAPPA_CONCRETE_HANDS" ) and wand_in_hand > 0 ) then
		local item_comp = EntityGetFirstComponentIncludingDisabled( wand_in_hand, "ItemComponent" )
		if( item_comp ~= nil and not( ComponentGetValue2( item_comp, "has_been_picked_by_player" ))) then
			local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_in_hand, "AbilityComponent" )
			if( abil_comp ~= nil ) then
				ComponentSetValue2( abil_comp, "drop_as_item_on_death", false )
				
				EntityAddComponent( wand_in_hand, "LuaComponent", 
				{
					_tags = "enabled_in_world",
					script_source_file = "mods/kappa/files/wand_nuker.lua",
					execute_every_n_frame = "1",
				})
			end
		end
	end
elseif( timer > 10 ) then
	if( hands_comp ~= nil and ComponentGetIsEnabled( hands_comp )) then
		EntitySetComponentIsEnabled( entity_id, hands_comp, false )
	end
end
if( mnee.mnin( "bind", {mod_id,"drop"}, {pressed=true,dirty=true})) then
	GameDropAllItems( entity_id )
	if( hands_comp ~= nil ) then
		EntitySetComponentIsEnabled( entity_id, hands_comp, true )
	end
end

if( kappa_id == 0 ) then
	if( ModSettingGetNextValue( "kappa.SOLID_SCREEN" )) then
		local ratio = 0.03
		local pos_x, pos_y, width, height = GameGetCameraBounds()
		local delta_x, delta_y = width*ratio, height*ratio
		pos_x, pos_y, width, height = pos_x + delta_x, pos_y + delta_y, width - 2*delta_x, height - 2*delta_y
		local new_x = math.min( math.max( x, pos_x ), pos_x + width )
		local new_y = math.min( math.max( y, pos_y ), pos_y + height )
		if( new_x ~= x or new_y ~= y ) then
			EntitySetTransform( entity_id, new_x, new_y )
		end
	end
	if( ModSettingGetNextValue( "kappa.NO_SUICIDES" )) then
		local duds = EntityGetInRadiusWithTag( x, y, 2*MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ), "player_unit" ) or {}
		if( #duds == 0 ) then
			EntityKill( entity_id )
			return
		end
	else
		if( mnee.mnin( "bind", {mod_id,"suicide"}, {pressed=true,dirty=true})) then
			if( is_coop and hands_comp ~= nil ) then ComponentSetValue2( hands_comp, "drop_items_on_death", false ) end
			EntityRemoveComponent( entity_id, EntityGetFirstComponentIncludingDisabled( entity_id, "PlatformShooterPlayerComponent" ))
			
			EntityInflictDamage( entity_id, 9999999, "DAMAGE_SLICE", "GET KAPPAED LOL", "BLOOD_EXPLOSION", 0, 0, entity_id, x, y, 0 )
			if( EntityHasTag( entity_id, "godlike" )) then
				EntityLoad( "data/entities/projectiles/deck/black_hole_giga.xml", x, y )
				EntityLoad( "data/entities/projectiles/deck/nuke_giga.xml", x, y )
				EntityLoad( "data/entities/projectiles/bomb_holy_giga.xml", x, y )
			end
		end
	end
end

if( EntityHasTag( entity_id, "godlike" )) then
	GameEntityPlaySoundLoop( entity_id, "godlike", 1.0 )
end



local uid, pic_x, pic_y, pic_z = 0, 0, 0, -99999

local gui = GuiCreate()
GuiStartFrame( gui )
local w, h = GuiGetScreenDimensions( gui )

if( ModSettingGetNextValue( "kappa.SHOW_POINTER" )) then
	pic_x, pic_y = pen.world2gui( gui, x, y + ComponentGetValue2( hitbox_comp, "aabb_min_y" ) - 10 )
	local scale_x, scale_y = 1, 1
	local pic = "mods/kappa/files/pics/pointer/"..math.max( kappa_id, 1 ).."pointer"
	if( pic_x >= w and pic_y >= h ) then
		pic = pic.."_ne"
		scale_y = -1
		pic_x, pic_y = w - 2.5, h + 1.5
	elseif( pic_x <= 0 and pic_y >= h ) then
		pic = pic.."_ne"
		scale_x, scale_y = -1, -1
		pic_x, pic_y = 5.5, h + 1.5
	elseif( pic_x <= 0 and pic_y <= 0 ) then
		pic = pic.."_ne"
		scale_x = -1
		pic_x, pic_y = 5.5, 2
	elseif( pic_x >= w and pic_y <= 0 ) then
		pic = pic.."_ne"
		pic_x, pic_y = w - 2.5, 1.5
	elseif( pic_x < 0 and pic_y > 0 ) then
		pic = pic.."_e"
		scale_x = -1
		pic_x = 4.5
	elseif( pic_x > 0 and pic_y < 0 ) then
		pic = pic.."_n"
		pic_y = 1.5
	elseif( pic_x > w and pic_y < h ) then
		pic = pic.."_e"
		pic_x = w - 1.5
	elseif( pic_x > 0 and pic_y > h ) then
		pic = pic.."_n"
		scale_y = -1
		pic_y = h + 1.5
	else
		pic = pic.."_n"
		scale_y = -1
		pic_y = pic_y + 1.5
	end
	uid = pen.new_image( gui, uid, pic_x - 1.5, pic_y - 1.5, pic_z, pic..".png", scale_x, scale_y )
end

if( show_aim ) then
	local drift = math.abs( s_x > 0 and ComponentGetValue2( hitbox_comp, "aabb_max_x" ) or ComponentGetValue2( hitbox_comp, "aabb_min_x" )) + 20
	pic_x, pic_y = pen.world2gui( gui, x + drift*math.cos( angle ), y + drift*s_y*math.sin( angle ))
	uid = pen.new_image( gui, uid, pic_x - 1.5, pic_y - 1.5, pic_z - 1, "mods/kappa/files/pics/pointer/"..math.max( kappa_id, 1 ).."pointer.png" )
end

if( ModSettingGetNextValue( "kappa.SHOW_UI" )) then
	local is_pinned = ModSettingGetNextValue( "kappa.PIN_UI" )
	local length = math.max( math.abs( ComponentGetValue2( hitbox_comp, "aabb_max_x" ) - ComponentGetValue2( hitbox_comp, "aabb_min_x" )), is_pinned and 30 or 10 )
	local percentage = math.min( math.max( ComponentGetValue2( dmg_comp, "hp" )/ComponentGetValue2( dmg_comp, "max_hp" ), 0 ), 1 )
	
	if( is_pinned ) then
		pic_y = h - 10
		if( kappa_id == 0 ) then
			pic_x = w/2
		else
			pic_x = ( w/2 - 90 ) + ( kappa_id - 1 )*60
		end
	else
		pic_x, pic_y = pen.world2gui( gui, x, y + ComponentGetValue2( hitbox_comp, "aabb_max_y" ) + 5 )
	end
	
	local bar_height = is_pinned and 1.5 or 2
	uid = pen.new_image( gui, uid, pic_x - length/2, pic_y, pic_z - 0.5, "mods/kappa/files/pics/pixels_white.png", length, bar_height )
	uid = pen.new_image( gui, uid, pic_x - length/2 + 1, pic_y + bar_height/2, pic_z - 0.6, "mods/kappa/files/pics/pixels_p"..math.max( kappa_id, 1 )..".png", ( length - 2 )*percentage, bar_height/2 )
	
	if( #attack_comps > 1 ) then
		local t_x, t_y = pic_x - ( #attack_comps*2 - 1 )/2, pic_y + 3*bar_height + 1
		for i = 1,#attack_comps do
			local this_one = current_gun == i
			uid = pen.new_image( gui, uid, t_x + 2*( i - 1 ), t_y, pic_z - 0.5, "mods/kappa/pixels_"..( this_one and "white" or "blue" )..".png", 1, this_one and 4/3 or 1 )
		end
	end
	
	if( ComponentGetValue2( char_comp, "flying_needs_recharge" )) then
		local perc = ComponentGetValue2( char_comp, "mFlyingTimeLeft" )/ComponentGetValue2( char_comp, "fly_time_max" )
		if( perc < 0.99 ) then
			uid = pen.new_image( gui, uid, pic_x - ( length/2 + 3 ), pic_y + 3*bar_height, pic_z - 0.45, "mods/kappa/files/pics/pixels_blue.png", length + 6, -bar_height*perc )
		end
	end

	if( wand_in_hand > 0 ) then
		local abil_comp = EntityGetFirstComponentIncludingDisabled( wand_in_hand, "AbilityComponent" )
		local mana, mana_max = ComponentGetValue2( abil_comp, "mana" ), ComponentGetValue2( abil_comp, "mana_max" )
		local mana_perc = ( 1 - mana/mana_max )^2
		local mana_frames = 60*math.max( mana_max - mana, 0 )/ComponentGetValue2( abil_comp, "mana_charge_speed" )
        local delay_frames = math.max( ComponentGetValue2( abil_comp, "mNextFrameUsable" ) - frame_num, 0 )
		local reload_frames = math.max( ComponentGetValue2( abil_comp, "mReloadNextFrameUsable" ) - frame_num, 0 )
		local full_frame = math.min(( is_pinned and 3 or 1 )*math.ceil( mana_perc*mana_frames + delay_frames + reload_frames )/10, length - 4 )
		if( full_frame > 1 ) then
			uid = pen.new_image( gui, uid, pic_x - full_frame/2, pic_y - ( is_pinned and 2 or 0 ), pic_z - 0.55, "mods/kappa/files/pics/pixels_blue.png", full_frame, is_pinned and 1.5 or 2 )
		end
	end
end

GuiDestroy( gui )