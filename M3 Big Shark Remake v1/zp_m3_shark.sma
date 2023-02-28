/*
	[NOTE]
	This is Remake of M3 Big Shark,
	this on is first weapon from me there maybe some bugs,
	bugs will be fix in next versions.
	Dont forget to give credits & feedback.

*/
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

/* ~ [ Shotgun Settings ] ~ */
new const SHOTGUN_MODEL_VIEW[] 	= "models/cso/v_m3shark.mdl";
new const SHOTGUN_MODEL_PLAYER[]= "models/cso/p_m3shark.mdl";
new const SHOTGUN_MODEL_WORLD[] = "models/cso/w_m3shark.mdl";

new const SHARKMODEL [] = "models/cso/m3shark_effect.mdl";
new const MISSILEMODEL[]= "sprites/cso/ef_m3water.spr";
new const WATERMODEL[]	= "models/cso/ef_m3shark_sign.mdl";

/* ~ [ CLASS NAMES ] ~ */
#define DRAGON_CLASSNAME			"SharClass"
#define MISSILE_CLASSNAME			"SharkMissile"
#define WATER_CLASSNAME				"WaterShark"

new const SHOTGUN_REFERENCE[] = "weapon_m3";
const SHOTGUN_SPECIAL_CODE = 58002;

new const CHAT_COMMAND[] = "shark";

const SHOTGUN_AMMO = 8;
const SHOTGUN_BPAMMO = 100;

/* ~ [ Shotgun Primary Attack ] ~ */
new const SHOTGUN_SHOOT_SOUND[] = "cso/m3shark-1_1.wav";
new const SHOTGUN_SHOOT2_SOUND[] = "cso/m3shark-2.wav";
new const SHOTGUN_EXPLODE_SOUND[] = "cso/m3shark_fx.wav";

const Float: SHOTGUN_SHOOT_RATE = 1.1;
const Float: SHOTGUN_SHOOT_PUNCHANGLE = 0.2;
const Float: SHOTGUN_SHOOT_DAMAGE = 4.50;

/* ~ [ Shotgun Secondary Attack ] ~ */
const WEAPON_MAX_CHARGES = 1;
const WEAPON_SHOTS_COUNT = 6;
#define DAMAGE_SPECIAL 650
#define WEAPON_RADIUS_EXP	200.0
#define WEAPON_RADIUS_EXP2	110.0

/* ~ [ Shotgun WeaponList ] ~ */
new const SHOTGUN_WEAPONLIST[] = "weapon_m3shark";
new const iShotgunList[] = { 5, 32, -1, -1, 0, 5, 21, 0 };

/* ~ [ANIMATION (Frames/FPS) PRIMARY] ~ */
#define SHOTGUN_ANIM_IDLE_TIME 111/30.0
#define SHOTGUN_ANIM_DRAW_TIME 31/30.0
#define SHOTGUN_ANIM_SHOOT_TIME 41/30.0
#define SHOTGUN_ANIM_SHOOT2_TIME 41/37.0
#define SHOTGUN_ANIM_INSERT_TIME 28/65.0
#define SHOTGUN_ANIM_AFTER_RELOAD_TIME 39/38.0
#define SHOTGUN_ANIM_START_RELOAD_TIME 16/30.0

/* ~ [ANIMATION PRIMARY] ~ */
#define ANIME_IDLE 0
#define ANIME_SHOOT1 1
#define ANIME_INSERT 3
#define ANIME_AFTER_RELOAD 4
#define ANIME_START_RELOAD 5
#define ANIME_DRAW 6

/* ~ [ANIMATION SECONDARY] ~ */
#define ANIME_SECONDARY_SHOOT 8
#define ANIME_SECONDARY_SHOOT2 13
#define ANIME_SECONDAR_READY 7
#define ANIME_SECONDARY_INSERT 9
#define ANIME_SECONDARY_AFTER_RELOAD 10
#define ANIME_SECONDRAY_START_RELOAD 11
#define ANIME_SECONDARY_DRAW 12

/* ~ [CONF SECONDARY] ~ */
#define m_iFlames m_iFamasShotsFired
#define m_iShotsCount m_iGlock18ShotsFired

/* ~ [ Shotgun Conditions ] ~ */
#define IsCustomShotgun(%0) (pev(%0, pev_impulse) == SHOTGUN_SPECIAL_CODE)
#define IsValidEntity(%0) (pev_valid(%0) == 2)

/* ~ [EXTRA STUFF] ~ */
#define SET_MODEL(%0,%1)			engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)			engfunc(EngFunc_SetOrigin, %0, %1)
#define SET_SIZE(%0,%1,%2)			engfunc(EngFunc_SetSize, %0, %1, %2)

/* ~ [CUSTOM MUZZLEFLASH] ~ */
#define IsCustomMuzzle(%0)	(pev(%0, pev_impulse) == gl_iszAllocString_MuzzleKey)
new const WEAPON_MUZZLEFLASH_SPRITE[] = "sprites/muzzleflash106.spr"
new const ENTITY_MUZZLE_CLASSNAME[] = "muzzle_m3shark";
const m_maxFrame = 35;

/*if u want us bits to assign player 
#define IsCustomShotgun(%1) get_bit(gl_iBitCustomItem, %1)
#define get_bit(%1,%2) ((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2) %1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2) %1 &= ~(1 << (%2 & 31))
*/

/* ~ [ Offsets ] ~ */
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rpgPlayerItems = 367;
const m_pNext = 42
const m_iShotsFired = 64;
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle = 48;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_rgpPlayerItems_iShotgunBox = 34;
const m_fInSpecialReload = 55;
const m_iFamasShotsFired = 72;
const m_flVelocityModifier = 108;
const m_iGlock18ShotsFired = 70;
new iBlood[2],g_item;

/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],
    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,
    gl_iMsgID_Weaponlist,	
    gl_iMsgID_StatusIcon,
	gl_iszAllocString_MuzzleKey;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
		register_plugin("Cso M3 Big Shark[Remake]", "1.0", "Tech2cool");

		// Fakemeta
		register_forward(FM_UpdateClientData,      "FM_Hook_UpdateClientData_Post",      true);
		register_forward(FM_SetModel, 			   "FM_Hook_SetModel_Pre",              true);

		//shotgun
		RegisterHam(Ham_Item_Deploy,             SHOTGUN_REFERENCE,    	"CShotgun__Deploy_Post",           	true);
		RegisterHam(Ham_Weapon_PrimaryAttack,    SHOTGUN_REFERENCE,    	"CShotgun__PrimaryAttack_Pre",    	false);
		RegisterHam(Ham_Weapon_Reload,           SHOTGUN_REFERENCE,	  	"CShotgun__Reload_Pre",           	false);
		RegisterHam(Ham_Item_PostFrame,          SHOTGUN_REFERENCE,	 	"CShotgun__PostFrame_Pre",       	false);
		RegisterHam(Ham_Item_Holster,            SHOTGUN_REFERENCE,	  	"CShotgun__Holster_Post",         	true);
		RegisterHam(Ham_Item_AddToPlayer,		 SHOTGUN_REFERENCE,   	"CShotgun__AddToPlayer_Post",      	true);
		RegisterHam(Ham_Weapon_WeaponIdle,       SHOTGUN_REFERENCE,	  	"CShotgun__Idle_Pre",             	false);
		RegisterHam(Ham_Weapon_SecondaryAttack,  SHOTGUN_REFERENCE,	"CWeapon__SecondaryAttack_Pre", 	false);

		//ham think /touch
		RegisterHam(Ham_Think, "info_target", "HamHook_Think", false);
		RegisterHam(Ham_Touch, "info_target", "HamHook_Touch", false);
		RegisterHam(Ham_Think, "env_sprite", "CMuzzleFlash__Think_Pre", false);

		// Trace Attack
		gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre",  false);
		gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre",  false);
		gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre",  false);
		gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre",  false);

		// Alloc String
		gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, SHOTGUN_REFERENCE);
		gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, SHOTGUN_MODEL_VIEW);
		gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, SHOTGUN_MODEL_PLAYER);

		// Messages
		gl_iMsgID_Weaponlist =	get_user_msgid("WeaponList");
		gl_iMsgID_StatusIcon =	get_user_msgid("StatusIcon");

		// Chat Command
		register_clcmd(CHAT_COMMAND, "Command_GiveShotgun");
		
		// Ham Hook
		fm_ham_hook(false);

		//zp extra
		g_item = zp_register_extra_item("CSO M3 Big Shark", 0, ZP_TEAM_HUMAN)
}

public plugin_precache()
{
		// Precache Models
		engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_VIEW);
		engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_PLAYER);
		engfunc(EngFunc_PrecacheModel, SHOTGUN_MODEL_WORLD);

		// Precache Sounds
		engfunc(EngFunc_PrecacheSound, SHOTGUN_SHOOT_SOUND);
		engfunc(EngFunc_PrecacheSound, SHOTGUN_SHOOT2_SOUND);
		engfunc(EngFunc_PrecacheSound, SHOTGUN_EXPLODE_SOUND);
		// Precache generic
		new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", SHOTGUN_WEAPONLIST);
		engfunc(EngFunc_PrecacheGeneric, szWeaponList);

		// Hook weapon
		register_clcmd(SHOTGUN_WEAPONLIST, "Command_HookShotgun");

		//shark, water, missile
		engfunc(EngFunc_PrecacheModel, WATERMODEL);
		engfunc(EngFunc_PrecacheModel, SHARKMODEL);
		engfunc(EngFunc_PrecacheModel, MISSILEMODEL);
		engfunc(EngFunc_PrecacheModel, WEAPON_MUZZLEFLASH_SPRITE);

		//Water Stuff
		iBlood[0] = precache_model("sprites/cso/ef_m3waterbomb.spr");
		iBlood[1] = precache_model("sprites/cso/ef_m3shark_water.spr");
}

public Command_HookShotgun(iPlayer)
{
    engclient_cmd(iPlayer, SHOTGUN_REFERENCE);
    return PLUGIN_HANDLED;
}
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem==g_item)
	{
		Command_GiveShotgun(iPlayer);
	}
}
//Give Weapon
public Command_GiveShotgun(iPlayer)
{
    static iShotgun; iShotgun = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsValidEntity(iShotgun)) return FM_NULLENT;

    set_pev(iShotgun, pev_impulse, SHOTGUN_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, iShotgun);
    set_pdata_int(iShotgun, m_iClip, SHOTGUN_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iShotgun));

    if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iShotgun))
    {
	set_pev(iShotgun, pev_flags, pev(iShotgun, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, iShotgun, iPlayer);
    UTIL_WeaponList(iPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iShotgun, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) < SHOTGUN_BPAMMO)
    set_pdata_int(iPlayer, iAmmoType, SHOTGUN_BPAMMO, linux_diff_player);

    emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

public HamHook_Think(const iEntity)
{
	if (!pev_valid(iEntity))
	{
		return HAM_IGNORED;
	}

	static iClassname[32];pev(iEntity, pev_classname, iClassname, sizeof(iClassname));

	static iAttacker;iAttacker=pev(iEntity, pev_owner);

	static Float:OriginEnt[3];pev(iEntity, pev_origin, OriginEnt);

	if (equal(iClassname, MISSILE_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser3, iFuser);

		if (pev(iEntity, pev_movetype) == MOVETYPE_TOSS)
		{
			set_pev(iEntity, pev_velocity, Float:{0.0,0.0, -1000.0});
		}

		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			
			set_pev(iEntity, pev_fuser3, 0.0);

			Spawn(pev(iEntity, pev_owner), OriginEnt);
			
			return HAM_SUPERCEDE;
		}

		new Float:iAngle[3];

		iAngle[0] = 0.0;
		iAngle[1] = 0.0;
		iAngle[2] = random_float(0.0, -360.0);

		set_pev(iEntity, pev_angles, iAngle);

		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}
	else if (equal(iClassname, DRAGON_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser2, iFuser);

		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			set_pev(iEntity, pev_fuser2, 0.0);
			
			return HAM_IGNORED;
		}

		new pNull = FM_NULLENT;

		while((pNull = fm_find_ent_in_sphere(pNull, OriginEnt, WEAPON_RADIUS_EXP2)) != 0)
		{	
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
			
			if (IsValidEntity(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull))
				{
					new Float:vOrigin[3], Float:dist, Float:damage;pev(pNull, pev_origin, vOrigin);

					static Float:iVelo[3];pev(pNull, pev_velocity, iVelo);iVelo[0] = 0.0;iVelo[1] = 0.0;iVelo[2] += 250.0;
					set_pev(pNull, pev_velocity, iVelo);
					
					dist = get_distance_f(OriginEnt, vOrigin);
					damage = DAMAGE_SPECIAL - (DAMAGE_SPECIAL/DAMAGE_SPECIAL) * dist;

					if (damage > 0.0)
					{
						ExecuteHamB(Ham_TakeDamage, pNull, iEntity, iAttacker, damage, DMG_BULLET);
					}

					set_pdata_float(pNull, m_flVelocityModifier, 1.0,  linux_diff_player);
				}
			}
		}

		set_pev(iEntity, pev_nextthink, get_gametime() + 0.2);
	}
	else if (equal(iClassname, WATER_CLASSNAME))
	{
		static Float:iFuser;pev(iEntity, pev_fuser4, iFuser);

		if (iFuser && iFuser <= get_gametime())
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);

			set_pev(iEntity, pev_fuser4, 0.0);

			return HAM_SUPERCEDE;
		}

		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);
	}

	return HAM_IGNORED;
}

public HamHook_Touch(const iEntity, const iOther)
{
	if(!pev_valid(iEntity))
	{
		return HAM_IGNORED;
	}

	static Classname[32];pev(iEntity, pev_classname, Classname, sizeof(Classname));

	static Float:OriginEnt[3];pev(iEntity, pev_origin, OriginEnt);
	static Float:vOrigin[3];pev(iOther, pev_origin, vOrigin);

	static iAttacker;iAttacker = pev(iEntity, pev_owner);

	if (equal(Classname, MISSILE_CLASSNAME))
	{	
		if (pev(iEntity, pev_iuser1))
		{
			return HAM_IGNORED;
		}

		set_pev(iEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(iEntity, pev_renderamt, 0.0);

		engfunc(EngFunc_DropToFloor, iEntity);

		set_pev(iEntity, pev_iuser1, 1);
		set_pev(iEntity, pev_fuser3, get_gametime() + 1.0);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, OriginEnt[0]);
		engfunc(EngFunc_WriteCoord, OriginEnt[1]);
		engfunc(EngFunc_WriteCoord, OriginEnt[2] + 50.0);
		write_short(iBlood[0]);
		write_byte(20);
		write_byte(15);
		write_byte(TE_EXPLFLAG_NOSOUND |TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS);
		message_end();

		new pNull = FM_NULLENT;

		while((pNull = fm_find_ent_in_sphere(pNull, OriginEnt, WEAPON_RADIUS_EXP)) != 0)
		{
			new Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);

			if (IsValidEntity(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull))
				{
					new Float:vOrigin[3], Float:dist, Float:damage;pev(pNull, pev_origin, vOrigin);

					set_pev(pNull, pev_velocity, {0.0, 0.0, -100.0});

					dist = get_distance_f(OriginEnt, vOrigin);
					damage = DAMAGE_SPECIAL - (DAMAGE_SPECIAL/DAMAGE_SPECIAL) * dist;

					if (damage > 0.0)
					{
						ExecuteHamB(Ham_TakeDamage, pNull, 0, iAttacker, damage, DMG_BULLET);
					}
				}
			}
		}
		emit_sound(iEntity, CHAN_ITEM, SHOTGUN_EXPLODE_SOUND, 1.0, ATTN_NORM, 0, PITCH_HIGH);

		return HAM_IGNORED;
	}

	return HAM_IGNORED;
}

/* ~ [ Hamsandwich ] ~ */
public CShotgun__Deploy_Post(iShotgun)
{
		if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

		static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);
		static iCharges; iCharges = get_pdata_int(iShotgun, m_iFlames, linux_diff_weapon);
		if(!iCharges)
		{
			UTIL_SendWeaponAnim(iPlayer, ANIME_DRAW);
		}else
		{
			UTIL_SendWeaponAnim(iPlayer, ANIME_SECONDARY_DRAW);
		}
		UTIL_StatusIcon(iShotgun, iPlayer, 0);
		UTIL_StatusIcon(iShotgun, iPlayer, 1);
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
		set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);
		set_pdata_float(iPlayer, m_flNextAttack, SHOTGUN_ANIM_DRAW_TIME, linux_diff_player);
		set_pdata_float(iShotgun, m_flTimeWeaponIdle, SHOTGUN_ANIM_DRAW_TIME, linux_diff_weapon);
	}

public CShotgun__PrimaryAttack_Pre(iShotgun)
{
		if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;
	
		static iAmmo; iAmmo = get_pdata_int(iShotgun, m_iClip, linux_diff_weapon);
		static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);
		if(!iAmmo)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iShotgun);
			set_pdata_float(iShotgun, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);
			return HAM_SUPERCEDE;
		}

		static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
		static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
		fm_ham_hook(true);		

		ExecuteHam(Ham_Weapon_PrimaryAttack, iShotgun);
		unregister_forward(FM_TraceLine, fw_TraceLine, true);
		unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
		fm_ham_hook(false);

		static Float: vecPunchangle[3];
		pev(iPlayer, pev_punchangle, vecPunchangle);
		vecPunchangle[0] *= SHOTGUN_SHOOT_PUNCHANGLE
		vecPunchangle[1] *= SHOTGUN_SHOOT_PUNCHANGLE
		vecPunchangle[2] *= SHOTGUN_SHOOT_PUNCHANGLE
		set_pev(iPlayer, pev_punchangle, vecPunchangle);
		CWeapon__CheckShots(iShotgun, iPlayer);	

		emit_sound(iPlayer, CHAN_WEAPON, SHOTGUN_SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateMuzzleFlash(iPlayer, WEAPON_MUZZLEFLASH_SPRITE, 0, 0.07, 255.0, 1, 0.02);
		static iCharges; iCharges = get_pdata_int(iShotgun, m_iFlames, linux_diff_weapon);
		if(!iCharges)
		{
			UTIL_SendWeaponAnim(iPlayer, ANIME_SHOOT1);
		}else
		{
			UTIL_SendWeaponAnim(iPlayer, ANIME_SECONDARY_SHOOT2);
		}
		set_pdata_float(iPlayer, m_flNextAttack, SHOTGUN_SHOOT_RATE, linux_diff_player);
		set_pdata_float(iShotgun, m_flTimeWeaponIdle, SHOTGUN_ANIM_SHOOT_TIME, linux_diff_weapon);
		set_pdata_float(iShotgun, m_flNextPrimaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);
		set_pdata_float(iShotgun, m_flNextSecondaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(!IsValidEntity(iItem) || !IsCustomShotgun(iItem)) return HAM_IGNORED;
	
	static iCharges; iCharges = get_pdata_int(iItem, m_iFlames, linux_diff_weapon);
	UTIL_SendWeaponAnim(iPlayer, ANIME_SECONDARY_SHOOT);

	static iAnimDesired; 
	static szAnimation[64];
									
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
					
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.5, linux_diff_weapon);
	
	Punchangle(iPlayer, .iVecx = -3.5, .iVecy = 0.0, .iVecz = 0.0);

	
	new Float:vecEnd[3];GetWeaponPosition(iPlayer, 4096.0, 0.0, 0.0, vecEnd);
	new Float:vecSrc[3];GetWeaponPosition(iPlayer, 10.0, 0.0, 0.0, vecSrc);
	static Float:OriginEnt[3];pev(iPlayer, pev_origin, OriginEnt);

	Spawn2(iPlayer, vecSrc, vecEnd); 

	emit_sound(iPlayer, CHAN_WEAPON, SHOTGUN_SHOOT2_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	iCharges--;
	set_pdata_int(iItem, m_iFlames, iCharges, linux_diff_weapon);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	set_pdata_float(iItem, m_flNextPrimaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, SHOTGUN_SHOOT_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, SHOTGUN_ANIM_SHOOT2_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CShotgun__Reload_Pre(iShotgun)
{
		if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;
		
		static iCharges; iCharges = get_pdata_int(iShotgun, m_iFlames, linux_diff_weapon);
		if(!iCharges)
		{
			UTIL_ShotgunReload(iShotgun, ANIME_START_RELOAD, SHOTGUN_ANIM_START_RELOAD_TIME, ANIME_INSERT, SHOTGUN_ANIM_INSERT_TIME);
		}else
		{
			UTIL_ShotgunReload(iShotgun, ANIME_SECONDRAY_START_RELOAD, SHOTGUN_ANIM_START_RELOAD_TIME, ANIME_SECONDARY_INSERT, SHOTGUN_ANIM_INSERT_TIME);
		}
		return HAM_SUPERCEDE;
	}

public CShotgun__PostFrame_Pre(const iShotgun)
{ 
		if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return HAM_IGNORED;

		static iPlayer; iPlayer = get_pdata_cbase( iShotgun, m_pPlayer, linux_diff_weapon);
		static iButton; iButton = pev(iPlayer, pev_button);

		if(get_pdata_int(iShotgun, m_fInReload, linux_diff_weapon) == 1)
		{	
			static iClip; iClip	= get_pdata_int(iShotgun, m_iClip, linux_diff_weapon);
			static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iShotgun, m_iPrimaryAmmoType, linux_diff_weapon);
			static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
			static j; j = min(SHOTGUN_AMMO - iClip, iAmmo);
					
			set_pdata_int(iShotgun, m_iClip, iClip + j, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
			set_pdata_int(iShotgun, m_fInReload, 0, linux_diff_weapon);
		}

		if(iButton & IN_ATTACK2 && get_pdata_float(iShotgun, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
		{
			ExecuteHamB(Ham_Weapon_SecondaryAttack, iShotgun);
			iButton &= ~IN_ATTACK2;
			set_pev(iPlayer, pev_button, iButton);
		}
		return HAM_IGNORED;
	}

public CShotgun__Holster_Post(iShotgun)
{
	if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

	static iPlayer; iPlayer = get_pdata_cbase(iShotgun, m_pPlayer, linux_diff_weapon);
	UTIL_StatusIcon(iShotgun, iPlayer, 0);

	set_pdata_float(iShotgun, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iShotgun, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iShotgun, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
	set_pdata_int(iShotgun, m_fInSpecialReload, 0, linux_diff_weapon);
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
		if(!is_user_connected(iAttacker)) return;
		
		static iShotgun; iShotgun = get_pdata_cbase(iAttacker, 373, 5);
		if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;
		flDamage *= SHOTGUN_SHOOT_DAMAGE
		SetHamParamFloat(3, flDamage);
}

public CShotgun__Idle_Pre(iShotgun)
{
	if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun) || get_pdata_float(iShotgun, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
			
	static iCharges; iCharges = get_pdata_int(iShotgun, m_iFlames, linux_diff_weapon);
	if(!iCharges)
	{
		UTIL_ShotgunIdle(iShotgun, SHOTGUN_AMMO, ANIME_IDLE, SHOTGUN_ANIM_IDLE_TIME, ANIME_AFTER_RELOAD, SHOTGUN_ANIM_AFTER_RELOAD_TIME);
	}else
	{
		UTIL_ShotgunIdle(iShotgun, SHOTGUN_AMMO, ANIME_SECONDAR_READY, SHOTGUN_ANIM_IDLE_TIME, ANIME_SECONDARY_AFTER_RELOAD, SHOTGUN_ANIM_AFTER_RELOAD_TIME);
	}
	return HAM_SUPERCEDE;
	}

public CShotgun__AddToPlayer_Post(iShotgun, iPlayer)
{
    if(IsValidEntity(iShotgun) && IsCustomShotgun(iShotgun)) UTIL_WeaponList(iPlayer, true);
    else if(!pev(iShotgun, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(iPlayer)) return;

    static iShotgun; iShotgun = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
    if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
    static i, szClassName[32], iShotgun;
    pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
	iShotgun = get_pdata_cbase(iEntity, m_rgpPlayerItems_iShotgunBox + i, linux_diff_weapon);
		
	if(IsValidEntity(iShotgun) && IsCustomShotgun(iShotgun))
	{
		engfunc(EngFunc_SetModel, iEntity, SHOTGUN_MODEL_WORLD);
		return FMRES_SUPERCEDE;
	}
    }

    return FMRES_IGNORED;
}
public CWeapon__CheckShots(iItem, iPlayer)
{
	static iCharges; iCharges = get_pdata_int(iItem, m_iFlames, linux_diff_weapon);
	static iShotsCount; iShotsCount = get_pdata_int(iItem, m_iShotsCount, linux_diff_weapon);
	if(iCharges < WEAPON_MAX_CHARGES)
	{
		if(is_user_alive(iPlayer))
		{
			iShotsCount++;
			if(iShotsCount >= WEAPON_SHOTS_COUNT)
			{
				iCharges++;
				iShotsCount = 0;

				UTIL_StatusIcon(iItem, iPlayer, 0);
				set_pdata_int(iItem, m_iFlames, iCharges, linux_diff_weapon);
				UTIL_StatusIcon(iItem, iPlayer, 1);
			}
		}

		set_pdata_int(iItem, m_iShotsCount, iShotsCount, linux_diff_weapon);
	}
}
public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
    if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
    write_byte(TE_WORLDDECAL);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_byte(random_num(41, 45));
    message_end();
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_STREAK_SPLASH);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20)); 
    write_byte(5);
    write_short(70);
    write_short(3);
    write_short(75);
    message_end();

    return FMRES_IGNORED;
}

public CMuzzleFlash__Think_Pre(const pSprite)
{
    if(pev_valid(pSprite) != 2 || !IsCustomMuzzle(pSprite)) return HAM_IGNORED;

    new Float: flFrame; pev(pSprite, pev_frame, flFrame);
    new Float: flNextThink; pev(pSprite, pev_fuser3, flNextThink);
    new iSpriteType = pev(pSprite, pev_iuser1);

    if(flFrame < get_pdata_float(pSprite, m_maxFrame, 4))
    {
    	flFrame++;

    	set_pev(pSprite, pev_frame, flFrame);
    	set_pev(pSprite, pev_nextthink, get_gametime() + flNextThink);
    	
    	return HAM_SUPERCEDE;
    }
    else if(iSpriteType)
    {
        flFrame = 0.0;
        
        set_pev(pSprite, pev_frame, flFrame);
        set_pev(pSprite, pev_nextthink, get_gametime() + flNextThink);
        
        return HAM_SUPERCEDE;
    }

    set_pev(pSprite, pev_flags, FL_KILLME);
        
    return HAM_SUPERCEDE;
}

/* ~ [ Ham Hook ] ~ */
public fm_ham_hook(bool: bEnabled)
{
    if(bEnabled)
    {
	EnableHamForward(gl_HamHook_TraceAttack[0]);
	EnableHamForward(gl_HamHook_TraceAttack[1]);
	EnableHamForward(gl_HamHook_TraceAttack[2]);
	EnableHamForward(gl_HamHook_TraceAttack[3]);
    }
    else 
    {
	DisableHamForward(gl_HamHook_TraceAttack[0]);
	DisableHamForward(gl_HamHook_TraceAttack[1]);
	DisableHamForward(gl_HamHook_TraceAttack[2]);
	DisableHamForward(gl_HamHook_TraceAttack[3]);
    }
}

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const iPlayer, const iAnim)
{
    set_pev(iPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}

stock UTIL_DropWeapon(const iPlayer, const iSlot)
{
    static iEntity, iNext, szWeaponName[32];
    iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(iEntity > 0)
    {       
	do 
	{
                iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);
		if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
		engclient_cmd(iPlayer, "drop", szWeaponName);
	} 
		
	while((iEntity = iNext) > 0);
    }
}

stock UTIL_WeaponList(const iPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
    write_string(bEnabled ? SHOTGUN_WEAPONLIST : SHOTGUN_REFERENCE);
    write_byte(iShotgunList[0]);
    write_byte(bEnabled ? SHOTGUN_AMMO : iShotgunList[1]);
    write_byte(iShotgunList[2]);
    write_byte(iShotgunList[3]);
    write_byte(iShotgunList[4]);
    write_byte(iShotgunList[5]);
    write_byte(iShotgunList[6]);
    write_byte(iShotgunList[7]);
    message_end();
}

stock UTIL_ShotgunReload(iItem, iAnimReloadStart, Float: flReloadStartDelay, iAnimReload, Float: flReloadDelay)
{
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(iClip >= SHOTGUN_AMMO) return;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);

	if(!iAmmo) return;

	if(get_pdata_float(iItem, m_flNextPrimaryAttack, linux_diff_weapon) > 0.0) return;

	static iSpecialReload; iSpecialReload = get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon);

	switch(iSpecialReload)
	{
		case 0:
		{
			UTIL_SendWeaponAnim(iPlayer, iAnimReloadStart);
			iSpecialReload = 1;
			set_pdata_float(iItem, m_flNextPrimaryAttack, flReloadStartDelay, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, flReloadStartDelay, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, flReloadStartDelay, linux_diff_weapon);
		}
		case 1:
		{
			if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return;

			UTIL_SendWeaponAnim(iPlayer, iAnimReload);
			iSpecialReload = 2;
			set_pdata_float(iItem, m_flTimeWeaponIdle, flReloadDelay, linux_diff_weapon);
		}
		case 2:
		{
			if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return;

			iSpecialReload = 1;
			set_pdata_int(iItem, m_iClip, iClip + 1, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, linux_diff_player);
		}
	}

	set_pdata_int(iItem, m_fInSpecialReload, iSpecialReload, linux_diff_weapon);
}

stock UTIL_ShotgunIdle(iItem, iMaxClip, iAnimIdle, Float: flAnimIdleTime, iAnimReloadEnd, Float: flAnimReloadEndTime)
{
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
	static iSpecialReload; iSpecialReload = get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon);
        static iItem_iClip; iItem_iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(!iItem_iClip && !iSpecialReload && iAmmo) CShotgun__Reload_Pre(iItem);

	else if(iSpecialReload)
	{
		if(iItem_iClip != iMaxClip && iAmmo) CShotgun__Reload_Pre(iItem);
		else
		{
			UTIL_SendWeaponAnim(iPlayer, iAnimReloadEnd);

			set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, flAnimReloadEndTime, linux_diff_weapon);
		}
	}
	else
	{
		UTIL_SendWeaponAnim(iPlayer, iAnimIdle);
		set_pdata_float(iItem, m_flTimeWeaponIdle, flAnimIdleTime, linux_diff_weapon);
	}
}

stock Spawn2(const iPlayer, const Float:iVec[3], const Float:vecEnd[3])
{
	static iszAllocStringCached;
	static pEntity;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}

	if (pev_valid(pEntity))
	{
		set_pev(pEntity, pev_movetype, MOVETYPE_FLYMISSILE);
		set_pev(pEntity, pev_owner, iPlayer);

		SET_MODEL(pEntity, MISSILEMODEL);
		SET_ORIGIN(pEntity, iVec);

		set_pev(pEntity, pev_classname, MISSILE_CLASSNAME);
		set_pev(pEntity, pev_solid, SOLID_TRIGGER);
		set_pev(pEntity, pev_gravity, 0.01);
		
		set_pev(pEntity, pev_scale, 0.1);

		set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
		set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
		
		Sprite_SetTransparency(pEntity, kRenderTransAdd, Float:{255.0,255.0,255.0}, 255.0);
		
		set_pev(pEntity, pev_nextthink, get_gametime() + 0.01);
		
		new Float:Velocity[3];Get_Speed_Vector(iVec, vecEnd, 2000.0, Velocity);
		set_pev(pEntity, pev_velocity, Velocity);
	}
}

stock Spawn(const iPlayer, const Float:iVec[3])
{
	static iszAllocStringCached;
	static pEntity;

	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}

	if (pev_valid(pEntity))
	{
		set_pev(pEntity, pev_movetype, MOVETYPE_TOSS);
		set_pev(pEntity, pev_owner, iPlayer);
			
		SET_MODEL(pEntity, SHARKMODEL);
		SET_ORIGIN(pEntity, iVec);

		set_pev(pEntity, pev_classname, DRAGON_CLASSNAME);
		set_pev(pEntity, pev_solid, SOLID_NOT);

		//SET_SIZE(pEntity, Float:{-100.0, -100.0, -100.0}, Float:{100.0, 100.0, 300.0});
		
		set_pev(pEntity, pev_framerate, 0.7);
		set_pev(pEntity, pev_sequence, 0);
		set_pev(pEntity, pev_animtime, get_gametime());

		set_pev(pEntity, pev_fuser2, get_gametime() + 3.0);

		set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);
	}

	static iszAllocStringCached2;
	static pEntity2;

	if (iszAllocStringCached2 || (iszAllocStringCached2 = engfunc(EngFunc_AllocString, "info_target")))
	{
		pEntity2 = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached2);
	}

	if (pev_valid(pEntity2))
	{
		set_pev(pEntity2, pev_movetype, MOVETYPE_TOSS);
		set_pev(pEntity2, pev_owner, iPlayer);

		SET_MODEL(pEntity2, WATERMODEL);
		SET_ORIGIN(pEntity2, iVec);

		set_pev(pEntity2, pev_classname, WATER_CLASSNAME);
		set_pev(pEntity2, pev_solid, SOLID_NOT);

		//SET_SIZE(pEntity, Float:{-100.0, -100.0, -100.0}, Float:{100.0, 100.0, 300.0});
		
		set_pev(pEntity2, pev_framerate, 1.0);
		set_pev(pEntity2, pev_sequence, 0);
		set_pev(pEntity2, pev_animtime, get_gametime());

		set_pev(pEntity2, pev_fuser4, get_gametime() + 3.5);

		set_pev(pEntity2, pev_nextthink, get_gametime() + 0.1);
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, iVec[0]);
	engfunc(EngFunc_WriteCoord, iVec[1] - 60.0);
	engfunc(EngFunc_WriteCoord, iVec[2] + 50.0);
	write_short(iBlood[1]);
	write_byte(10);
	write_byte(16);
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, iVec[0]);
	engfunc(EngFunc_WriteCoord, iVec[1] + 60.0);
	engfunc(EngFunc_WriteCoord, iVec[2] + 45.0);
	write_short(iBlood[1]);
	write_byte(10);
	write_byte(17);
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, iVec[0]);
	engfunc(EngFunc_WriteCoord, iVec[1] - 20.0);
	engfunc(EngFunc_WriteCoord, iVec[2] + 55.0);
	write_short(iBlood[1]);
	write_byte(10);
	write_byte(18);
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS);
	message_end();

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, iVec[0]);
	engfunc(EngFunc_WriteCoord, iVec[1] + 20.0);
	engfunc(EngFunc_WriteCoord, iVec[2] + 50.0);
	write_short(iBlood[1]);
	write_byte(10);
	write_byte(15);
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS);
	message_end();
}
stock UTIL_StatusIcon(iItem, iPlayer, iUpdateMode)
{
	new szSprite[33], iStatus;
	new iClip = get_pdata_int(iItem, m_iFlames, linux_diff_weapon);
	static iShotgun; iShotgun = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iShotgun) || !IsCustomShotgun(iShotgun)) return;

	if(iClip >= WEAPON_MAX_CHARGES || iClip > 9)
		format(szSprite, charsmax(szSprite), "number_%i", (iClip >= 9) ? 9 : WEAPON_MAX_CHARGES), iStatus = 2;
	else format(szSprite, charsmax(szSprite), "number_%d", iClip), iStatus = 1;

	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	write_byte((iUpdateMode && iClip > 0) ? iStatus : 0);
	write_string(szSprite);
	write_byte(0);
	write_byte(128);
	write_byte(192);
	message_end();
}

stock GetWeaponPosition(const iPlayer, Float: forw, Float: right, Float: up, Float: vStart[])
{
	new Float: vOrigin[3], Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
	
	pev(iPlayer, pev_origin, vOrigin);
	pev(iPlayer, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	pev(iPlayer, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: vecColor[3], const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_rendercolor, vecColor);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock Get_Speed_Vector(const Float:origin1[3], const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
}
stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz;
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock UTIL_CreateMuzzleFlash(const pPlayer, const szMuzzleSprite[], const iMuzzleLoop, const Float: flScale, const Float: flBrightness, const iAttachment, Float: flNextThink)
{
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100) return FM_NULLENT;
        
    static pSprite, iszAllocStringCached;

    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    	pSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
        
    if(pev_valid(pSprite) != 2) return FM_NULLENT;
        
    set_pev(pSprite, pev_model, szMuzzleSprite);
    set_pev(pSprite, pev_spawnflags, SF_SPRITE_ONCE);
        
    set_pev(pSprite, pev_classname, ENTITY_MUZZLE_CLASSNAME);
    set_pev(pSprite, pev_impulse, gl_iszAllocString_MuzzleKey);
    set_pev(pSprite, pev_owner, pPlayer);
    set_pev(pSprite, pev_fuser3, flNextThink);
    set_pev(pSprite, pev_iuser1, iMuzzleLoop);
    set_pev(pSprite, pev_aiment, pPlayer);
    set_pev(pSprite, pev_body, iAttachment);

    set_pev(pSprite, pev_rendermode, kRenderTransAdd);
    set_pev(pSprite, pev_renderamt, flBrightness);

    set_pev(pSprite, pev_scale, flScale);
        
    dllfunc(DLLFunc_Spawn, pSprite)

    return pSprite;
}