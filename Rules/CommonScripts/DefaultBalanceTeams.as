#include "RulesCore.as";

void onRestart(CRules@ this)
{
	this.set_bool("managed teams", true);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
	this.get("core", @core);
	
	core.ChangePlayerTeam(player, this.getSpectatorTeamNum());
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);

    if (this.get_bool("teams_locked"))
        getNet().server_SendMsg("Prevented " + player.getUsername() + " from switching teams because teams are locked.");
    else
        core.ChangePlayerTeam(player, newTeam);
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
}
