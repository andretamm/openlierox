/////////////////////////////////////////
//
//             OpenLieroX
//
// code under LGPL, based on JasonBs work,
// enhanced by Dark Charlie and Albert Zeyer
//
//
/////////////////////////////////////////


// Game header file
// Created 28/6/02
// Jason Boettcher


#ifndef __LIEROX_H__
#define __LIEROX_H__


#ifdef _MSC_VER
#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif // _DEBUG
#endif // _MSC_VER

#ifdef WIN32
#include <windows.h>
#endif

#if DEBUG == 1
#define		_AI_DEBUG
#endif

#define		LX_PORT			23400
#define		SPAWN_HOLESIZE	4
#ifndef		LX_VERSION
#	define		LX_VERSION		"0.57_beta3"
#endif
#define		LX_ENDWAIT		9.0f


// Game types
enum {
	GMT_DEATHMATCH,
	GMT_TEAMDEATH,
	GMT_TAG,
    GMT_DEMOLITION
};


const float	D2R(1.745329e-2f); // degrees to radians
const float	R2D(5.729578e+1f); // radians to degrees

#define DEG2RAD(a)  (a * D2R)
#define RAD2DEG(a)  (a * R2D)


// Game includes
#include "ProfileSystem.h"
#include "Networking.h"
#include "CChatBox.h"
#include "Frame.h"
#include "CViewport.h"
#include "CSimulation.h"
#include "Command.h"
#include "CWorm.h"
#include "CProjectile.h"
#include "CShootList.h"
#include "Entity.h"
#include "CWeather.h"
#include "Protocol.h"
#include "Options.h"


#include "CFont.h"
#include "Cursor.h"

// LieroX structure
class lierox_t { public:
	float	fCurTime;
	float	fDeltaTime;
	CFont	cFont;
	CFont	cOutlineFont;
	CFont	cOutlineFontGrey;

	int		iQuitGame;
	int		iQuitEngine;

	int		debug_int;
	float	debug_float;
	CVec	debug_pos;

	// Default Colours
	Uint32			clNormalLabel;
	Uint32			clHeading;
	Uint32			clSubHeading;
	Uint32			clChatText;
	Uint32			clNetworkText;
	Uint32			clNormalText;
	Uint32			clNotice;
	Uint32			clDropDownText;
	Uint32			clDisabled;
	Uint32			clListView;
	Uint32			clTextBox;
	Uint32			clMouseOver;
	Uint32			clError;
	Uint32			clCredits1;
	Uint32			clCredits2;
	Uint32			clPopupMenu;
	Uint32			clWaiting;
	Uint32			clReady;
	Uint32			clPlayerName;
	Uint32			clBoxLight;
	Uint32			clBoxDark;
	Uint32			clWinBtnBody;
	Uint32			clWinBtnLight;
	Uint32			clWinBtnDark;
	Uint32			clMPlayerTime;
	Uint32			clMPlayerSong;
	Uint32			clChatBoxBackground;
	Uint32			clDialogBackground;
	Uint32			clGameBackground;
	Uint32			clViewportSplit;
	Uint32			clScrollbarBack;
	Uint32			clScrollbarBackLight;
	Uint32			clScrollbarFront;
	Uint32			clScrollbarHighlight;
	Uint32			clScrollbarShadow;
	Uint32			clCurrentSettingsBg;
	Uint32			clScoreBackground;
	Uint32			clDialogCaption;

	Uint32			clPink;
	Uint32			clWhite;
	Uint32			clBlack;


	std::string	debug_string;
};


// Game types
enum {
	GME_LOCAL=0,
	GME_HOST,
	GME_JOIN
};



// Game structure
class game_t { public:
	int			iGameType;		// Local, remote, etc
	int			iGameMode;		// DM, team DM, etc
	std::string		sModName;
	std::string		sMapname;
    std::string        sPassword;
	std::string		sModDir;
    maprandom_t sMapRandom;
	int			iLoadingTimes;
	std::string		sServername;
	std::string		sWelcomeMessage;
	bool		bRegServer;
	bool		bTournament;

	int			iLives;
	int			iKillLimit;
	int			iTimeLimit;
	int			iTagLimit;
	int			iBonusesOn;
	int			iShowBonusName;
	
	int			iNumPlayers;
	profile_t	*cPlayers[MAX_WORMS];
};


// TODO: move this somewhere else
// Game lobby structure
class game_lobby_t { public:
	int		nSet;
	int		nGameMode;
	int		nLives;
	int		nMaxWorms;
	int		nMaxKills;
	int		nLoadingTime;
	int		nBonuses;
	std::string	szMapName;
	std::string	szDecodedMapName;
	std::string	szModName;
	std::string	szModDir;
	bool	bHaveMap;
	bool	bHaveMod;
	bool	bTournament;
};



extern	lierox_t		*tLX;
extern	game_t			tGameInfo;
extern	CVec			vGravity;
extern  CInput			cTakeScreenshot;
extern  CInput			cSwitchMode;
extern  int				nDisableSound;
extern	bool			bActivated;
#ifdef WITH_MEDIAPLAYER
extern	CInput			cToggleMediaPlayer;
#endif



// Main Routines
void    ParseArguments(int argc, char *argv[]);
int		InitializeLieroX(void);
void	StartGame(void);
void	ShutdownLieroX(void);
void	GameLoop(void);
void	QuittoMenu(void);
void	GotoLocalGameMenu(void);



// Miscellanous routines
float	GetFixedRandomNum(uchar index);
int		CheckCollision(CVec trg, CVec pos, uchar checkflags, CMap *map);
void	ConvertTime(float time, int *hours, int *minutes, int *seconds);
int 	CarveHole(CMap *cMap, CVec pos);
bool    MouseInRect(int x, int y, int w, int h);






void printf(const std::string& txt);


// TODO: remove this from here
void	xmlEntities(std::string& text);




// Thread functions
#ifdef WIN32
void	nameThread(const DWORD threadId, const char *name);
#endif


#endif  //  __LIEROX_H__
