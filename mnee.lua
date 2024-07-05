for i = 1,4 do
	local is_main = i == 1
	if( not( is_main )) then
		_MNEEDATA[ "kappa:p"..( i + 1 )] = {
			id = i,
			is_hidden = function( mod_id, jpads )
				return jpads[ _MNEEDATA[ mod_id ].id ] == -1
			end,
		}
	end
	_BINDINGS[ "kappa"..( is_main and "" or ":p"..( i + 1 ))] = {
		rally = is_main and {
			order_id = "!a",
			name = "Rally",
			desc = "Teleports all secondary players to the primary (does not work in PvP mode).",
			keys = { x = 1, },
		} or nil,
		spawn = {
			order_id = "!b",
			name = "Spawn",
			desc = "Use this to create an additional player character.",
			keys = {[ i.."gpd_a" ] = 1, },
			keys_alt = is_main and { keypad_1 = 1, } or nil,
		},

		movement_v = {
			is_hidden = true,
			name = "Movement Vertical",
			desc = "Controls up and down.",
			keys = { "is_axis", i.."gpd_axis_lv", },
			keys_alt = is_main and { "is_axis", "keypad_8", "keypad_5" } or nil,
		},
		movement_h = {
			is_hidden = true,
			name = "Movement Horizontal",
			desc = "Controls left and right.",
			keys = { "is_axis", i.."gpd_axis_lh", },
			keys_alt = is_main and { "is_axis", "keypad_4", "keypad_6" } or nil,
		},
		movement = {
			order_id = "aa",
			jpad_type = "MOTION",
			deadzone = 0.05,
			name = "Movement",
			desc = "Moves the character around.",
			axes = { "movement_h", "movement_v" },
		},
		aim_v = {
			is_hidden = true,
			name = "Aim Vertical",
			desc = "Controls up and down.",
			keys = { "is_axis", i.."gpd_axis_rv", },
			keys_alt = is_main and { "is_axis", "up", "down" } or { "is_axis", "NOPE", "NOPE" },
		},
		aim_h = {
			is_hidden = true,
			name = "Aim Horizontal",
			desc = "Controls left and right.",
			keys = { "is_axis", i.."gpd_axis_rh", },
			keys_alt = { "is_axis", "NOPE", "NOPE" },
		},
		aim = {
			order_id = "ab",
			jpad_type = "AIM",
			name = "Aim",
			desc = "Moves the crosshair around.",
			axes = { "aim_h", "aim_v" },
		},
		halt_autoaim = {
			order_id = "ac",
			name = "Halt Autoaim",
			desc = "Stops aim assists from messing up the inputs while is held.",
			keys = {[ i.."gpd_r1" ] = 1, },
			keys_alt = is_main and {["keypad_3"] = 1, } or nil,
		},
		
		next_gun = {
			order_id = "ba",
			name = "Next Attack",
			desc = "Switches between ranged attack modes, assuming there're many or any.",
			keys = {[ i.."gpd_right" ] = 1, },
			keys_alt = is_main and { right = 1, } or nil,
		},
		previous_gun = {
			order_id = "bb",
			name = "Previous Attack",
			desc = "Switches between ranged attack modes, assuming there're many or any.",
			keys = {[ i.."gpd_left" ] = 1, },
			keys_alt = is_main and { left = 1, } or nil,
		},
		shoot = {
			order_id = "bc",
			name = "Shoot",
			desc = "Creature will attempt to perform a randged attack.",
			keys = {[ i.."gpd_r2" ] = 1 },
			keys_alt = is_main and { keypad_0 = 1, } or nil,
		},
		melee = {
			order_id = "bd",
			name = "Melee",
			desc = "Creature will attempt to perform a melee attack.",
			keys = {[ i.."gpd_l2" ] = 1, },
			keys_alt = is_main and { keypad_1 = 1, } or nil,
		},
		
		drop = {
			order_id = "ca",
			name = "Drop/Pick Up",
			desc = "Creature will drop currently held wand/pick up wand from the floor.",
			keys = {[ i.."gpd_y" ] = 1, },
			keys_alt = is_main and { keypad_9 = 1, } or nil,
		},
		suicide = {
			order_id = "cb",
			name = "Suicide",
			desc = "Creature will die from \"natural\" causes.",
			keys = {[ i.."gpd_b" ] = 1, },
			keys_alt = is_main and { keypad_7 = 1, } or nil,
		},
	}
end