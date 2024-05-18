ModRegisterAudioEventMappings( "mods/kappa/files/sfx/GUIDs.txt" )

if( ModIsEnabled( "mnee" )) then
	ModLuaFileAppend( "mods/mnee/bindings.lua", "mods/kappa/mnee.lua" )
end

function OnModInit()
	local path = "data/scripts/items/heart_fullhp_temple.lua"
	local marker = "%-%- remove the item from the game"
	local injection = "for i = 1,4 do GameRemoveFlagRun(\"KAPPA_SPAWN_BAN\"..i) end -- remove the item from the game"
	ModTextFileSetContent( path, string.gsub( ModTextFileGetContent( path ), marker, injection ))
end

function OnWorldPreUpdate()
	if( not( ModIsEnabled( "mnee" ))) then
		GamePrint( "[M-NEE IS REQUIRED] - check steam page description" )
		return
	end
	
	local players = EntityGetWithTag( "player_unit" ) or {}
	if( #players == 0 ) then return end
	
	dofile_once( "mods/mnee/lib.lua" )
	dofile_once( "data/scripts/lib/utilities.lua" )
	dofile_once( "mods/kappa/incompatibility.lua" )
	
	local mode = ModSettingGet( "kappa.GLOBAL_MODE" )
	if( mode == 3 ) then
		local flags = { "KAPPA_IS_ACTIVE", "KAPPA_SPAWN_BAN" }
		local player_x, player_y = EntityGetTransform( players[1])
		local real_count, x_count, y_count = 0, 0, 0
		for i = 1,4 do
			local core_tag = "kappaed"..i
			local core_flag, spawn_ban = flags[1]..i, flags[2]..i
			local mod_id = "kappa"..( i > 1 and ":p"..( i + 1 ) or "" )
			local wanna_spawn = mnee.mnin( "bind", {mod_id,"spawn"}, {pressed=true,dirty=true})
			
			local dude = EntityGetClosestWithTag( player_x, player_y, core_tag ) or 0
			local is_real = dude > 0
			if( is_real ) then
				local x, y = EntityGetTransform( dude )
				real_count = real_count + 1
				x_count = x_count + x
				y_count = y_count + y
			end

			local is_alive = GameHasFlagRun( core_flag )
			if( GameHasFlagRun( spawn_ban )) then
				if( wanna_spawn and not( is_alive )) then
					mnee.play_sound( "error" )
					GamePrint( "PICK UP TEMPLE HEART TO RESPAWN" )
				end
			elseif( not( is_alive )) then
				if( wanna_spawn ) then
					local target_entity = EntityLoad( "mods/kappa/files/kappa.xml", player_x, player_y )
					EntityLoad( "data/entities/particles/teleportation_target.xml", player_x, player_y )
					
					EntityRemoveTag( target_entity, "teleportable_NOT" )
					EntityRemoveTag( target_entity, "enemy" )
					EntityRemoveTag( target_entity, "homing_target" )
					EntityRemoveTag( target_entity, "destruction_target" )
					EntitySetComponentIsEnabled( target_entity, EntityGetFirstComponentIncludingDisabled( target_entity, "AnimalAIComponent" ), false )
					local lua_comps = EntityGetComponentIncludingDisabled( target_entity, "LuaComponent" ) or {}
					if( #lua_comps > 0 ) then
						for i,lua_comp in ipairs( lua_comps ) do
							if( ComponentGetValue2( lua_comp, "script_death" ) == "data/scripts/items/drop_money.lua" ) then
								EntityRemoveComponent( target_entity, lua_comp )
								break
							end
						end
					end

					local player_hp = ComponentGetValue2( EntityGetFirstComponentIncludingDisabled( players[1], "DamageModelComponent" ), "max_hp" )/2
					local dmg_comp = EntityGetFirstComponentIncludingDisabled( target_entity, "DamageModelComponent" )
					ComponentSetValue2( dmg_comp, "max_hp", player_hp )
					ComponentSetValue2( dmg_comp, "hp", player_hp )
					
					local wand_id = EntityLoad( "data/entities/items/starting_wand_rng.xml", player_x, player_y )
					GamePickUpInventoryItem( target_entity, wand_id, false )
					EntityAddComponent( wand_id, "LuaComponent", 
					{
						_tags = "enabled_in_world",
						script_source_file = "mods/kappa/files/wand_nuker.lua",
						execute_every_n_frame = "1",
					})

					ComponentSetValue2( pen.get_storage( target_entity, "kappa" ), "value_int", i )
					GameAddFlagRun( core_flag )
					GameAddFlagRun( spawn_ban )
					EntityAddTag( target_entity, core_tag )
				end
			elseif( not( is_real )) then
				GameRemoveFlagRun( core_flag )
			end
		end
		
		if( real_count > 0 ) then
			local shooter_comp = EntityGetFirstComponentIncludingDisabled( players[1], "PlatformShooterPlayerComponent" )
			if( shooter_comp ~= nil ) then
				local cam_limit = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" )
				local temp_x, temp_y = x_count/real_count, y_count/real_count
				local shift_mult = 5*( 1 - math.min( math.sqrt(( temp_x - player_x )^2 + ( temp_y - player_y )^2 )/cam_limit, 1 ))
				x_count, y_count, real_count = shift_mult*x_count + player_x, shift_mult*y_count + player_y, shift_mult*real_count

				local smoothing = 15
				local cam_pos = { ComponentGetValue2( shooter_comp, "mSmoothedCameraPosition" )}
				local wanna_pos = { x_count/( real_count + 1 ), y_count/( real_count + 1 )}
				local pos_x, pos_y = cam_pos[1] + ( wanna_pos[1] - cam_pos[1])/smoothing, cam_pos[2] + ( wanna_pos[2] - cam_pos[2])/smoothing
				ComponentSetValue2( shooter_comp, "mSmoothedCameraPosition", pos_x, pos_y )
				ComponentSetValue2( shooter_comp, "mDesiredCameraPos", pos_x, pos_y )
			end
		end

		local waiting_for_what = false
		for i = 1,4 do
			if( not( GameHasFlagRun( flags[1]..i ) or GameHasFlagRun( flags[2]..i )) and ( i == 1 or mnee.is_jpad_real( i ))) then
				waiting_for_what = i
				break
			end
		end
		if( waiting_for_what ) then
			local gui = GuiCreate()
			GuiStartFrame( gui )
			
			local txt = "Press "..mnee.get_binding_keys( "kappa"..( waiting_for_what > 1 and ":p"..( waiting_for_what + 1 ) or "" ), "spawn", true ).." to spawn a player."
			local pic_x, pic_y = pen.world2gui( player_x, player_y + 10 )
			local off_x = GuiGetTextDimensions( gui, txt, 1, 2 )
			pen.new_text( gui, pic_x - off_x/2, pic_y, 100, txt, {255,255,174})

			GuiDestroy( gui )
		end
	elseif( not( GameHasFlagRun( "KAPPA_IS_ACTIVE" ))) then
		local p_x, p_y = DEBUG_GetMouseWorld()
		
		local ghosts = EntityGetWithTag( "kappa_ghost" ) or {}
		if( #ghosts > 0 ) then
			local ghost_id = ghosts[1]
			p_x, p_y = EntityGetTransform( ghost_id )
			EntityKill( EntityGetRootEntity( ghost_id ))
		end
		
		local is_coop = mode ~= 1

		local target_entity = 0
		if( ModSettingGetNextValue( "kappa.KAPPA_SPAWN" )) then
			local player_x, player_y = EntityGetTransform( players[1] )
			target_entity = EntityLoad( ModSettingGetNextValue( "kappa.DEFAULT_KAPPA" ), player_x, player_y )
		else
			local targets = EntityGetInRadiusWithTag( p_x, p_y, 500, "enemy" ) or {}
			if( #targets > 0 ) then
				local min_dist = -1
				for i,dud in ipairs( targets ) do
					local has_proper_comps = EntityGetFirstComponentIncludingDisabled( dud, "ControlsComponent" ) ~= nil and EntityGetFirstComponentIncludingDisabled( dud, "CharacterPlatformingComponent" ) ~= nil and EntityGetFirstComponentIncludingDisabled( dud, "CharacterPlatformingComponent" ) ~= nil
					local is_mortal = EntityGetFirstComponentIncludingDisabled( dud, "DamageModelComponent" ) ~= nil
					local has_proper_ai = EntityGetFirstComponentIncludingDisabled( dud, "AnimalAIComponent" ) ~= nil and EntityGetFirstComponentIncludingDisabled( dud, "AdvancedFishAIComponent" ) == nil and EntityGetFirstComponentIncludingDisabled( dud, "BossDragonComponent" ) == nil and EntityGetFirstComponentIncludingDisabled( dud, "CrawlerAnimalComponent" ) == nil and EntityGetFirstComponentIncludingDisabled( dud, "FishAIComponent" ) == nil and EntityGetFirstComponentIncludingDisabled( dud, "PhysicsAIComponent" ) == nil and EntityGetFirstComponentIncludingDisabled( dud, "WormAIComponent" ) == nil
					local is_supported = CANT_DO_TABLE[ EntityGetFilename( dud ) or "balls" ] == nil
					if( has_proper_comps and is_mortal and has_proper_ai and is_supported ) then
						local t_x, t_y = EntityGetTransform( dud )
						local t_dist = math.sqrt(( p_x - t_x )^2 + ( p_y - t_y )^2 )
						if( min_dist == -1 or t_dist < min_dist ) then
							min_dist = t_dist
							target_entity = EntityGetRootEntity( dud )
						end
					end
				end
			end
		end
		
		if( target_entity ~= 0 ) then
			GamePrint( "[TARGET KAPPTURED]" )
			EntityAddTag( target_entity, "kappaed" )
			
			local attack_comps = EntityGetComponentIncludingDisabled( target_entity, "AIAttackComponent" ) or {}
			if( #attack_comps > 0 ) then
				local x, y = EntityGetTransform( target_entity )
				local gun_pics = EntityGetComponentIncludingDisabled( target_entity, "SpriteComponent", "gun" ) or {}
				if( #gun_pics > 0 ) then
					for i,pic in ipairs( gun_pics ) do
						ComponentSetValue2( pic, "visible", false )
						
						local kid = EntityLoad( "mods/kappa/files/base_kid.xml", x, y )
						local pic_comp = EntityGetFirstComponentIncludingDisabled( kid, "SpriteComponent" )
						
						ComponentSetValue2( pic_comp, "image_file", ComponentGetValue2( pic, "image_file" ))
						ComponentSetValue2( pic_comp, "z_index", ComponentGetValue2( pic, "z_index" ) - 0.000001 )
						ComponentSetValue2( pic_comp, "alpha", ComponentGetValue2( pic, "alpha" ))
						ComponentSetValue2( pic_comp, "offset_x", ComponentGetValue2( pic, "offset_x" ))
						ComponentSetValue2( pic_comp, "offset_y", ComponentGetValue2( pic, "offset_y" ))
						ComponentSetValue2( pic_comp, "emissive", ComponentGetValue2( pic, "emissive" ))
						ComponentSetValue2( pic_comp, "additive", ComponentGetValue2( pic, "additive" ))
						
						local scale_x, scale_y = 1, 1
						if( ComponentGetValue2( pic, "has_special_scale" )) then
							scale_x, scale_y = ComponentGetValue2( pic, "special_scale_x" ), ComponentGetValue2( pic, "special_scale_y" )
						end
						
						local offsets = { ComponentGetValue2( pic, "transform_offset" ) }
						ComponentSetValue2( EntityGetFirstComponentIncludingDisabled( kid, "InheritTransformComponent" ), "Transform", offsets[1], offsets[2], scale_x, scale_y, 0 )
						
						EntityRefreshSprite( target_entity, pic )
						EntityRefreshSprite( kid, pic_comp )
						
						EntityAddChild( target_entity, kid )
					end
				end
			end
			
			if( ModSettingGetNextValue( "kappa.DO_BOOSTS" )) then
				local is_godlike = ModSettingGetNextValue( "kappa.GODLIKE" )
				if( is_godlike ) then
					EntityAddTag( target_entity, "godlike" )
				
					ComponentSetValue2( GetGameEffectLoadTo( target_entity, "NO_SLIME_SLOWDOWN", true ), "frames", -1 )
					ComponentSetValue2( GetGameEffectLoadTo( target_entity, "PROTECTION_ALL", true ), "frames", -1 )
					ComponentSetValue2( GetGameEffectLoadTo( target_entity, "PROTECTION_POLYMORPH", true ), "frames", -1 )
					EntityAddComponent( target_entity, "CellEaterComponent", 
					{
						radius = 20,
						ignored_material_tag = "[indestructible]",
					})
					EntityAddComponent( target_entity, "AudioLoopComponent", 
					{
						_tags = "godlike",
						file = "mods/kappa/files/sfx/kappa.bank",
						event_name = "godlike",
						volume_autofade_speed = "0.25",
					})
				end
				edit_component( target_entity, "DamageModelComponent", function(comp,vars)
					local new_hp = ComponentGetValue2( comp, "max_hp" )*tonumber( ModSettingGetNextValue( "kappa.MORE_HP" ))
					ComponentSetValue2( comp, "max_hp", new_hp )
					ComponentSetValue2( comp, "hp", new_hp )
					
					if( is_godlike ) then
						EntitySetComponentIsEnabled( target_entity, comp, false )
					end
				end)
				edit_component( target_entity, "CharacterPlatformingComponent", function(comp,vars)
					local speed_boost = tonumber( ModSettingGetNextValue( "kappa.MORE_SPEED" ))
					
					ComponentSetValue2( comp, "accel_x", 1.5 )
					ComponentSetValue2( comp, "accel_x_air", 1 )
					ComponentSetValue2( comp, "fly_speed_max_down", speed_boost*ComponentGetValue2( comp, "fly_speed_max_down" ))
					ComponentSetValue2( comp, "fly_speed_max_up", speed_boost*ComponentGetValue2( comp, "fly_speed_max_up" ))
					ComponentSetValue2( comp, "velocity_max_x", speed_boost*ComponentGetValue2( comp, "velocity_max_x" ))
					ComponentSetValue2( comp, "velocity_max_y", speed_boost*ComponentGetValue2( comp, "velocity_max_y" ))
					ComponentSetValue2( comp, "velocity_min_x", speed_boost*ComponentGetValue2( comp, "velocity_min_x" ))
					ComponentSetValue2( comp, "velocity_min_y", speed_boost*ComponentGetValue2( comp, "velocity_min_y" ))
					ComponentSetValue2( comp, "fly_velocity_x", speed_boost*ComponentGetValue2( comp, "fly_velocity_x" ))
					ComponentSetValue2( comp, "run_velocity", speed_boost*ComponentGetValue2( comp, "run_velocity" ))
				end)
				edit_component( target_entity, "AnimalAIComponent", function(comp,vars)
					local melee_boost = tonumber( ModSettingGetNextValue( "kappa.MORE_DAMAGE" ))
					if( is_godlike ) then
						melee_boost = melee_boost*99999
						ComponentGetValue2( comp, "can_fly", true )
					end
					
					ComponentSetValue2( comp, "attack_melee_damage_min", melee_boost*ComponentGetValue2( comp, "attack_melee_damage_min" ))
					ComponentSetValue2( comp, "attack_melee_damage_max", melee_boost*ComponentGetValue2( comp, "attack_melee_damage_max" ))
				end)
				
				local randged_boost = 1/tonumber( ModSettingGetNextValue( "kappa.MORE_ATTACK" ))
				if( is_godlike ) then
					randged_boost = 0
				end
				if( #attack_comps > 0 ) then
					for i,attack_comp in ipairs( attack_comps ) do
						ComponentSetValue2( attack_comp, "frames_between_global", randged_boost*ComponentGetValue2( attack_comp, "frames_between_global" ))
						ComponentSetValue2( attack_comp, "frames_between", randged_boost*ComponentGetValue2( attack_comp, "frames_between" ))
					end
				else
					edit_component( target_entity, "AnimalAIComponent", function(comp,vars)
						ComponentSetValue2( comp, "attack_ranged_frames_between", randged_boost*ComponentGetValue2( comp, "attack_ranged_frames_between" ))
					end)
				end
				
				if( not( ModSettingGetNextValue( "kappa.NO_GLOW" ))) then
					local total_amount = tonumber( ModSettingGetNextValue( "kappa.MORE_HP" )) + tonumber( ModSettingGetNextValue( "kappa.MORE_DAMAGE" )) + tonumber( ModSettingGetNextValue( "kappa.MORE_ATTACK" ))*( is_godlike and 10 or 1 )
					ComponentSetValue2( EntityAddComponent( target_entity, "ParticleEmitterComponent", 
					{
						emitted_material_name = "spark_blue",
						render_back = "1",
						render_ultrabright = "0",
						fade_based_on_lifetime = "1",
						lifetime_max = math.ceil( total_amount/5 )/10, 
						lifetime_min = math.ceil( total_amount/5 )/20, 
						emit_real_particles = "0",
						collide_with_grid = "0",
						emit_cosmetic_particles = "1",
						cosmetic_force_create = "1",
						color = "0",
						emitter_lifetime_frames = "-1",
						airflow_force = math.min( total_amount*2, 100 ),
						airflow_time = "10",
						airflow_scale = "50",
						image_animation_file = "mods/kappa/files/pics/glow.png",
						image_animation_colors_file = "mods/kappa/files/pics/glow_pic.png",
						image_animation_speed = "1000",
						image_animation_raytrace_from_center = "0",
						image_animation_loop = "1",
						image_animation_use_entity_rotation = "1",
						emission_interval_max_frames = "1",
						emission_interval_min_frames = "1",
						velocity_always_away_from_center = math.min( total_amount*10, 1000 ),
						is_emitting = "1",
						draw_as_long = "1",
					}), "gravity", 0, -math.min( total_amount*50, 10000 ))
				end
			end
			
			EntitySetComponentIsEnabled( target_entity, EntityGetFirstComponentIncludingDisabled( target_entity, "AnimalAIComponent" ), false )
			EntityAddComponent( target_entity, "StreamingKeepAliveComponent" )
			ComponentSetValue2( EntityGetFirstComponentIncludingDisabled( target_entity, "CharacterPlatformingComponent" ), "keyboard_look", true )
			
			local plat_comp = EntityGetFirstComponentIncludingDisabled( target_entity, "PlatformShooterPlayerComponent" )
			if( plat_comp == nil ) then
				plat_comp = EntityAddComponent( target_entity, "PlatformShooterPlayerComponent" )
			end
			ComponentSetValue2( plat_comp, "eating_cells_per_frame", 0 )
			ComponentSetValue2( plat_comp, "eating_probability", 0 )
			ComponentSetValue2( plat_comp, "eating_delay_frames", 999999999999 )
			ComponentSetValue2( plat_comp, "eating_area_min", 0, -9999999 )
			ComponentSetValue2( plat_comp, "eating_area_max", 0, -9999999 )
			
			if( is_coop ) then
				local gene_comp = EntityGetFirstComponentIncludingDisabled( target_entity, "GenomeDataComponent" )
				if( gene_comp ~= nil ) then
					ComponentSetValue2( gene_comp, "herd_id", StringToHerdId( "player" ))
				end
				EntityRemoveTag( target_entity, "teleportable_NOT" )
				EntityAddTag( target_entity, "teleportable" )
				
				EntityRemoveTag( target_entity, "necromancer_shop" )
				EntityRemoveTag( target_entity, "necromancer_super" )
				EntityRemoveTag( target_entity, "music_energy_050" )
				EntityRemoveTag( target_entity, "music_energy_100" )
				EntityRemoveTag( target_entity, "music_energy_100_near" )
				
				local lua_comps = EntityGetComponentIncludingDisabled( target_entity, "LuaComponent" ) or {}
				if( #lua_comps > 0 ) then
					for i,lua_comp in ipairs( lua_comps ) do
						if( ComponentGetValue2( lua_comp, "script_death" ) == "data/scripts/items/drop_money.lua" ) then
							EntityRemoveComponent( target_entity, lua_comp )
							break
						end
					end
				end
			end
			if( ModSettingGetNextValue( "kappa.KAPPA_HAS_EYES" )) then
				EntityAddComponent( target_entity, "SpriteComponent", 
				{
					alpha = "1",
					emissive = "0",
					image_file = "data/particles/fog_of_war_hole_64.xml",
					smooth_filtering = "1",
					fog_of_war_hole = "1",
				})
			end
			
			local hands_comp = EntityGetFirstComponentIncludingDisabled( target_entity, "ItemPickUpperComponent" )
			if( ModSettingGetNextValue( "kappa.KAPPA_HAS_HANDS" ) and hands_comp == nil ) then
				hands_comp = EntityAddComponent( target_entity, "ItemPickUpperComponent", 
				{ 
					is_immune_to_kicks = "0",
					is_in_npc = "1",
				})
			end
			if( hands_comp ~= nil ) then
				if( ModSettingGetNextValue( "kappa.KAPPA_IRON_HANDS" )) then
					ComponentSetValue2( hands_comp, "is_immune_to_kicks", true )
				end
			end
			
			EntityAddComponent( target_entity, "VariableStorageComponent", 
			{
				name = "kappa_angle",
				value_float = 0,
			})
			EntityAddComponent( target_entity, "VariableStorageComponent", 
			{
				name = "kappa_ranged_cooldown",
				value_int = 0,
			})
			EntityAddComponent( target_entity, "VariableStorageComponent", 
			{
				name = "kappa_melee_cooldown",
				value_int = 0,
			})
			EntityAddComponent( target_entity, "VariableStorageComponent", 
			{
				name = "kappa_dash_cooldown",
				value_int = 0,
			})
			EntityAddComponent( target_entity, "VariableStorageComponent", 
			{
				name = "kappa_current_gun",
				value_int = 1,
			})
			EntityAddComponent( target_entity, "LuaComponent", 
			{
				script_source_file = "mods/kappa/files/kontroller.lua",
				execute_every_n_frame = "1",
			})
			EntityAddComponent( target_entity, "LuaComponent", 
			{
				script_source_file = "mods/kappa/files/remover.lua",
				execute_every_n_frame = "-1",
				execute_on_removed = "1",
			})
			
			GameAddFlagRun( "KAPPA_IS_ACTIVE" )
			if( is_coop and GameGetFrameNum() < 100 ) then
				EntitySetTransform( target_entity, EntityGetTransform( players[1]))
			end
		end
	elseif( #( EntityGetWithTag( "kappaed" ) or {} ) == 0 ) then
		GameRemoveFlagRun( "KAPPA_IS_ACTIVE" )
	end
end

function OnPlayerSpawned( hooman ) 
	GlobalsSetValue( "PROSPERO_IS_REAL", "1" )

	for i = 1,5 do
		local kid = ( i - 1 ) > 0 and i-1 or ""
		GameRemoveFlagRun( "KAPPA_SPAWN_BAN"..kid )
		GameRemoveFlagRun( "KAPPA_IS_ACTIVE"..kid )
		
		local x, y = EntityGetTransform( hooman )
		local dud = EntityGetClosestWithTag( x, y, "kappaed" ) or 0
		if( dud > 0 and EntityGetIsAlive( dud )) then
			GameDropAllItems( dud )
			EntityKill( dud )
		end
	end
end