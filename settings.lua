dofile( "data/scripts/lib/mod_settings.lua" )

function mod_setting_custom_enum( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id( mod_id, setting ))
	local text = setting.ui_name .. ": " .. setting.values[ value ]
	
	local clicked, right_clicked = GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text )
	if clicked then
		value = value + 1
		if( value > #setting.values ) then
			value = 1
		end
		ModSettingSetNextValue( mod_setting_get_id( mod_id,setting ), value, false )
	end
	if right_clicked and setting.value_default then
		ModSettingSetNextValue( mod_setting_get_id( mod_id, setting ), setting.value_default, false )
	end
	
	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_custom_text( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id( mod_id, setting ))
	if( type( value ) ~= "string" ) then
		value = setting.value_default or ""
	end
	
	GuiLayoutBeginHorizontal( gui, 0, 0 )
	GuiOptionsAddForNextWidget( gui, 47 ) --NoSound
	local clicked, right_clicked = GuiButton( gui, im_id, mod_setting_group_x_offset, 0, setting.ui_name )
	if right_clicked and setting.value_default then
		ModSettingSetNextValue( mod_setting_get_id( mod_id, setting ), setting.value_default, false )
	end
	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
	
	GuiOptionsAddForNextWidget( gui, 47 ) --NoSound
	local value_new = GuiTextInput( gui, im_id, 0, 0, value, 250, setting.text_max_length or 25, setting.allowed_characters or "" )
	GuiLayoutEnd( gui )
	if( value ~= value_new ) then
		ModSettingSetNextValue( mod_setting_get_id( mod_id, setting ), value_new, false )
		mod_setting_handle_change_callback( mod_id, gui, in_main_menu, setting, value, value_new )
	end
end

local mod_id = "kappa"
mod_settings_version = 1
mod_settings = 
{
	{
		id = "GLOBAL_MODE",
		ui_name = "Global Mode",
		ui_description = "Changes core gameplay.",
		hidden = false,
		value_default = 3,
		values = { "PvP", "COOP", "MP" },
		scope = MOD_SETTING_SCOPE_NEW_GAME,
		ui_fn = mod_setting_custom_enum,
	},

	{
		category_id = "UI",
		ui_name = "[UI]",
		ui_description = "Customizable visualization.",
		foldable = true,
		_folded = true,
		not_setting = true,
		settings = {
			{
				id = "MANUAL_SELECTION",
				ui_name = "Manual Selection",
				ui_description = "Allow second player to select the target.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "SHOW_POINTER",
				ui_name = "Show Pointer",
				ui_description = "Highlight creature's location.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "SHOW_AIM",
				ui_name = "Show Crosshair",
				ui_description = "Displays creature's aim.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "AIM_SPEED",
				ui_name = "Keyboard Aiming Speed",
				ui_description = "Alters how fast the aim will drift while in keyboard mode.",
				value_default = 3,
				
				value_min = 1,
				value_max = 5,
				value_display_multiplier = 1,
				value_display_formatting = " $0 ",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "SHOW_UI",
				ui_name = "Show Info",
				ui_description = "Displays creature's stats.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "PIN_UI",
				ui_name = "Pin Info Bars",
				ui_description = "Pins creature's stats to the actual UI.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
	{
		category_id = "CREATURE",
		ui_name = "[CREATURE] (does not work in MP mode)",
		ui_description = "Settings for ya bud.",
		foldable = true,
		_folded = true,
		not_setting = true,
		settings = {
			{
				id = "KAPPA_HAS_EYES",
				ui_name = "Friend? sees through fog",
				ui_description = "Will remove fog-of-war at the creature's position.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "KAPPA_HAS_HANDS",
				ui_name = "Force-allow wand pickups",
				ui_description = "Any controllable creature will be able to use the wands.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "KAPPA_IRON_HANDS",
				ui_name = "Force-prevent wand drops on being kicked",
				ui_description = "Makes the creature immune to the wand drops on getting kicked by player.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "KAPPA_CONCRETE_HANDS",
				ui_name = "Force-prevent wand drops on death",
				ui_description = "When the creature goes to the better world, so do its wands.",
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "NO_SUICIDES",
				ui_name = "Prevent Suicides",
				ui_description = "Prevents mass slaughter of the enemies by second player's will.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "SOLID_SCREEN",
				ui_name = "Solid Screen Edges",
				ui_description = "Second player won't be able to get past the edge of the screen.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},

			{
				id = "NEWLINE",
				ui_name = " ",
				not_setting = true,
			},
			{
				id = "KAPPA_SPAWN",
				ui_name = "Spawn Friend?",
				ui_description = "Will automatically spawn a creature and assign it to the second player.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "DEFAULT_KAPPA",
				ui_name = "Friend? Path",
				ui_description = "The path to that creature.\n(you can check a link in the steam description for the list of all vanilla enemies)\n(anything modded will work as long as it is supported)",
				value_default = "data/entities/animals/playerghost.xml",
				text_max_length = 999999,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = mod_setting_custom_text,
			},
			{
				id = "NEWLINE",
				ui_name = " ",
				not_setting = true,
			},

			{
				category_id = "BOOSTS",
				ui_name = "[STAT BOOSTS]",
				ui_description = "To better match or outmatch the player.",
				foldable = true,
				_folded = true,
				not_setting = true,
				settings = {
					{
						id = "DO_BOOSTS",
						ui_name = "Apply Boosts",
						ui_description = "",
						value_default = false,
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "NO_GLOW",
						ui_name = "Hide Power Signature",
						ui_description = "Ultra Instinct Goku Theme Song - Clash Of The Gods (Recreation)",
						value_default = false,
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "MORE_HP",
						ui_name = "HP Multiplayer",
						ui_description = "Boosts total HP pool.",
						value_default = "2",
						text_max_length = 999999,
						allowed_characters = "0123456789.",
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "MORE_SPEED",
						ui_name = "Speed Multiplayer",
						ui_description = "Boosts overall movement speed.",
						value_default = "2",
						text_max_length = 999999,
						allowed_characters = "0123456789.",
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "MORE_DAMAGE",
						ui_name = "Melee Multiplayer",
						ui_description = "Boosts melee damage.",
						value_default = "2",
						text_max_length = 999999,
						allowed_characters = "0123456789.",
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "MORE_ATTACK",
						ui_name = "Ranged Multiplayer",
						ui_description = "Lowers delay between shots.",
						value_default = "2",
						text_max_length = 999999,
						allowed_characters = "0123456789.",
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
					{
						id = "GODLIKE",
						ui_name = "Bring Me The Horizon - Can You Feel My Heart",
						ui_description = "do it",
						value_default = false,
						scope = MOD_SETTING_SCOPE_RUNTIME,
					},
				},
			},
		},
	},
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end