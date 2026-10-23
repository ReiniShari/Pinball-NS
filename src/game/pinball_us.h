/*
 * pinball_us.h - addresses in "Pokemon Pinball (USA, Australia)" (SHA-1 9402014d14969432142abfde728c6f1a10ee4dac).
 * Names follow the pret/pokepinball disassembly, which builds this exact ROM.
 */
#ifndef PINBALL_US_H
#define PINBALL_US_H

#define PB_ROM_SHA1 "9402014d14969432142abfde728c6f1a10ee4dac"

/* ---- routines: (bank, address) ---- */
#define R_BankSwitch                     0x054F   /* bank 0 */
#define R_SetAllPalettesWhite            0x0B66   /* bank 0 */
#define R_FadeIn_GameboyColor            0x0C19   /* bank 0 */
#define R_FadeInStep                     0x0C2D   /* bank 0 */
#define R_FadeOut_GameboyColor           0x0CEE   /* bank 0 */
#define R_FadeOutStep                    0x0D11   /* bank 0 */
#define R_QueueGraphicsToLoadWithFunc    0x10C5   /* bank 0 */
#define R_Func_113a                      0x113A   /* bank 0: runs the graphics queue (VBlank)     */
#define R_Func_113a_Entry                0x114B   /* bank 0: "push hl" in the queue loop, L = slot */
#define R_Func_113a_AfterCall            0x1162   /* bank 0: right after "call JumpToHL"          */
#define B_CaptureAnimation               0x04     /* catch mode: the capture shown on the billboard */
#define R_CaptureAnimation               0x4496   /* (callba from the stages' catch mode steps)   */
#define R_Ret                            0x112F   /* bank 0: the "ret" of Func_1129               */
#define R_ResolveGameObjectCollisions    0x281C   /* bank 0 */
#define B_DrawSpritesForStage 2
#define R_DrawSpritesForStage            0x44B7
#define B__LoadStageData 2
#define R__LoadStageData                 0x4471
#define B_HandleBallLoss 3
#define R_HandleBallLoss                 0x5C49
#define B_UpdateFlipperStates 3
#define R_UpdateFlipperStates            0x6118
#define B_LoadStageCollisionAttributes 3
#define R_LoadStageCollisionAttributes   0x6578
#define B_LoadStageData 3
#define R_LoadStageData                  0x66C2
#define B_CheckStageTransition 3
#define R_CheckStageTransition           0x6CE9
#define B_ScrollScreenToShowPinball 3
#define R_ScrollScreenToShowPinball      0x6D5E
#define B_DrawTimer 5
#define R_DrawTimer                      0x75A4

/* ---- variables ---- */
#define W_StageCollisionMap          0xC700   /* $300 bytes */
#define W_VramQueueStart             0xCA00   /* $600 bytes: graphics queue (wca00, wcb00..wcf00) */
#define W_VramQueueFunc              0xCE00   /* routine of each entry: low bytes, then high at $CF00 */
#define W_QueueBuffers               0xC000   /* wc000, wc150, wc1b8: data of queue entries (billboard */
#define W_QueueBuffersSize           0x200    /* picture and palettes); measured: entries read C001-C1B9 */
#define W_SpriteBuffer               0xD000   /* $A0 bytes */
#define W_PaletteData                0xD200   /* $80 bytes, then fade buffers ($40 BG, $40 OBJ) */
#define W_FadeBGPaletteData          0xD280
#define W_FadeOBJPaletteData         0xD2C0
#define W_BallType                   0xD47E
#define W_NextBonusStage             0xD498
#define W_ExtraBalls                 0xD49B
#define W_CurrentStage               0xD4AC
#define W_MoveToNextScreenState      0xD4AE
#define W_StageCollisionState        0xD4AF
#define W_BallXPos                   0xD4B3   /* 2 bytes: fraction, pixel */
#define W_BallYPos                   0xD4B5   /* 2 bytes: fraction, pixel */
#define W_LeftMapMoveCounter         0xD4F0
#define W_RightMapMoveCounter        0xD4F2
#define W_StaryuState                0xD502   /* wd502 */
#define W_PikachuSaverCharge         0xD517
#define W_IndicatorStates            0xD52F   /* $13 bytes */
#define W_PinballIsVisible           0xD548
#define W_CurrentMap                 0xD54A
#define W_InSpecialMode              0xD54B
#define W_SpecialModeState           0xD54D
#define W_SpecialMode                0xD550
#define W_EvolutionObjectsDisabled   0xD551
#define W_NumEvolutionTrinkets       0xD554
#define W_MapMoveDirection           0xD55A
#define W_RareMonsFlag               0xD55B
#define W_CollidedPointIndex         0xD578   /* evolution trinket touched (1-based point index of the half) */
#define W_NumMonHits                 0xD5C0
#define W_CapturingMon               0xD5F3
#define W_BallUpgradeTriggerStates   0xD5F9   /* 3 bytes */
#define W_SlotIsOpen                 0xD604
#define W_OpenedSlotBy4CAVELights    0xD608
#define W_OpenedSlotBy3Pokeballs     0xD609
#define W_BonusMultiplierTens        0xD60C
#define W_BonusMultiplierOnes        0xD60D
#define W_NumBellsproutEntries       0xD62A
#define W_BlueForceFieldDirection    0xD63E
#define W_LeftRightTiltOffset        0xD79F
#define W_UpperTiltOffset            0xD7A0
#define W_SCX                        0xD7AB
#define W_DisableHorizontalScrollForBallStart 0xD7AC
#define W_RedStageStructureBackup    0xD7AD
#define W_StageCollisionMapPointer   0xD7EC   /* .. D7F1 */
#define W_d7f2                       0xD7F2
#define W_d7fa                       0xD7FA   /* graphics queue budget */
#define W_d7fb                       0xD7FB   /* graphics queue write index */
#define W_d7fc                       0xD7FC   /* graphics queue read index */
#define W_SpriteBufferSize           0xD802
#define W_CurrentScreen              0xD8F1
#define W_ScreenState                0xD8F2
/* VRAM tile data (offsets from $8000) of the window's dynamic graphics: status bar icons
 * and message letters, pause menu cursor (tiles $81-$8F, bank 0; $80 is the blank tile of
 * both fields). Measured with tools/pbdebug: the main program only writes $8830-$886F
 * there, and the field halves do not display these tiles. */
#define PB_WIN_TILES_LO              0x0810
#define PB_WIN_TILES_HI              0x0900
/* the status bar tiles ($8800-$88FF) as every field stage loads them, the same for both tables
 * and both halves: StageRedFieldTopStatusBarSymbolsGfx_GameBoyColor, ROM 27:4000 */
#define ROM_StatusBarSymbols         0x9C000u
#define ROM_AsteriskGlyph            0xD6480u  /* InGameMenuSymbolsGfx + $80: the "*" of the bottom texts */
#define W_DrawBottomMessageBox       0xD4AA
#define W_BottomTextEnabled          0xD5CA
#define W_KeyConfigs                 0xD948   /* 7 pairs of button masks (OPTION > KEY CONFIG) */
#define S_KeyConfigs                 0x0244   /* their copy in the cartridge save: 14 bytes, "NT", checksum, backup */

#define H_FarCallTempA               0xFF8A
#define H_SCY                        0xFFA0
#define H_SCX                        0xFFA1
#define H_WY                         0xFFA6

#define SCREEN_TITLESCREEN  3
#define SCREEN_PINBALL_GAME 4
#define SCREEN_OPTIONS      6

/* stages */
#define STAGE_RED_FIELD_TOP     0
#define STAGE_RED_FIELD_BOTTOM  1
#define STAGE_BLUE_FIELD_TOP    4
#define STAGE_BLUE_FIELD_BOTTOM 5

#endif
