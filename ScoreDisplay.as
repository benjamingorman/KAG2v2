#include "Logging.as";

const SColor TEAM0COLOR(255,25,94,157);
const SColor TEAM1COLOR(255,192,36,36);
const u8 FONT_SIZE = 30;

int GetScore(CRules@ this, int team) {
    string prop = "team" + team + "score";
    if (this.exists(prop)) {
        return this.get_u8(prop);
    }
    else {
        log("GetScore", "No score found for team " + team);
        return 0;
    }
}

void SetScore(CRules@ this, int team0Score, int team1Score) {
    log("SetScore", "Setting to " + team0Score + ", " + team1Score);
    /*
    if (getNet().isServer()) {
        CBitStream params;
        params.write_u16(0x5AFE); // check
        params.write_u8(team0Score);
        params.write_u8(team1Score);
        this.SendCommand(this.getCommandID("set score"), params);
    }
    */
    this.set_u8("team0score", team0Score);
    this.set_u8("team1score", team1Score);
    if (getNet().isServer()) {
        this.Sync("team0score", true);
        this.Sync("team1score", true);
    }
}

void ToggleScore(CRules@ this) {
    this.set_bool("show score", !this.get_bool("show score"));
    this.Sync("show score", true);
}

void onInit(CRules@ this) {
    if (!GUI::isFontLoaded("big score font")) {
        GUI::LoadFont("big score font",
                      "GUI/Fonts/AveriaSerif-Bold.ttf", 
                      FONT_SIZE,
                      true);
    }
    this.set_bool("show score", true);
    this.addCommandID("set score");

    if (getNet().isServer()) {
        SetScore(this, 0, 0);
    }
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player) {
    this.SyncToPlayer("team0score", player);
    this.SyncToPlayer("team1score", player);
}

/*
void onCommand(CRules@ this, u8 cmd, CBitStream@ params) {
    if (cmd == this.getCommandID("set score")) {
        //log("onCommand", "got set score command");
        u16 check = 0x5AFE;
        if (params.read_u16() != check) {
            log("onCommand", "set score params failed check");
        }
        u8 team0Score = params.read_u8();
        u8 team1Score = params.read_u8();
        //log("onCommand", team0Score + ", " + team1Score);
        this.set_u8("team0score", team0Score);
        this.set_u8("team1score", team1Score);
    }
}
*/

void onStateChange(CRules@ this, const u8 oldState) {
    // Detect game over
    if (this.getCurrentState() == GAME_OVER &&
            oldState != GAME_OVER) {
        int winningTeam = this.getTeamWon();
        //log("onStateChange", "Detected game over! Winning team: " + winningTeam);

        if (winningTeam == 0) {
            //log("onStateChange", "Winning team is 0");
            SetScore(this, GetScore(this, 0) + 1, GetScore(this, 1));
        }
        else if (winningTeam == 1) {
            //log("onStateChange", "Winning team is 1");
            SetScore(this, GetScore(this, 0), GetScore(this, 1) + 1);
        }
    }
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player) {
    if (player is null) return true;

    //log("onServerProcessChat", "Got: " + text_in);
    if (text_in == "!resetscore") {
        //log("onServerProcessChat", "Parsed !resetscore cmd");
        SetScore(this, 0, 0);
    }
    else if (text_in == "!togglescore") {
        //log("onServerProcessChat", "Parsed !togglescore cmd");
        ToggleScore(this);
    }
    else {
        string[]@ tokens = text_in.split(" ");
        if (tokens[0] == "!setscore" && tokens.length == 3) {
            //log("onServerProcessChat", "Parsed !setscore cmd");
            string team0ScoreStr = tokens[1];
            string team1ScoreStr = tokens[2];
            int team0Score = parseInt(team0ScoreStr);
            int team1Score = parseInt(team1ScoreStr);
            SetScore(this, team0Score, team1Score);
        }
    }

    return true;
}

void onRender(CRules@ this)
{
    if (!this.get_bool("show score")) return;

    GUI::SetFont("big score font");
    u8 team0Score = GetScore(this, 0);
    u8 team1Score = GetScore(this, 1);
    //log("onRender", "" + team0Score + ", " + team1Score);
    Vec2f team0ScoreDims;
    Vec2f team1ScoreDims;
    Vec2f scoreSeperatorDims;
    GUI::GetTextDimensions("" + team0Score, team0ScoreDims);
    GUI::GetTextDimensions("" + team1Score, team1ScoreDims);
    GUI::GetTextDimensions("-", scoreSeperatorDims);

    Vec2f scoreDisplayCentre(getScreenWidth()/2, getScreenHeight() / 5.0);
    int scoreSpacing = 24;

    Vec2f topLeft0(
            scoreDisplayCentre.x - scoreSpacing - team0ScoreDims.x,
            scoreDisplayCentre.y);
    Vec2f topLeft1(
            scoreDisplayCentre.x + scoreSpacing,
            scoreDisplayCentre.y);
    GUI::DrawText("" + team0Score, topLeft0, TEAM0COLOR);
    GUI::DrawText("-", Vec2f(scoreDisplayCentre.x - scoreSeperatorDims.x/2.0, scoreDisplayCentre.y), color_black);
    GUI::DrawText("" + team1Score, topLeft1, TEAM1COLOR);
}
