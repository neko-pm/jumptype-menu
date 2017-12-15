#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "!bhop",
	author = "domino_",
	description = "bhop menu with client side autobhop support",
	version = "0.1.2",
	url = "https://github.com/neko-pm/jumptype-menu"
};

#define CHAT_TAG "Bhop"

bool	g_bLongJump[MAXPLAYERS+1];

ConVar	g_cvJumpType	= null;

ConVar	g_cvJumpDefault	= null;
ConVar	g_cvJumpHeight	= null;
ConVar	g_cvJumpLength	= null;
ConVar	g_cvJumpAA		= null;
ConVar	g_cvJumpLJMaxS	= null;

ConVar	sv_airaccelerate	= null;
ConVar	sv_autobunnyhopping	= null;

Handle	g_hCookieIndex;

public void OnPluginStart()
{
	RegConsoleCmd("sm_bhop", cmd_bhop);
	
	g_hCookieIndex	=	RegClientCookie("sm_bhop_cookie", "store !bhop preference", CookieAccess_Private);
	
	g_cvJumpType	=	CreateConVar("sm_jumptype_only", "2", "0:easy(auto), 1: longjump, 2:both (named for backwards compatablity)", _, true, 0.0, true, 2.0);
	
	g_cvJumpDefault	=	CreateConVar("sm_bhop_jumptype_default", "1", "0:easy(auto), 1: longjump", _, true, 0.0, true, 1.0);
	g_cvJumpHeight	=	CreateConVar("sm_bhop_height", "1.1", "height of longjump (1.0 to disable)");
	g_cvJumpLength	=	CreateConVar("sm_bhop_length", "1.75", "lenght of longjump (1.0 to disable)");
	g_cvJumpAA		=	CreateConVar("sm_bhop_AA_LJ", "3000.0", "set sv_airaccelerate (0.0 to disable)");
	g_cvJumpLJMaxS	=	CreateConVar("sm_bhop_lj_max", "300.0", "maximum speed for applying jump boosts to players");
	
	sv_airaccelerate	= FindConVar("sv_airaccelerate");
	sv_airaccelerate.Flags &= ~FCVAR_NOTIFY;
	
	sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
	sv_autobunnyhopping.BoolValue = false;
	
	HookConVarChange(g_cvJumpLength, OnConVarChange);
	HookConVarChange(g_cvJumpAA, OnConVarChange);
	
	HookEvent("player_jump", OnPlayerJump, EventHookMode_Pre);
	
	for(int i = 1; i <= MaxClients; i++){ g_bLongJump[i] = g_cvJumpDefault.BoolValue; if(IsValidClient(i)) { OnClientPostAdminCheck(i); OnClientCookiesCached(i); }}
}

public void OnPluginEnd()
{
	FindConVar("sv_enablebunnyhopping").RestoreDefault(true, false);
	FindConVar("sv_staminamax").RestoreDefault(true, false);
	FindConVar("sv_staminajumpcost").RestoreDefault(true, false);
	FindConVar("sv_staminalandcost").RestoreDefault(true, false);
	
	if(g_cvJumpAA.FloatValue > 0.0)
		sv_airaccelerate.RestoreDefault(true, false);
	
	sv_autobunnyhopping.RestoreDefault(true, false);
	
	UnhookEvent("player_jump", OnPlayerJump, EventHookMode_Pre);
}

public void OnConfigsExecuted()
{
	FindConVar("sv_enablebunnyhopping").SetInt(1, true, false);
	FindConVar("sv_staminamax").SetInt(0, true, false);
	FindConVar("sv_staminajumpcost").SetInt(0, true, false);
	FindConVar("sv_staminalandcost").SetInt(0, true, false);
	
	if(g_cvJumpAA.FloatValue > 0.0)
		sv_airaccelerate.SetFloat(g_cvJumpAA.FloatValue, true, false);
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_cvJumpType)
		if(g_cvJumpType.IntValue != 2)
			for(int i = 1; i <= MaxClients; i++)
				g_bLongJump[i] = view_as<bool>(g_cvJumpType.IntValue);
		else
			for(int i = 1; i <= MaxClients; i++)
				g_bLongJump[i] = view_as<bool>(g_cvJumpDefault.IntValue);
	
	else if(convar == g_cvJumpAA)
		if(g_cvJumpAA.FloatValue > 0.0)
			sv_airaccelerate.SetFloat(g_cvJumpAA.FloatValue, true, false);
		else
			sv_airaccelerate.RestoreDefault(true, false);
}

public Action cmd_bhop(int iClient, any aArgs)
{
	if(!IsValidClient(iClient) || g_cvJumpType.IntValue != 2) return Plugin_Handled;
	
	if(aArgs > 0)
	{
		char sArg1[2];
		GetCmdArg(1, sArg1, sizeof(sArg1));
		switch(StringToInt(sArg1))
		{
			case 0:		g_bLongJump[iClient] = false;
			case 1:		g_bLongJump[iClient] = true;
			case 2:		g_bLongJump[iClient] = !g_bLongJump[iClient];
			default:	PrintToChat(iClient, "\x01[\x0C%s\x01]\x01 use \x02!bhop 0\x01 for \x04easy(auto) bhop\x01, \x02!bhop 1\x01 for \x04long jump or \x02!bhop 2\x01 to toggle", CHAT_TAG);
		}
		PrintToChat(iClient, "\x01[\x0C%s\x01]\x01 you are now using \x02%s", CHAT_TAG, g_bLongJump[iClient] ? "Long Jump":"Easy Bhop");
		
		SetCookie(iClient, g_hCookieIndex, g_bLongJump[iClient]);
		
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(MenuHandler_Bhop, MENU_ACTIONS_ALL);
	menu.SetTitle("Choose Jump Type");
	
	if(g_bLongJump[iClient])
		menu.AddItem("0", "Enable Easy Bhop");
	else
		menu.AddItem("1", "Enable Long Jump");
	
	menu.ExitButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

public int MenuHandler_Bhop(Menu menu, MenuAction action, int iClient, int iOption)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char[] sInfo = new char[32];
			menu.GetItem(iOption, sInfo, 32);
			
			g_bLongJump[iClient] = view_as<bool>(StringToInt(sInfo));
			PrintToChat(iClient, "\x01[\x0C%s\x01]\x01 you are now using \x02%s", CHAT_TAG, g_bLongJump[iClient] ? "Long Jump":"Easy Bhop");
			
			SetCookie(iClient, g_hCookieIndex, g_bLongJump[iClient]);
			
			cmd_bhop(iClient, 0);
		}
	}
	return 0;
}

public void PreThink(int iClient)
{
	if(IsPlayerAlive(iClient))
		sv_autobunnyhopping.BoolValue = g_bLongJump[iClient] ? false : true;
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsValidClient(iClient))
		return;
	
	SDKHook(iClient, SDKHook_PreThink, PreThink);
	
	if(g_cvJumpType.IntValue != 2)
		g_bLongJump[iClient] = view_as<bool>(g_cvJumpType.IntValue);
}

public void OnClientCookiesCached(int iClient)
{
	char[] sCookie = new char[2];
	
	if(g_cvJumpType.IntValue == 2)
	{
		GetClientCookie(iClient, g_hCookieIndex, sCookie, 2);
		g_bLongJump[iClient] = view_as<bool>(StringToInt(sCookie));
	}
}

public Action OnPlayerJump(Event event, char[] name, bool dontbroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(iClient) && g_bLongJump[iClient])
		RequestFrame(JumpBoostClient, iClient);
}

stock void JumpBoostClient(int iClient)
{
	if(g_cvJumpLength.FloatValue == 1.0 && g_cvJumpHeight.FloatValue == 1.0)
		return;
	
	float m_vecVelocity[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", m_vecVelocity);
	
	if(SquareRoot(Pow(m_vecVelocity[0], 2.0) + Pow(m_vecVelocity[1], 2.0)) < g_cvJumpLJMaxS.FloatValue)
		for(int i = 0; i < 2; i++)
			m_vecVelocity[i] *= g_cvJumpLength.FloatValue;
	
	m_vecVelocity[2] *= g_cvJumpHeight.FloatValue;
	
	TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, m_vecVelocity);
}

stock void SetCookie(int iClient, Handle hCookie, bool b)
{
	char[] sCookie = new char[2];
	IntToString(b, sCookie, 2);
	
	SetClientCookie(iClient, hCookie, sCookie);
}

stock bool IsValidClient(int iClient, bool noBots = true)
{
    if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || !IsClientAuthorized(iClient) || (noBots && IsFakeClient(iClient)))
		return false;
	
    return IsClientInGame(iClient);
}