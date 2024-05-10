local hooman = GetUpdatedEntityID()
local parent = EntityGetRootEntity( hooman )
if( hooman == parent ) then
	EntityKill( hooman )
end