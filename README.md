# JumpType Menu
This is a plugin I wrote a while ago for a friend to replace their [existing plugin](https://github.com/Franc1sco/Franug-JumpType/blob/master/jumptype_menu.sp) with one that utilizes the sv_autobunnyhopping ConVar.

credit to shavit: https://github.com/shavitush/bhoptimer & https://forums.alliedmods.net/showpost.php?p=1740177&postcount=3

credit to Franc1sco: https://github.com/Franc1sco/Franug-JumpType
## Convars
```CPP
sm_jumptype_only		2	//0:easy(auto), 1: longjump, 2:both (named for backwards compatablity)
	
sm_bhop_jumptype_default	1	//0:easy(auto), 1: longjump
sm_bhop_height			1.1	//height of longjump (1.0 to disable)
sm_bhop_length			1.75	//lenght of longjump (1.0 to disable)
sm_bhop_AA_LJ			3000.0	//set sv_airaccelerate (0.0 to disable)
sm_bhop_lj_max			300.0	//maximum speed for applying jump boosts to players
```

## Client Commands 
```CPP
sm_jump		//with no arguments it opens the menu

sm_jump	0	//set bhop style to easy (auto)
sm_jump	1	//set bhop style to longjump
sm_jump	2	//toggle bhop style
```
