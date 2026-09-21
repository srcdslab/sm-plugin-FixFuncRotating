#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#pragma newdecls required

public Plugin myinfo =
{
	name = "FixFuncRotating",
	author = "Cloud Strife",
	description = "Fixes func_rotating`s StartForward and StopAtStartPos inputs",
	version = "1.0.3",
	url = ""
};

Handle g_CFuncRotating_StartForward = null;
Handle g_CFuncRotating_UpdateSpeed = null;

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR < 12
stock float FloatMod(float num, float denom)
{
	return num - denom * RoundToFloor(num / denom);
}

stock float operator%(float oper1, float oper2)
{
	return FloatMod(oper1, oper2);
}
#endif

// Set m_bStopAtStartPos to false
public MRESReturn CFuncRotating_InputStartForward(int entity)
{
	SetEntProp(entity, Prop_Data, "m_bStopAtStartPos", false, 1);
	return MRES_Ignored;
}

public MRESReturn CFuncRotating_UpdateSpeed(int entity, Handle hParams)
{
	if(GetEntProp(entity, Prop_Data, "m_bStopAtStartPos", 1))
	{
		float flNewSpeed = view_as<float>(DHookGetParam(hParams, 1));
		if(flNewSpeed <= 25)
		{
			float vecMoveAng[3], angStart[3], angRotation[3], avelpertick[3];

			GetEntPropVector(entity, Prop_Data, "m_vecMoveAng", vecMoveAng);
			GetEntPropVector(entity, Prop_Data, "m_angStart", angStart);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", angRotation);
			GetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", avelpertick);
			ScaleVector(avelpertick, GetTickInterval());

			int checkAxis = 2;
			if (vecMoveAng[0] != 0) checkAxis = 0;
			else if ( vecMoveAng[1] != 0 ) checkAxis = 1;

			float angDelta = ( angRotation[ checkAxis ] - angStart[ checkAxis ] )%360.0;
			if ( angDelta > 180.0 ) angDelta -= 360.0;

			if(FloatAbs(angDelta) < FloatAbs(avelpertick[ checkAxis ]))
			{
				SetEntPropVector(entity, Prop_Data, "m_angRotation", angStart);
				return MRES_Ignored;
			}
		}
	}
	return MRES_Ignored;
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("FixFuncRotating.games");
	if(hGameConf == INVALID_HANDLE)
	{
		LogError("Couldn't load FixFuncRotating.games game config!");
		return;
	}

	Address pStartForward = GameConfGetAddress(hGameConf, "CFuncRotating::InputStartForward");
	if(pStartForward)
	{
		g_CFuncRotating_StartForward = DHookCreateDetour(pStartForward, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);

		if(!DHookEnableDetour(g_CFuncRotating_StartForward, false, CFuncRotating_InputStartForward))
		{
			LogError("Could not enable detour for CFuncRotating::InputStartForward");
		}
	}
	else LogError("Could not find CFuncRotating::InputStartForward address");

	Address pUpdateSpeed = GameConfGetAddress(hGameConf, "CFuncRotating::UpdateSpeed");
	if(!pUpdateSpeed)
	{
		LogError("Could not find CFuncRotating::UpdateSpeed address");
		delete hGameConf;
		return;
	}

	g_CFuncRotating_UpdateSpeed = DHookCreateDetour(pUpdateSpeed, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	DHookAddParam(g_CFuncRotating_UpdateSpeed, HookParamType_Float);

	if(!DHookEnableDetour(g_CFuncRotating_UpdateSpeed, false, CFuncRotating_UpdateSpeed))
	{
		LogError("Could not enable detour for CFuncRotating::UpdateSpeed");
	}

	delete hGameConf;
}
