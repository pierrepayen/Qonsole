; Tested On AutoHotkey Version: 1.1.23.01
	
	;///////////////////////// [ XP Patch ] /////////////////////////
	if A_OSVersion in WIN_2003,WIN_XP,WIN_2000,WIN_NT4,WIN_95,WIN_98,WIN_ME  ; Note: No spaces around commas.
		XPMode:=1
	else
		XPMode:=0
	;///////////////////////// [ XP Patch ] /////////////////////////
	
	#Include LibCon-minXP.ahk
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	#Warn, LocalSameAsGlobal, off
	#SingleInstance, Force
	
	SetWinDelay, -1
	SetBatchLines, -1
	DetectHiddenWindows, On
	SetWorkingDir %A_ScriptDir%
	OnExit,Quit
	
	;///////////////////////// [ XP Patch ] /////////////////////////
	if (XPMode) {
			;if (A_Is64bitOS && (A_PtrSize==8)) {
			;	FileInstall,dll\bin\SizeCon_x64.dll,SizeCon_x64.dll
			;}
			;else
			;{
				FileInstall,dll\bin\SizeCon.dll,SizeCon.dll
			;}
		loadSizeCon()
	}
	;///////////////////////// [ XP Patch ] /////////////////////////
	
	LibConDebug := 1
	autoexecute_thread :=1
	configfile:=SubStr(A_ScriptName,1,-4) "_settings.ini"
	Default_CMD_Width:=Round((A_ScreenWidth*0.75)/8)
	WelcomeFirstTime:=!FileExist(configFile)
	self_pid:=DllCall("GetCurrentProcessId")
	lastactive:="ahk_ID " WinExist("A","","ahk_pid " self_pid)
	CheckUpdate_hide:=0
	
;<<<<<<<<  HEADER END  >>>>>>>>>

;###################[ Settings ]#####################

	IniRead,Speed,%configfile%,Animation,Speed,1 ;speed:=1
	IniRead,Delay,%configfile%,Animation,Delay,20 ;Delay:=20
	IniRead,dx,%configfile%,Animation,dx,25 ;dx:=25
		quitOnInActive:=0
	IniRead,HideOnInActive,%configfile%,Settings,HideOnInActive,0 ;HideOnInActive:=0
	IniRead,HorizontallyCentered,%configfile%,Settings,HorizontallyCentered,0 ;HorizontallyCentered:=0
	IniRead,BottomPlaced,%configfile%,Settings,BottomPlaced,0 ;BottomPlaced:=0
	;IniRead,ShowDebugMenu,%configfile%,Settings,ShowDebugMenu,0 ;ShowDebugMenu:=0
	IniRead,AnimationDisabled,%configfile%,Animation,AnimationDisabled,0 ;AnimationDisabled:=0
	IniRead,CmdPaste,%configfile%,Settings,CmdPaste,1 ;CmdPaste:=1
	IniRead,RunOnStartUp,%configfile%,Settings,RunOnStartUp,0 ;RunOnStartUp:=0
	IniRead,AutoWinActivate,%configfile%,Settings,AutoWinActivate,1 ;AutoWinActivate:=1
	IniRead,ReduceMemory,%configfile%,Settings,ReduceMemory,1 ;ReduceMemory:=1
		chkActiveDelay:=100
	IniRead,Console_Mode,%configfile%,Settings,Console_Mode,0 ;Console_2_Mode:=0
	;IniRead,Console_2_Mode,%configfile%,Settings,Console_2_Mode,0 ;Console_2_Mode:=0
	IniRead,TransparencyPercent,%configfile%,Settings,TransparencyPercent,20 ;TransparencyPercent:=20
	IniRead,CMD_Path,%configfile%,Settings,CMD_Path,%A_scriptDir%\cmd_Qonsole.lnk ;CMD_Path:="cmd_tcon.lnk" ;%comspec% ;Quotes!!!
	IniRead,Console_2_path,%configfile%,Settings,Console_2_path,%A_scriptDir%\Console.exe ;Console_2_path:="bin\Console.exe"
	IniRead,Mintty_path,%configfile%,Settings,Mintty_path,%A_scriptDir%\mintty.exe
	IniRead,GitBash_path,%configfile%,Settings,GitBash_path,%A_scriptDir%\git-cmd.exe	
	IniRead,OpenHotkey,%configfile%,Settings,OpenHotkey,#c
		Hotkey,%OpenHotkey%,OpenHotkey,On
	IniRead,CMD_Width,%configfile%,Settings,CMD_Width, % (Default_CMD_Width*8)
	IniRead,CMD_Height,%configfile%,Settings,CMD_Height,266
	IniRead,CMD_StartUpArgs,%configfile%,Settings,CMD_StartUpArgs,%A_space%
	IniRead,GuiBGDarken_Increment,%configfile%,Animation,GuiBGDarken_Increment,6
	
	;///////////////////////// [ XP Patch ] /////////////////////////
	if (XPMode)
		IniRead,GuiBGDarken_Max,%configfile%,Animation,GuiBGDarken_Max,255
	else
		IniRead,GuiBGDarken_Max,%configfile%,Animation,GuiBGDarken_Max,128
	;///////////////////////// [ XP Patch ] /////////////////////////
	
	IniRead,GuiBGDarken_Color,%configfile%,Animation,GuiBGDarken_Color,0x1A1A1A

;####################################################
AppName:="Qonsole"
Version:="1.4.0"
App_date:="2016/02/17"
Update_URL:="http://qonsole-ahk.sourceforge.net/update.ini"
Project_URL:="http://qonsole-ahk.sourceforge.net"

MsgBox_AlwaysOnTop:=262144
Console_2_Mode:=InStr(Console_Mode,"Console2")
Console_Mode:=SubStr(Console_Mode,1,8)

if (GuiBGDarken_Max) ;if not equal zero, then create it
	gosub Create_GuiBGDarken

if (A_IsCompiled)
	Menu,tray,Icon,%A_scriptFullPath%,1

if (!A_IsCompiled || ShowDebugMenu)
	menu,tray,Standard
else
	menu,tray,NoStandard

Menu,tray,Tip,%AppName% v%Version%
menu,tray,add,Show/Hide Console,OpenHotkey
menu,tray,Default,Show/Hide Console
menu,tray,add,Settings,prog_settings
menu,tray,add ;----------------------
menu,tray,add,Check for update,Check4Update
menu,tray,add,Project Webpage,OpenProjectWebpage
menu,tray,add,About,About_prog
menu,tray,add ;----------------------
menu,tray,add,Reload
menu,tray,add,Quit

Menu, Tray, Click, 1 ;single click instead of double click for default tray icon action

;if (Console_2_Mode)
;	con=ahk_class Console_2_Main
;else
;	con=ahk_class ConsoleWindowClass

Speed:=(Speed<1)?1:Speed
anim:=0 ;Dont touch, Enables the principle (similar) of jQuery stop()
open:=0
cShown:=0
cmd_w_offset:=0
cPID:=0
Check4Update_hidden_fail:=1
GroupAdd,Console_Classes,ahk_class ConsoleWindowClass  ;for cmd or git-cmd.exe
GroupAdd,Console_Classes,ahk_class Console_2_Main
GroupAdd,Console_Classes,ahk_class mintty ;for mintty and git-bash.exe

if (CmdPaste) {
	Hotkey, IfWinActive, ahk_group Console_Classes
	Hotkey,^v,PasteHotkey
	Hotkey, IfWinActive
}

if (WelcomeFirstTime) {
	gosub About_prog
	MsgBox, % (64+MsgBox_AlwaysOnTop), %AppName% - Version %Version%, Welcome!`nSee the tray icon/menu in the notifications area.
}

gosub,Check4Update_hidden ;check update on startup
SetTimer,Check4Update_hidden,-300000 ;wait 5 mins till autocheck of update, in case of failure

setAutorun(RunOnStartUp)

;Reduce Memory Usage
SetTimer,cleanself,-1

return ;End of Auto-execute

OpenProjectWebpage:
	Run, %Project_URL%
return

Check4Update:
	tempupdatefile=%A_temp%\%AppName%_update%A_now%%A_MSec%%A_TickCount%.tmp
	URLDownloadToFile,%Update_URL%,%tempupdatefile%
	IniRead,NewVersion,%tempupdatefile%,Update,Version,NULL (Error)
	IniRead,__URL,%tempupdatefile%,Update,URL
	FileDelete,%tempupdatefile%
	if (InStr(NewVersion,"NULL") || InStr(NewVersion,"Error"))
	{
		if (CheckUpdate_hide)
			Check4Update_hidden_fail:=1
		else
			MsgBox, 262192, %AppName% - Update, An error occured.`nPlease check your internet connection and try again.
	}
	else
	{
		if (NewVersion > Version)
		{
			if (CheckUpdate_hide)
			{
				Check4Update_hidden_fail:=0
				menu,tray,Rename,Check for update,Update available...
				Menu,Tray,Tip,%AppName% v%Version%`nUpdate available...
			}
			else
			{
				MsgBox, 262212, %AppName% - Update, A new version is available.`nCurrent Version: `t%Version%`nLatest Version: `t%NewVersion%`nWould you like to update?
				IfMsgBox, Yes
					run, %__URL%
			}
		}
		else
		{
			if (CheckUpdate_hide)
				Check4Update_hidden_fail:=0
			else
				MsgBox, 262208, %AppName% - Update, You have the latest version.
		}
	}
return

Check4Update_hidden:
	if (Check4Update_hidden_fail)
	{
		CheckUpdate_hide:=1
		gosub, Check4Update
		CheckUpdate_hide:=0
	}
return

OpenHotkey:
	if (quitOnInActive)
		gosub CloseC
	
	; Settimer allows Multi-threading, gosub does not.
	;   This allows the program to catch the open/close
	;   even during the animation.
	SetTimer,HideC,Off       ; Turn off all ("settimer") Threads
		SetTimer,showC,Off
		;SetTimer,FadeBG,Off
		;if (!autoexecute_thread)
		;SetTimer,FadeBG,-1   ; And run sub-routine anew
		SetTimer,showC,-1    ;gosub showC
		autoexecute_thread:=0
	
	if (HideOnInActive)
		SetTimer,chkActive,%chkActiveDelay%
return

PasteHotkey:
if (Console_2_Mode) {
	KeyWait, Ctrl, Up
	MouseClick, M ;default config
}
IfWinActive, ahk_class ConsoleWindowClass
{
	SendInput {Raw}%clipboard% ; ConsolePaste
}
return

/*
~Esc::
	if (quitOnInActive)
		gosub closeC
	else
		gosub HideC
return
*/

showC:
	if (!WinExist(con)) {
		open:=0
		cShown:=0
		cPID:=0
	}
	if (cShown)
		goto HideC
	if (!cShown) ;&& (open)
		WinShow,%con%
	WinActivate,%con%
	if ((!open) or (!WinExist(con))) and (!cPID) {
		;MsgBox new con - not exist: %con% - o: %open%
		if (Console_2_Mode) {
			con=ahk_class Console_2_Main
			if (!FileExist(Console_2_path))
			{
				MsgBox, 52, Qonsole Error, Console2 was not found.`nBrowse For Console2? (Console.exe)
				IfMsgBox, Yes
				{
					Console_2_pathS:=BrowseForConsole("Console2")
					IniWrite,%Console_2_pathS%,%configFile%,Settings,Console_2_path
					MsgBox, 48, Qonsole Error,The program will now restart.
					gosub reload
					
				}
				IfMsgBox, No
				{
					MsgBox, 48, Qonsole Error, Cmd Mode will be used.`nThe program will now restart.
					IniWrite,0,%configFile%,Settings,Console_Mode
					gosub reload
				}
			}
			chk_console_setupfile:
			SplitPath,Console_2_Path,,Console_2_Dir
			console_setupfile:=Console_2_Dir . "\Qonsole.xml"
			if (!FileExist(console_setupfile))
			{
				write_console_setup(console_setupfile)
				MsgBox, 64, Qonsole - Notice, Qonsole has created a configuration file:`n"%console_setupfile%"
				goto chk_console_setupfile
			}
			run,"%Console_2_path%" -c "%console_setupfile%" %CMD_StartUpArgs%,,,cPID
			;conP=ahk_pid %cPID%
			;WinWait,%con% ;buggy?
			DetectHiddenWindows,Off
			WinWaitActive,ahk_pid %cPID%
			WinWaitActive,%con%
			DetectHiddenWindows,On
			;Sleep 500
				;doesnt work ;WinSet, Transparent, % (abs(100-TransparencyPercent)/100)*255 , %con%
				Winset, AlwaysOnTop, On, %con%
			cmd_height__:=(-cmd_height)
			WinMove,ahk_pid %cPID%,,,%cmd_height__%,%cmd_width%,%cmd_height%
			WinMove,%con%,,,%cmd_height__%,%cmd_width%,%cmd_height%
			WinGetPos,,,cw_w,ch,%con%
			WinGet,hc,ID,%con%
			con=ahk_id %hc%
			;WindowDesign(hc)
				WinSet, Transparent, % (abs(100-TransparencyPercent)/100)*255 , %con%
				;Winset, AlwaysOnTop, On, %con%
			cmd_w_fix:=cw_w
			CMD_Height-=10
		} else if (InStr(Console_Mode,"mintty")) {
			con=ahk_class mintty
			if (!FileExist(mintty_path))
			{
				MsgBox, 52, Qonsole Error, mintty was not found.`nBrowse For mintty? (mintty.exe)
				IfMsgBox, Yes
				{
					mintty_pathS:=BrowseForConsole("mintty")
					IniWrite,%mintty_pathS%,%configFile%,Settings,mintty_path
					MsgBox, 48, Qonsole Error,The program will now restart.
					gosub reload
					
				}
				IfMsgBox, No
				{
					MsgBox, 48, Qonsole Error, Cmd Mode will be used.`nThe program will now restart.
					IniWrite,0,%configFile%,Settings,Console_Mode
					gosub reload
				}
			}
			run,"%mintty_path%" %CMD_StartUpArgs%,,,cPID
			WinWait,%con%
			DetectHiddenWindows,Off
			WinWaitActive,ahk_pid %cPID%
			WinWaitActive,%con%
			DetectHiddenWindows,On
				Winset, AlwaysOnTop, On, %con%
			cmd_height__:=(-cmd_height)
			
			; hide window border
			WinSet, Style, -0x40000, %con%
			WinSet, Style, -0x80000, %con%
			WinSet, Style, -0x200000, %con%
			WinSet, Style, -0xC00000, %con%
			WinSet, Style, -0x800000, %con%
			WinSet, Style, -0x400000, %con%
			
			WinMove,ahk_pid %cPID%,,,%cmd_height__%,%cmd_width%,% cmd_height+0
			WinMove,%con%,,,%cmd_height__%,%cmd_width%, % cmd_height+0
			WinGetPos,,,cw_w,ch,%con%
			WinGet,hc,ID,%con%
			con=ahk_id %hc%
			cmd_w_fix:=cw_w
			WinMove,%con%,,,,, % (ch-=14)
			CMD_Height-=14
			
		} else if (InStr(Console_Mode,"GitBash")) {
			con=ahk_class mintty
			if (!FileExist(GitBash_path))
			{
				MsgBox, 52, Qonsole Error, GitBash was not found.`nBrowse For GitBash? (mintty.exe)
				IfMsgBox, Yes
				{
					GitBash_pathS:=BrowseForConsole("GitBash")
					IniWrite,%GitBash_pathS%,%configFile%,Settings,GitBash_path
					MsgBox, 48, Qonsole Error,The program will now restart.
					gosub reload
					
				}
				IfMsgBox, No
				{
					MsgBox, 48, Qonsole Error, Cmd Mode will be used.`nThe program will now restart.
					IniWrite,0,%configFile%,Settings,Console_Mode
					gosub reload
				}
			}
			run,"%GitBash_path%" %CMD_StartUpArgs%,,,cPID
			WinWait,%con%
			DetectHiddenWindows,Off
			WinWaitActive,ahk_pid %cPID%
			WinWaitActive,%con%
			DetectHiddenWindows,On
				Winset, AlwaysOnTop, On, %con%
			cmd_height__:=(-cmd_height)
			
			; hide window border
			WinSet, Style, -0x40000, %con%
			WinSet, Style, -0x80000, %con%
			WinSet, Style, -0x200000, %con%
			WinSet, Style, -0xC00000, %con%
			WinSet, Style, -0x800000, %con%
			WinSet, Style, -0x400000, %con%
			
			WinMove,ahk_pid %cPID%,,,%cmd_height__%,%cmd_width%,% cmd_height+0
			WinMove,%con%,,,%cmd_height__%,%cmd_width%, % cmd_height+0
			WinGetPos,,,cw_w,ch,%con%
			WinGet,hc,ID,%con%
			con=ahk_id %hc%
			cmd_w_fix:=cw_w
			WinMove,%con%,,,,, % (ch-=14)
			
		} else { ;Cmd mode (Quake mode?? >> Quahke)
			con=ahk_class ConsoleWindowClass
			chk_CMD_Path:
			if (!FileExist(CMD_Path))
			{
				if (WelcomeFirstTime)
					MsgBox, 64, Qonsole - Version %Version%, The is no Cmd path currently set.`nQonsole will set it up for you.
				else
					MsgBox, 64, Qonsole Error, The Cmd path is Invalid.`nQonsole will set it up for you.
				/*
				if (WelcomeFirstTime)
					MsgBox, 52, Qonsole - Version %Version%, The is no Cmd path currently set.`nLet Qonsole set it up for you?
				else
					MsgBox, 52, Qonsole Error, The Cmd path is Invalid.`nLet Qonsole set it up for you?
				IfMsgBox, Yes
				{
				*/
					CMD_Path=%A_scriptDir%\cmd_Qonsole.lnk
					FileCreateShortcut,%comspec%,%CMD_Path%
					IniWrite,%CMD_Path%,%configFile%,Settings,CMD_Path
					MsgBox, 64, Qonsole - Notice, Qonsole has created a configuration file:`n"%CMD_Path%"
					goto chk_CMD_Path
				/*
				}
				IfMsgBox, No
				{
					MsgBox, 52, Qonsole Error, The Cmd path is Invalid.`nBrowse For Cmd?
					IfMsgBox, Yes
					{
						CMD_PathS:=BrowseForConsole("Cmd")
						IniWrite,%CMD_PathS%,%configFile%,Settings,CMD_Path
						MsgBox, 48, Qonsole Error,The program will now restart.
						gosub reload
					}
					IfMsgBox, No
					{
						MsgBox, 48, Qonsole Error, `%comspec`% Mode will be used.`nThe program will now restart.
						;IniWrite,0,%configFile%,Settings,Console_2_Mode
						IniWrite,%comspec%,%configFile%,Settings,CMD_Path
						gosub reload
					}
				}
				*/
			}
			run,"%CMD_Path%" %CMD_StartUpArgs%,,,cPID
			conP=ahk_pid %cPID%
			WinWait,%conP%,,1
			conP:=""
			if (ErrorLevel) or (cPID="")
			WinGet,cPID,PID,%con%
			con=ahk_pid %cPID%
			WinGetPos,,,,ch,%con%
			offset:=Mod(ch,speed)-ch + speed
			WinMove,%con%,,0,%offset%
			;conP=ahk_pid %cPID%
			WinGet,hc,ID,%con%
			con=ahk_id %hc%
			ITaskbarList(hc,5) ;delete from taskbar
			AttachConsole(cPID)
			hs:=getStdoutHandle()
			cmd_int_fwidth:=getFontWidth()
			setconsoleSize(cmd_w_int:=(CMD_Width//cmd_int_fwidth),getConsoleHeight())
			cmd_w_fix:=(cmd_w_int*cmd_int_fwidth)
			winW:=CMD_Width+50
			SysGet,tbarH__,4
			WinMove,%con%,,,,%winW%,(CMD_Height+tbarH__)
			WindowDesign(hc)
			
			
			;///////////////////////// [ XP Patch ] /////////////////////////
			if (XPMode) {
				wingetpos,,,w_width,w_height, ahk_id %hc%
				__www:=(w_width-6)-23 ;(RectX)
				__wwh:=(w_height-32)-4 ;(RectY)+fh
				__wwzh:=(tbarH__)+4 ;(32+4)
			}
			;///////////////////////// [ XP Patch ] /////////////////////////
			
			
			FreeConsole()
			WinGetPos,,,cw_w,ch,%con%
			ch:=ch+2
		}
		lastactive:="ahk_ID " WinExist("A")
		offset:=Mod(ch,speed)-ch + speed
		WinSet,AlwaysOnTop,On,ahk_id %hGuiBGDarken%
		WinActivate,ahk_id %hGuiBGDarken%
		WinSet,AlwaysOnTop,On,%con%
		WinActivate,%con%
		
		_tx:=((HorizontallyCentered) ? ((cmd_w_fix<A_ScreenWidth) ? abs((A_ScreenWidth-cmd_w_fix)/2) : 0) : 0) +((Console_2_Mode) ? 0 : -2)
		_ty:=((BottomPlaced) ? ((CMD_Height<A_ScreenHeight) ? abs(A_ScreenHeight-CMD_Height) : 0) : ((Console_2_Mode) ? 0 : -2))
		WinMove,%con%,,_tx, _ty
		
		;///////////////////////// [ XP Patch ] /////////////////////////
		if (XPMode) {
			cmd_w_fix:=__www
			offset:=offset-(__wwzh) ;;?? this line does nothing???
			
			;winfade("ahk_id " hGuiBGDarken,GuiBGDarken_Max,GuiBGDarken_Increment) ;fade in

			__wwwwvar:=(Console_2_Mode) ? 0 : -2
			__wwwwvar:=(__wwwwvar)-(__wwzh)
			if (BottomPlaced)
				WinSlideUpExp(Con,Delay,speed,A_ScreenHeight-CMD_Height,dx)
			else
				WinSlideDownExp(Con,Delay,speed, __wwwwvar,dx)
			;WinSlideDown(Con,speed,Delay,(0+(Console_2_Mode) ? 0 : -2) )		}
		}
		else
		{
			if (InStr(Console_Mode,"Mintty"||"GitBash"))
				WinSet, Transparent, % (abs(100-TransparencyPercent)/100)*255 , %con%

			winfade("ahk_id " hGuiBGDarken,GuiBGDarken_Max,GuiBGDarken_Increment) ;fade in
			if (BottomPlaced)
				WinSlideUpExp(Con,Delay,speed,A_ScreenHeight-CMD_Height,dx)
			else
				WinSlideDownExp(Con,Delay,speed, (0+(Console_2_Mode) ? 0 : -2),dx)
			;WinSlideDown(Con,speed,Delay,(0+(Console_2_Mode) ? 0 : -2) )
		}
		;///////////////////////// [ XP Patch ] /////////////////////////
		
		open:=1
	}
	else 
	{
		;while(anim) {
			;do nothing, wait till current animation finishes...
		;}
		lastactive:="ahk_ID " WinExist("A")
		WinSet,AlwaysOnTop,On,ahk_id %hGuiBGDarken%
		WinActivate,ahk_id %hGuiBGDarken%
		WinSet,AlwaysOnTop,On,%con%
		WinActivate,%con%
		
		_tx:=((HorizontallyCentered) ? ((cmd_w_fix<A_ScreenWidth) ? abs((A_ScreenWidth-cmd_w_fix)/2) : 0) : 0) +((Console_2_Mode) ? 0 : -2)
		_ty:=((BottomPlaced) ? ((CMD_Height<A_ScreenHeight) ? abs(A_ScreenHeight-CMD_Height) : 0) : ((Console_2_Mode) ? 0 : -2))
		WinMove,%con%,,_tx, ;_ty
		
		;///////////////////////// [ XP Patch ] /////////////////////////
		if (XPMode) {
			__wwwwvar:=(Console_2_Mode) ? 0 : -2
			__wwwwvar:=(__wwwwvar)-(__wwzh)
			;winfade("ahk_id " hGuiBGDarken,GuiBGDarken_Max,GuiBGDarken_Increment) ;fade in
			if (BottomPlaced)
				WinSlideUpExp(Con,Delay,speed,A_ScreenHeight-CMD_Height,dx)
			else
				WinSlideDownExp(Con,Delay,speed, __wwwwvar,dx)
		}
		else
		{
			if (InStr(Console_Mode,"Mintty"||GitBash)) {
				WinSet, Transparent, % (abs(100-TransparencyPercent)/100)*255 , %con%
				WinSet, Style, -0x40000, %con%
			}

			winfade("ahk_id " hGuiBGDarken,GuiBGDarken_Max,GuiBGDarken_Increment) ;fade in
			;gosub FadeBG
			
			;when qonsole is at the bottom, the action to hide it is the same as to show it when we're at the top, which is to slide it upward
			if (BottomPlaced)
				WinSlideUpExp(Con,Delay,speed,A_ScreenHeight-CMD_Height,dx)
			else
				WinSlideDownExp(Con,Delay,speed, (0+(Console_2_Mode) ? 0 : -2),dx)
		}
		;///////////////////////// [ XP Patch ] /////////////////////////
	}
	cShown:=1
	SetTimer,cleanself,-1
return

HideC:
	if (cShown) {
		
		/* completely disabled for now
		if (AutoWinActivate) {
			;WinActivate,%lastactive%
			WinGet, All_WindowList, List, , , %con%
			WinGet, All_WindowList_Count, Count, , , %con%
			
			Loop % All_WindowList_Count
			{
				index := A_index+1
				All_WindowList_id := All_WindowList%index%
				WinGet, All_WindowList_state, MinMax, ahk_id %All_WindowList_id%
				if (All_WindowList_state!=-1) {
					WinActivate, ahk_id %All_WindowList_id%
					break
				}
			}
		}
		*/
		
		;when qonsole is at the bottom, the action to hide it is the same as to show it when we're at the top, which is to slide it upward
		if (BottomPlaced)
			WinSlideDownExp(Con,Delay,speed,A_ScreenHeight,dx)
		else
			WinSlideUpExp(Con,Delay,speed,offset,dx)
		;WinSlideUp(Con,speed,Delay,offset)
		WinHide,%con%
		
		;///////////////////////// [ XP Patch ] /////////////////////////
		if (XPMode) {
			winfade("ahk_id " hGuiBGDarken,0,GuiBGDarken_Increment) ;fade out
		}
		else
		{
			winfade("ahk_id " hGuiBGDarken,0,GuiBGDarken_Increment) ;fade out
			;gosub FadeBG
		}
		;///////////////////////// [ XP Patch ] /////////////////////////
		
		cShown:=0
	}
	SetTimer,cleanself,-1
return

/*
FadeBG:
if (!cShown)
{
	winfade("ahk_id " hGuiBGDarken,GuiBGDarken_Max,GuiBGDarken_Increment)
	;MsgBox Fade IN
}
else
{
	winfade("ahk_id " hGuiBGDarken,0,GuiBGDarken_Increment)
	;MsgBox Fade OUT
}
return
*/

;{ [gui and other]
;######################################################

Create_GuiBGDarken:
;///////////////////////// [ XP Patch ] /////////////////////////
if (!XPMode) {
	Gui GuiBGDarken: Color, %GuiBGDarken_Color%
	Gui GuiBGDarken: +E0x20 -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndhGuiBGDarken
	WinSet, Transparent, 0
	Gui GuiBGDarken:Show, x0 y0 w%A_screenwidth% h%A_screenHeight%,Qonsole_GuiBGDarken
}
;///////////////////////// [ XP Patch ] /////////////////////////
return

GuiBGDarkenguiescape:
GuiBGDarkenguiclose:
return

winfade(w:="",t:=128,i:=1,d:=10) {
    w:=(w="")?("ahk_id " WinActive("A")):w
    t:=(t>255)?255:(t<0)?0:t
    WinGet,s,Transparent,%w%
    s:=(s="")?255:s ;prevent trans unset bug
    WinSet,Transparent,%s%,%w% 
    i:=(s<t)?abs(i):-1*abs(i)
    while(k:=(i<0)?(s>t):(s<t)&&WinExist(w)) {
        WinGet,s,Transparent,%w%
        s+=i
        WinSet,Transparent,%s%,%w%
        sleep %d%
    }
}

/* exit hotstring handling - No Longer needed.
#IfWinActive, ahk_group Console_Classes
::exit::
	SendInput, exit{Enter}
	if WinExist("ahk_pid " cPID)
	{
		Process, WaitClose, %cPID%, %chkActiveDelay%
		gosub, CloseC
	}
return
*/
/*
::ver::
	KeyWait,Enter,U
	if WinExist("ahk_pid " cPID)
	{
		AttachConsole(cPID)
		SendInput,ver{Enter}
		print("`nQonsole [version " . Version . "]")
		FreeConsole()
	}
return
*/
#IfWinActive

;~LButton::
chkActive:
if (HideOnInActive) {
	if !WinActive(con)
	{
		lastactive:="ahk_ID " WinExist("A")
		
		if (quitOnInActive)
			gosub CloseC
		else
		{
			gosub HideC
		}
		SetTimer,chkActive,Off
	}
}
return

CloseC:
	WinKill,%con%
	WinSet,Transparent,0,ahk_id %hGuiBGDarken%
	open:=0
	SetTimer,cleanself,-1
return

Reload:
	gosub, CloseC
	Reload
return

Quit:
	gosub CloseC
	ExitApp
return

show_settings:
	show_settings_btn_clicked:=1
	if (Console_2_Mode) {
		if (!cShown)
			gosub, OpenHotkey
		a_keyD:=A_KeyDelay
		a_CtrlD:=A_ControlDelay
		SetKeyDelay, -1
		SetControlDelay, -1
		ControlClick,Console_2_View1,%con%,,RIGHT,,
		ControlSend,,es,%con%
		SetKeyDelay, %a_keyD%
		SetControlDelay, %a_CtrlD%
		WinWaitActive,Console Settings
		WinWaitClose,Console Settings
	}
	else if (InStr(Console_Mode,"mintty"||"GitBash")) {
		if (!cShown)
			gosub, OpenHotkey
		a_keyD:=A_KeyDelay
		a_CtrlD:=A_ControlDelay
		SetKeyDelay, -1
		SetControlDelay, -1
		ControlClick, ,%con%,,RIGHT,,
		ControlSend,,O,%con%
		SetKeyDelay, %a_keyD%
		SetControlDelay, %a_CtrlD%
		WinWaitActive,ahk_class ConfigBox
		WinWaitClose,ahk_class ConfigBox
	}
	else
		show_properties(CMD_Path)
return

prog_settings:
	if (!prog_settings) {
		show_settings_btn_clicked:=0
		GuiSave_btn_clicked:=0
		CMD_PathS:=CMD_Path
		Console_2_pathS:=Console_2_path
		;Gui, +AlwaysOnTop
		Gui, Add, Tab, x0 y-1 w290 h235 , Consoles|Graphics|Others
		;Tab Consoles
		;----------- Consoles settings -----------------;
		Gui, Tab, Consoles
			;----------- HotKey -----------------;
			if (InStr(OpenHotkey,"#"))
			{
				WinKey:=1
				Gui, Add, CheckBox,x5 y29 w90 h20 checked vWinKey, Windows... +
			}
			else
			{
				WinKey:=0
				Gui, Add, CheckBox, x5 y29 w90 h20 vWinKey, Windows... +
			}
			StringReplace,OpenHotkeyX,OpenHotkey,#,,All
			Gui, Add, Hotkey,	xp+90 yp w40 h20 vOpenHotkey, %OpenHotkeyX%
			Gui, Add, Button, xp+75 yp w101 h20 gshow_settings, Consoles settings

			Gui, Add, Text, x5 y57 w100 h20 , Start Up arguments
			Gui, Add, Edit, xp+95 yp-4 w170 h22 +Center vCMD_StartUpArgs hwndhEditCMD_StartUpArgs,%CMD_StartUpArgs%
					;----------- Consoles paths -----------------;
			Gui, Add, GroupBox, x5 y79 w110 h110 , Paths settings
				Gui, Add, Text,   xp+5 yp+20 w50 h20 , cmd
				Gui, Add, Text,   xp yp+20 wp hp , Console2
				Gui, Add, Text,   xp yp+20 wp hp , Mintty
				Gui, Add, Text,   xp yp+20 wp hp , Git Bash
				Gui, Add, Button, xp+50 y97 wp hp gButtonCMD, Browse
				Gui, Add, Button, xp yp+20 wp hp gButtonConsole2, Browse
				Gui, Add, Button, xp yp+20 wp hp gButtonMintty, Browse
				Gui, Add, Button, xp yp+20 wp hp gButtonGitBash, Browse


			Gui, Add, Text, x119 y99 w80 h20 , Console mode
			Gui, Add, DropDownList, xp+75 yp-3 w60 hp +r4 vDDmode, cmd|console2|mintty|GitBash

		;----------- Graphics/Animation settings -----------------;
		Gui, Tab, Graphics
			;----------- Qonsoles graphics settings -----------------;
			Gui, Add, GroupBox, x5 y20 w145 h110 , Qonsole settings	
				Gui, Add, Text, x10 y40 w90 h20  , Transparency `%
				Gui, Add, Text, xp yp+20 w90 h20 , Width   (in px)
				Gui, Add, Text, xp yp+20 w90 h20 , Height  (in px)

				Gui, Add, Edit, xp+80 y37 w50 h18 ;, 20
				;///////////////////////// [ XP Patch ] /////////////////////////
				if (XPMode)
					Gui, Add, UpDown, vUTransparencyPercent Disabled, %TransparencyPercent%
				else
					Gui, Add, UpDown, vUTransparencyPercent, %TransparencyPercent%
				Gui, Add, Edit, xp yp+21 w50 hp ;, 1024
				UCMD_Width_max:=(A_ScreenWidth+8)
				Gui, Add, UpDown, vUCMD_Width Range24-%UCMD_Width_max%, %CMD_Width%
				Gui, Add, Edit, xp yp+21 w50 hp ;, 266
				UCMD_Height_max:=(A_screenHeight+8)
				Gui, Add, UpDown, vUCMD_Height Range24-%UCMD_Height_max%, %CMD_Height%

				if(HorizontallyCentered)
					Gui, Add, CheckBox, x10 yp+25 w70 h20 checked vHorizontallyCentered, Centered 
				else
					Gui, Add, CheckBox, x10 yp+25 w70 h20 vHorizontallyCentered, Centered
				if(BottomPlaced)
					Gui, Add, CheckBox, xp+80 yp w50 hp checked vBottomPlaced, Bottom 
				else
					Gui, Add, CheckBox, xp+80 yp w50 hp vBottomPlaced, Bottom
			;----------- Animation settings -----------------; 
			Gui, Add, GroupBox, x160 y20 w120 h110 , Animation settings
				Gui, Add, Text, x170 y40 w50 h20 , Speed
				Gui, Add, Text, xp yp+20 wp hp , Delay
				Gui, Add, Text, xp yp+20 wp hp , dx

				Gui, Add, Edit, xp+50 y38 wp h18 ;, 1
				Gui, Add, UpDown, vUspeed Range1-100, %speed%
				Gui, Add, Edit, xp yp+21 wp hp ;, 20
				Gui, Add, UpDown, vUdelay Range0-1000, %delay%
				Gui, Add, Edit, xp yp+21 wp hp; , 25
				Gui, Add, UpDown, vUdx Range0-100, %dx%
				if(AnimationDisabled)
					Gui, Add, CheckBox, x165 yp+25 w100 hp checked vAnimationDisabled, Disable animation
				else
					Gui, Add, CheckBox, x165 yp+25 w100 hp vAnimationDisabled, Disable animation			
					;----------- Background settings -----------------;
			if (!XPMode){
				Gui, Add, GroupBox, x5 yp+30 w275 h95 , Background settings
					Gui, Add, Text, xp+5 yp+20 w30 h20 , Color
					Gui, Add, Edit, xp+35 yp-3 w50 h20 vUGuiBGDarken_Color gGUISetting_color +Uppercase, % strupper(RegExReplace(dec2hex(GuiBGDarken_Color),"0x"))
					GuiBGDarken_Max_pc:=Round((abs(255-GuiBGDarken_Max)/255)*100)
					Gui, Add, Text, xp+110 yp+3 w80 h20 , Transparency `%
					Gui, Add, Edit, xp+80 yp-3 w40 h20 ;, 50
					Gui, Add, UpDown, vUGuiBGDarken_Max Range0-100, %GuiBGDarken_Max_pc%
					Gui, Add, Text, x10 yp+23 w35 h20 , Speed
					Gui, Add, Edit, xp+35 yp-3 w50 h20 ;, 6
					Gui, Add, UpDown, vUGuiBGDarken_Increment Range1-100, %GuiBGDarken_Increment%
					Gui, Font, italic underline c666666
					Gui, Add, Text, x5 yp+23 w270 h30 +Center + BackgroundTrans, Note: Set the Transparency to '100`%' to disable the background
					Gui, Font
			}
		
		;----------- Misc settings -----------------;
		Gui, Tab, Others
			if(RunOnStartUp)
					Gui, Add, CheckBox, x5 y25 checked vRunOnStartUp, Run %AppName% on start-up
			else
					Gui, Add, CheckBox, x5 y25 vRunOnStartUp, Run %AppName% on start-up
			if(CmdPaste)
					Gui, Add, CheckBox, xp yp+20 checked vCmdPaste, Enable Console Ctrl+V Pasting
			else
					Gui, Add, CheckBox, xp yp+20 vCmdPaste, Enable Console Ctrl+V Pasting
			if(HideOnInActive)
					Gui, Add, CheckBox, xp yp+20 checked vHideOnInActive, Hide when inactive
			else
					Gui, Add, CheckBox, xp yp+20 vHideOnInActive, Hide when inactive
			if(ReduceMemory)
				Gui, Add, CheckBox, xp yp+20 checked vReduceMemory, Reduce Memory Usage
			else
				Gui, Add, CheckBox, xp yp+20 vReduceMemory, Reduce Memory Usage
			;if(AutoWinActivate)
				; Gui, Add, CheckBox, x12 y109 Disabled checked vAutoWinActivate, Auto WinActivate
			;else
					Gui, Add, CheckBox, xp yp+20 Disabled vAutoWinActivate, Auto WinActivate
			/*
				if(ShowDebugMenu)
					Gui, Add, CheckBox, x12 y129 checked vShowDebugMenu, Show Debug Menu
				else
					Gui, Add, CheckBox, x12 y129 vShowDebugMenu, Show Debug Menu
				*/
		;----------- Save and Cancel -----------------;
		Gui, Tab
			Gui, Add, Button, x29 y249 w100 h30 gGuiSave Default, &Save
			Gui, Add, Button, xp+129 yp wp hp gGuiClose, &Cancel
		; Generated using SmartGUI Creator 4.0
		Gui, Show, h295 w285, %appname% Settings

		Console_Mode:=(Console_Mode)?Console_Mode:"Cmd"
		GuiControl, ChooseString, DDMode, %Console_Mode%
		SetEditPlaceholder(hEditCMD_StartUpArgs,"...to be appended at run/launch...")
		prog_settings:=1
	}
	else
	{
		WinActivate, %appname% Settings
	}
return

ButtonMintty:
mintty_pathS:=BrowseForConsole("Mintty")
return
ButtonCMD:
CMD_PathS:=BrowseForConsole("Cmd")
return
ButtonConsole2:
Console_2_pathS:=BrowseForConsole("Console2")
return
ButtonGitBash:
GitBash_pathS:=BrowseForConsole("GitBash")
return
GuiSave:
	Gui,Submit
	GuiSave_btn_clicked:=1
	if (WinKey)
		OpenHotkey=#%OpenHotkey%
	IniWrite,%Uspeed%,%configFile%,Animation,Speed
	IniWrite,%Udelay%,%configFile%,Animation,Delay
	IniWrite,%Udx%,%configFile%,Animation,dx
	IniWrite,%HideOnInActive%,%configFile%,Settings,HideOnInActive
	IniWrite,%HorizontallyCentered%,%configFile%,Settings,HorizontallyCentered
	IniWrite,%BottomPlaced%,%configfile%,Settings,BottomPlaced
	;IniWrite,%ShowDebugMenu%,%configFile%,Settings,ShowDebugMenu
	IniWrite,%AnimationDisabled%,%configFile%,Animation,AnimationDisabled
	IniWrite,%CmdPaste%,%configFile%,Settings,CmdPaste
	IniWrite,%AutoWinActivate%,%configFile%,Settings,AutoWinActivate
	IniWrite,%ReduceMemory%,%configFile%,Settings,ReduceMemory
	IniWrite,%RunOnStartUp%,%configFile%,Settings,RunOnStartUp
	setAutorun(RunOnStartUp)
	IniWrite,%DDMode%,%configFile%,Settings,Console_Mode
	IniWrite,%UTransparencyPercent%,%configFile%,Settings,TransparencyPercent
	if (FileExist(CMD_PathS)) {
		SplitPath,CMD_PathS,,,__cmdExt,__cmdName
		if __cmdExt = lnk
		{
			IniWrite,%CMD_PathS%,%configFile%,Settings,CMD_Path
		} else {
			CMD_Path=%A_scriptDir%\%__cmdName%_Qonsole.lnk
			FileCreateShortcut,%CMD_PathS%,%CMD_Path%
			IniWrite,%CMD_Path%,%configFile%,Settings,CMD_Path
		}
		;MsgBox, 64, Qonsole - Notice, Qonsole has created a configuration file:`n"%CMD_Path%"
	}
	if (FileExist(mintty_pathS))
		IniWrite,%mintty_pathS%,%configFile%,Settings,Mintty_Path
	if (FileExist(Console_2_pathS))
		IniWrite,%Console_2_pathS%,%configFile%,Settings,Console_2_path
	if (FileExist(GitBash_pathS))
		IniWrite,%GitBash_pathS%,%configFile%,Settings,GitBash_Path
	IniWrite,%OpenHotkey%,%configFile%,Settings,OpenHotkey
	IniWrite,%UCMD_Width%,%configFile%,Settings,CMD_Width
	IniWrite,%UCMD_Height%,%configFile%,Settings,CMD_Height
	IniWrite,%CMD_StartUpArgs%,%configFile%,Settings,CMD_StartUpArgs
	IniWrite,%UGuiBGDarken_Increment%,%configFile%,Animation,GuiBGDarken_Increment
	UGuiBGDarken_Max:=abs(255-Round((UGuiBGDarken_Max/100)*255))
	IniWrite,%UGuiBGDarken_Max%,%configFile%,Animation,GuiBGDarken_Max
	GuiControlGet,GUISetting_color_v,,UGuiBGDarken_Color
	GUISetting_color_v:="0x" SubStr(strupper(RegExReplace(GUISetting_color_v,"0x")),1,6)
	IniWrite,%GUISetting_color_v%,%configFile%,Animation,GuiBGDarken_Color
	
	gosub, GuiClose
	;if (show_settings_btn_clicked||GuiSave_btn_clicked)
	MsgBox, % (68+MsgBox_AlwaysOnTop), %appname% Settings, A restart is needed to appropriately apply the new settings.`n`tWould you like to restart the program now?
	IfMsgBox, Yes
		gosub Reload
return

GuiClose:
	Gui,Destroy
	prog_settings:=0
return

GUISetting_color:
GuiControlGet,GUISetting_color_v,,UGuiBGDarken_Color
if (StrLen(GUISetting_color_v) < 7) ; (< or = to 6)
	GUISetting_color_v:="0x" GUISetting_color_v
GUISetting_color_v:=dec2hex(GUISetting_color_v)
GuiControl,,UGuiBGDarken_Color, % strupper(RegExReplace(GUISetting_color_v,"0x"))
return

BrowseForConsole(name) {
	t:=A_scriptDir
	FileSelectFile,tmp,33,%t%,%name% Path, Files (*.exe; *.lnk; *.bat; *.com; *.vbs)
	SplitPath,tmp,,,ext
	if (ext="LNK")
		FileGetShortcut,%tmp%,tmp
	return tmp
}

About_prog:
if (!About_prog)
{
	gui, About_prog: +ToolWindow -Caption +AlwaysOnTop +hwndhAboutGUI
	Gui, About_prog:Color, 333333
	if (A_IsCompiled)
		Gui, About_prog:Add, Picture, x2 y2 w48 h48 Icon1, %A_ScriptFullPath%
	else
		Gui, About_prog:Add, Picture, x2 y2 w48 h48 Icon1, %A_scriptDir%\logo\Qonsole_sm.ico
	Gui, About_prog:font, s16 c00FF00, Sans Serif
	Gui, About_prog:font, s16 c00FF00, Segoe UI Light
	Gui, About_prog:Add, Text, x+2 yp+4, Qonsole
	Gui, About_prog:font, s8, Segoe UI
	Gui, About_prog:Add, Text, xp+2 y+4, Version %Version% (%App_date%)`nBy Joe DF
	Gui, About_prog:Add, Text, xp yp+30, Proudly under the MIT License
	Gui, About_prog:Show, w218 h92, About %appname%
	enableGuiDrag("About_prog")
	About_prog:=1
	;WinWaitNotActive, About %appname%
	WinWaitNotActive, ahk_id %hAboutGUI%
	goto About_progGuiClose
}
else
{
	WinActivate, About %appname%
}
return

About_progGuiEscape:
About_progGuiClose:
	gui, About_prog:Destroy
	About_prog:=0
return

strupper(str) {
	StringUpper,str,str
	return str
}

write_console_setup(file) {
	global Default_CMD_Width
xml =
(
<?xml version="1.0"?>
<settings>
	<console change_refresh="10" refresh="100" rows="20" columns="%Default_CMD_Width%" buffer_rows="500" buffer_columns="0" shell="" init_dir="" start_hidden="0" save_size="0">
		<colors>
			<color id="0" r="0" g="0" b="0"/>
			<color id="1" r="0" g="0" b="128"/>
			<color id="2" r="0" g="150" b="0"/>
			<color id="3" r="0" g="150" b="150"/>
			<color id="4" r="170" g="25" b="25"/>
			<color id="5" r="128" g="0" b="128"/>
			<color id="6" r="128" g="128" b="0"/>
			<color id="7" r="192" g="192" b="192"/>
			<color id="8" r="128" g="128" b="128"/>
			<color id="9" r="0" g="100" b="255"/>
			<color id="10" r="0" g="255" b="0"/>
			<color id="11" r="0" g="255" b="255"/>
			<color id="12" r="255" g="50" b="50"/>
			<color id="13" r="255" g="0" b="255"/>
			<color id="14" r="255" g="255" b="0"/>
			<color id="15" r="255" g="255" b="255"/>
		</colors>
	</console>
	<appearance>
		<font name="Fixedsys" size="8" bold="0" italic="0" smoothing="1">
			<color use="1" r="0" g="255" b="0"/>
		</font>
		<window title="Console" icon="" use_tab_icon="0" use_console_title="0" show_cmd="0" show_cmd_tabs="0" use_tab_title="1" trim_tab_titles="0" trim_tab_titles_right="0"/>
		<controls show_menu="0" show_toolbar="0" show_statusbar="0" show_tabs="1" hide_single_tab="1" show_scrollbars="1" flat_scrollbars="1" tabs_on_bottom="1"/>
		<styles caption="0" resizable="0" taskbar_button="0" border="0" inside_border="3" tray_icon="0">
			<selection_color r="255" g="255" b="255"/>
		</styles>
		<position x="0" y="-306" dock="-1" snap="-1" z_order="1" save_position="0"/>
		<transparency type="1" active_alpha="210" inactive_alpha="210" r="0" g="0" b="0"/>
	</appearance>
	<behavior>
		<copy_paste copy_on_select="0" clear_on_copy="1" no_wrap="1" trim_spaces="1" copy_newline_char="0" sensitive_copy="1"/>
		<scroll page_scroll_rows="0"/>
		<tab_highlight flashes="3" stay_highligted="1"/>
	</behavior>
	<hotkeys use_scroll_lock="1">
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="83" command="settings"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="112" command="help"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="27" command="exit"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="112" command="newtab1"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="113" command="newtab2"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="114" command="newtab3"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="115" command="newtab4"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="116" command="newtab5"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="117" command="newtab6"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="118" command="newtab7"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="119" command="newtab8"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="120" command="newtab9"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="121" command="newtab10"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="49" command="switchtab1"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="50" command="switchtab2"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="51" command="switchtab3"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="52" command="switchtab4"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="53" command="switchtab5"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="54" command="switchtab6"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="55" command="switchtab7"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="56" command="switchtab8"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="57" command="switchtab9"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="48" command="switchtab10"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="9" command="nexttab"/>
		<hotkey ctrl="1" shift="1" alt="0" extended="0" code="9" command="prevtab"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="87" command="closetab"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="0" code="82" command="renametab"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="1" code="45" command="copy"/>
		<hotkey ctrl="1" shift="0" alt="0" extended="1" code="46" command="clear_selection"/>
		<hotkey ctrl="0" shift="1" alt="0" extended="1" code="45" command="paste"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="stopscroll"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollrowup"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollrowdown"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollpageup"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollpagedown"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollcolleft"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollcolright"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollpageleft"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="scrollpageright"/>
		<hotkey ctrl="1" shift="1" alt="0" extended="0" code="112" command="dumpbuffer"/>
		<hotkey ctrl="0" shift="0" alt="0" extended="0" code="0" command="activate"/>
	</hotkeys>
	<mouse>
		<actions>
			<action ctrl="0" shift="0" alt="0" button="1" name="copy"/>
			<action ctrl="0" shift="1" alt="0" button="1" name="select"/>
			<action ctrl="0" shift="0" alt="0" button="3" name="paste"/>
			<action ctrl="1" shift="0" alt="0" button="1" name="drag"/>
			<action ctrl="0" shift="0" alt="0" button="2" name="menu"/>
		</actions>
	</mouse>
	<tabs>
		<tab title="Console2" use_default_icon="0">
			<console shell="" init_dir="" run_as_user="0" user=""/>
			<cursor style="0" r="255" g="255" b="255"/>
			<background type="0" r="0" g="0" b="0">
				<image file="" relative="0" extend="0" position="0">
					<tint opacity="0" r="0" g="0" b="0"/>
				</image>
			</background>
		</tab>
	</tabs>
</settings>
)
	if (FileExist(file))
		FileDelete,%file%
	FileAppend,%xml%,%file%
}

show_properties(file) {
	A_titlemode:=A_TitleMatchMode
	SetTitleMatchMode,2
	SplitPath,file,,,,fn_nx
	Run, properties "%file%"
	r:=ErrorLevel
	WinWaitActive,: %fn_nx%
	WinWaitClose,: %fn_nx%
	SetTitleMatchMode,%A_titlemode%
	Return r
}

ITaskbarList(activeHwnd,n) {
	;Function forked from Pulover's
	;http://www.autohotkey.com/board/topic/83159-solved-removing-windows-taskbar-icons/#entry529572
	
	/*
	  Example: Temporarily remove the active window from the taskbar by using COM.

	  Methods in ITaskbarList's VTable:
		IUnknown:
		  0 QueryInterface  -- use ComObjQuery instead
		  1 AddRef          -- use ObjAddRef instead
		  2 Release         -- use ObjRelease instead
		ITaskbarList:
		  3 HrInit
		  4 AddTab
		  5 DeleteTab
		  6 ActivateTab
		  7 SetActiveAlt
	*/
	IID_ITaskbarList  := "{56FDF342-FD6D-11d0-958A-006097C9A090}"
	CLSID_TaskbarList := "{56FDF344-FD6D-11d0-958A-006097C9A090}"

	; Create the TaskbarList object and store its address in tbl.
	tbl := ComObjCreate(CLSID_TaskbarList, IID_ITaskbarList)

	;activeHwnd := WinExist("A")

	;DllCall(vtable(tbl,3), "ptr", tbl)                     ; tbl.HrInit()
	DllCall(NumGet(NumGet(tbl+0), 3*A_PtrSize), "ptr", tbl)
	;DllCall(vtable(tbl,5), "ptr", tbl, "ptr", activeHwnd)  ; tbl.DeleteTab(activeHwnd)
	DllCall(NumGet(NumGet(tbl+0), n*A_PtrSize), "ptr", tbl, "ptr", activeHwnd)
	;Sleep 3000
	;DllCall(vtable(tbl,4), "ptr", tbl, "ptr", activeHwnd)  ; tbl.AddTab(activeHwnd)
	ObjRelease(tbl) ; Non-dispatch objects must always be manually freed.
	
	/*
	vtable(ptr, n) {
		; NumGet(ptr+0) returns the address of the object's virtual function
		; table (vtable for short). The remainder of the expression retrieves
		; the address of the nth function's address from the vtable.
		return NumGet(NumGet(ptr+0), n*A_PtrSize)
	}
	*/
}
;}

WindowDesign(WindowHWND) {
	SetWinDelay, -1
	global TransparencyPercent
	global Console_2_Mode
	WinSet, Transparent, % currentTrans:=(abs(100-TransparencyPercent)/100)*255 , ahk_id %WindowHWND%
	Winset, AlwaysOnTop, On, ahk_id %WindowHWND%
	
	;Bugged trick method from quahke-console // Forked
	WinSet, Style, % -(0x80000000|0xC00000|0x40000), ahk_id %WindowHWND%
	WinSet, ExStyle, % -0x200 +0x00000080 -0x00040000, ahk_id %WindowHWND%
	
	;set the rest
	getFontSize(fw,fh)
	getConsoleSize(cw,ch)
	WinGetPos,,,,winFH,ahk_id %windowHWND%
	SysGet,tbarH,4
	sysget,winBH,31
	dlines:=ceil(((winFH-tbarH)-winBH)/fh)
	x:=0 + 2 ;(Console_2_Mode) ? 0 : 2
	y:=0 + 2 ;(Console_2_Mode) ? 0 : 2
	RectX:=fw*cw + 2 - x
	RectY:=fh*dlines + 2 - y
	
	;///////////////////////// [ XP Patch ] /////////////////////////
	global XPMode
	if (XPMode) {
		wingetpos,xxx,yyy,w_width,w_height, ahk_id %WindowHWND%
		winmove,ahk_id %WindowHWND%,,2,2
		;msgbox %x%-%y% w%RectX% h%RectY% : %w_width% %w_height%
		wwx:=6 ;fw-2 ;6
		wwy:=32 ;8+(2*fh) ;4*fh ;32
		;msgbox %tbarH% %winBH%
		www:=(w_width-6)-23 ;(RectX)
		wwh:=(w_height-32)-6 ;(w_height-32)-4 ;(RectY)+fh
		WinSet, Region, %wwx%-%wwy% w%www% h%wwh%, ahk_id %WindowHWND%
		;msgbox % errorlevel "   ??????????"
		winmove,ahk_id %WindowHWND%,,%xxx%,%yyy%
	}
	else
	{
		WinSet, Region, %x%-%y% w%RectX% h%RectY%, ahk_id %WindowHWND%
	}
	;///////////////////////// [ XP Patch ] /////////////////////////
	
	winset,Redraw,, ahk_id %WindowHWND%
}

;Modern-like Exponential Movement - inspired from Quahke
WinSlideDownExp(Wintitle,Delay,spd,fy,dx) {
	global anim
	
	global AnimationDisabled
	if (AnimationDisabled) {
		WinMove,%Wintitle%,,, % abs(fy)
		anim:=0
		return
	}
	
	anim:=-1
	tau:=8*atan(1)
	WinGetPos,,y,,,%wintitle%
	while (y<(fy-1))
	{
		if !WinExist(wintitle)
			return
		if (anim==1)
			return
		WinGetPos,,y,,,%wintitle%
		b:=y+(spd*(-(1-exp((abs(dx)-A_Index)/tau))+1))+1
		if (b > fy)
			WinMove,%Wintitle%,,, % (abs(y-fy)+y)
		else
			WinMove,%Wintitle%,,,%b%
		if Delay
			Sleep %delay%
		if (b>=fy)
			break
	}
	;WinMove,%Wintitle%,,,%fy%
	anim:=0
	return
}

WinSlideUpExp(Wintitle,Delay,spd,fy,dx) {
	global anim
	
	global AnimationDisabled
	if (AnimationDisabled) {
		WinMove,%Wintitle%,,, % (fy)
		anim:=0
		return
	}
	
	anim:=1
	tau:=8*atan(1)
	WinGetPos,,y,,,%wintitle%
	while (y>(fy+1))
	{
		if (anim==-1)
			return
		if !WinExist(wintitle)
			return
		WinGetPos,,y,,,%wintitle%
		b:=y-(spd*(-(1-exp((abs(dx)-A_Index)/tau))+1))-1
		if (b<=fy) {
			WinMove,%Wintitle%,,,%fy%
			break
		}
		if (b <= y) ;(b > fy)
			WinMove,%Wintitle%,,,%b%
		if Delay
			Sleep %delay%
	}
	;WinMove,%Wintitle%,,,%fy%
	anim:=0	
	return
}

enableGuiDrag(GuiLabel=1) {
	WinGetPos,,,A_w,A_h,A
	Gui, %GuiLabel%:Add, Text, x0 y0 w%A_w% h%A_h% +BackgroundTrans gGUI_Drag
	return
	
	GUI_Drag:
	PostMessage 0xA1,2  ;-- Goyyah/SKAN trick
	;http://www.autohotkey.com/board/topic/80594-how-to-enable-drag-for-a-gui-without-a-titlebar/#entry60075
	return
}

getStdoutHandle() {
	global Stdout
	return Stdout.__Handle
}

setAutorun(query) {
	global AppName
	if (query) {
	FileCreateShortcut,"%A_ScriptFullPath%",%A_Startup%\%AppName%.lnk,%A_WorkingDir%
	} else {
	FileDelete, %A_Startup%\%AppName%.lnk
	}
}

cleanself:
If (ReduceMemory)
	EmptyMem()
return

EmptyMem(PID="AHK Rocks"){ ;by hersey
	pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
	h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
	DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
	DllCall("CloseHandle", "Int", h)
}

/* http://ahkscript.org/boards/viewtopic.php?f=9&t=503&p=4648#p4263
## Funktion: SetEditPlaceholder
## Beschreibung: Setzt einen Platzhalter für ein Edit-Feld. Dieser ist nur sichtbar, solange nichts in dem Feld steht. Entspricht dem Attribut placeholder in HTML.
## Parameter:
# control: Entweder ein HWND oder die zugewiesene Variable (als String!) des Steuerelements.
# string: Der Text, der als Platzhalter im Steuerelement stehen soll.
# showalways: Bestimmt, ob der Text auch angezeigt werden soll, während das Steuerelement Fokus hat. Standard: 0 (deaktiviert)
## return: "" (kein besonderer Wert)
*/
SetEditPlaceholder(control, string, showalways = 0){
    if control is not number
        GuiControlGet, control, HWND, %control%
    if(!A_IsUnicode){
        VarSetCapacity(wstring, (StrLen(wstring) * 2) + 1)
        DllCall("MultiByteToWideChar", UInt, 0, UInt, 0, UInt, &string, Int, -1, UInt, &wstring, Int, StrLen(string) + 1)
    }
    else
        wstring := string
    DllCall("SendMessageW", "UInt", control, "UInt", 0x1501, "UInt", showalways, "UInt", &wstring)
    return
}
