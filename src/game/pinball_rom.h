/*
 * pinball_rom.h - the ROMs Pinball NS plays, and where their routines and variables are.
 *
 *   - Pokemon Pinball (USA, Australia), SHA-1 9402014d14969432142abfde728c6f1a10ee4dac. Names of the
 *     pret/pokepinball disassembly, which builds this exact ROM.
 *   - Pokemon Pinball Generations 1.6, SHA-1 9407074cc9b5a93d731a07e2d24b9ca06ecf17d7: a fan-made
 *     extension of that disassembly (four more tables, Gold, Silver, Ruby and Sapphire, and the Pokemon
 *     of the later generations), applied to the US ROM. Addresses from its own disassembly, assembled
 *     (the same ROM, byte for byte). Its code is the original's, moved; its new tables are copies of
 *     the Red one (Gold, Ruby) and of the Blue one (Silver, Sapphire) with the same variables, so the
 *     unified field works the same way on all six. Its bonus stages are the original five,
 *     numbered after the twelve stages of its tables.
 *
 * The macros below give the address in the ROM being played: a file using them defines PBR, the
 * profile in use (`#define PBR (pb->rom)`). The ROM is recognised by pb_init (pb_rom_profile).
 */
#ifndef PINBALL_ROM_H
#define PINBALL_ROM_H

#include <stdint.h>
#include <stddef.h>

enum { PB_ROM_ORIGINAL = 0, PB_ROM_GENERATIONS = 1 };

/* the tables (pb_table) */
enum { PB_TABLE_RED = 0, PB_TABLE_BLUE, PB_TABLE_GOLD, PB_TABLE_SILVER, PB_TABLE_RUBY, PB_TABLE_SAPPHIRE, PB_TABLES };
/* the tables built like the Red one (its structures, the funnel of its frame) or like the Blue one */
#define PB_TABLE_RED_LIKE(t) ((t) == PB_TABLE_RED || (t) == PB_TABLE_GOLD || (t) == PB_TABLE_RUBY)

/* the bonus stages (pb_bonus) */
enum { PB_BONUS_NONE = 0, PB_BONUS_GENGAR, PB_BONUS_MEWTWO, PB_BONUS_MEOWTH, PB_BONUS_DIGLETT, PB_BONUS_SEEL };

#define PB_WCLASS_RANGES 24
#define PB_WATCH_MAX     48
#define PB_BALL_HITS     17

typedef struct PbRom {
    const char *name;
    const char *sha1;
    int id;
    /* routines: bank 0, or the bank in B_ */
    uint16_t R_BankSwitch, R_SetAllPalettesWhite, R_FadeInStep, R_FadeOut_GameboyColor, R_FadeOutStep;
    uint16_t R_SetFadedPalettesRet;          /* the "ret" of SetFadedPalettes */
    uint16_t R_QueueGraphicsToLoadWithFunc;
    uint16_t R_Func_113a;                    /* runs the graphics queue (VBlank) */
    uint16_t R_Func_113a_Entry;              /* "push hl" in its loop, L = slot */
    uint16_t R_Func_113a_AfterCall;          /* right after its "call JumpToHL" */
    uint16_t R_Ret;                          /* the "ret" of Func_1129 */
    uint16_t R_ResolveGameObjectCollisions;
    uint16_t R_PlaySoundEffect, R_PlaySong;
    uint16_t R_WaitFrame, R_WaitFrameLoop;   /* the wait for the next frame (clears hFFB2), its loop */
    uint16_t R_FlagWait, R_FlagWaitEnd;      /* a wait for a flag cleared by an interrupt */
    uint16_t R_ScreenOff, R_ScreenOffEnd;    /* the wait to turn the screen off */
    uint16_t R_CopyScreenOnLoop, R_CopyScreenOffLoop;
    uint8_t  B_HandleBallPhysics;  uint16_t R_ResolveDone;   /* its return site in HandleBallPhysics */
    uint8_t  B_DrawSpritesForStage;  uint16_t R_DrawSpritesForStage;
    uint8_t  B_HandleBallLoss;  uint16_t R_HandleBallLoss;
    uint8_t  B_UpdateFlipperStates;  uint16_t R_UpdateFlipperStates;
    uint8_t  B_LoadStageCollisionAttributes;  uint16_t R_LoadStageCollisionAttributes;
    uint8_t  B_LoadStageData;  uint16_t R_LoadStageData;
    uint8_t  B_CheckStageTransition;  uint16_t R_CheckStageTransition;
    uint8_t  B_ScrollScreenToShowPinball;  uint16_t R_ScrollScreenToShowPinball;
    uint8_t  B_DrawTimer;  uint16_t R_DrawTimer;
    uint8_t  B_CaptureAnimation;  uint16_t R_CaptureAnimation;    /* BallCaptureInit */
    uint8_t  B_PlayCry;  uint16_t R_PlayCry, R_PlayCryEnd, R_CryPlayer, R_CryPlayerEnd;
    uint16_t R_StartCatchEmMode, R_StartEvolutionMode;          /* bank 4 (tools: forced modes) */
    /* variables */
    uint16_t W_BallType, W_NextBonusStage, W_ExtraBalls, W_DrawBottomMessageBox, W_CurrentStage;
    uint16_t W_MoveToNextScreenState, W_StageCollisionState, W_BallXPos, W_BallYPos, W_BallXVelocity;
    uint16_t W_LeftMapMoveCounter, W_RightMapMoveCounter, W_StaryuState, W_PikachuSaverCharge;
    uint16_t W_IndicatorStates, W_PinballIsVisible, W_CurrentMap, W_InSpecialMode, W_SpecialModeState;
    uint16_t W_SpecialMode, W_EvolutionObjectsDisabled, W_CurrentEvolutionMon, W_NumEvolutionTrinkets;
    uint16_t W_MapMoveDirection, W_RareMonsFlag, W_CollidedPointIndex, W_CurrentCatchEmMon;
    uint16_t W_WildMonIsHittable, W_BallHitWildMon, W_NumMonHits, W_CatchModeMonTimer;
    uint16_t W_BottomTextEnabled, W_DisableDrawScoreboardInfo, W_CapturingMon, W_BallUpgradeTriggerStates;
    uint16_t W_SlotIsOpen, W_OpenedSlotBy4CAVELights, W_OpenedSlotBy3Pokeballs, W_BonusMultiplierTens;
    uint16_t W_BonusMultiplierOnes, W_NumBellsproutEntries, W_BlueForceFieldDirection;
    uint16_t W_LeftRightTiltOffset, W_UpperTiltOffset, W_SCX, W_DisableHorizontalScrollForBallStart;
    uint16_t W_RedStageStructureBackup, W_d7f2, W_d7fa, W_d7fb, W_d7fc, W_SpriteBufferSize;
    uint16_t W_SoundFlag;                    /* the flag the wait R_FlagWait waits for */
    uint16_t W_CurrentScreen, W_ScreenState, W_KeyConfigs;
    uint16_t W_GoingToBonusStage, W_NextStage, W_NumPartyMons, W_PartyMons, W_Score;
    uint16_t W_SelectedFieldIndex, W_FieldSelectRegion;   /* the table chosen (FIELD SELECT), its region (0: none) */
    uint16_t S_KeyConfigs;                   /* their copy in the cartridge save (offset) */
    /* the stages: their table (PB_TABLE_*, -1: not a table), their bonus stage (PB_BONUS_*) */
    int8_t table[32];
    uint8_t bonus[32];
    uint8_t first_bonus, last_bonus;
    /* the unified field (pinball.c): classes of the work RAM for the merge of the other half
     * (ranges [a, b), class), the variables the graphics of each half depend on, what the ball touched */
    struct { uint16_t a, b; uint8_t cls; } wclass[PB_WCLASS_RANGES];
    uint16_t watch_top[PB_WATCH_MAX];
    int nwatch_top;
    uint16_t watch_bottom[PB_WATCH_MAX];
    int nwatch_bottom;
    uint16_t ball_hits[PB_BALL_HITS];
} PbRom;

/* the profile of a ROM (NULL: not one Pinball NS plays) */
const PbRom *pb_rom_profile(const char sha1_hex[41]);
/* the ROMs it plays, in turn (NULL after the last) */
const PbRom *pb_rom_known(int i);

/* the work RAM classes */
enum { M_SHARED = 0, M_LOCAL = 1, M_BALL = 2 };

#define R_BankSwitch                    (PBR->R_BankSwitch)
#define R_SetAllPalettesWhite           (PBR->R_SetAllPalettesWhite)
#define R_FadeInStep                    (PBR->R_FadeInStep)
#define R_FadeOut_GameboyColor          (PBR->R_FadeOut_GameboyColor)
#define R_FadeOutStep                   (PBR->R_FadeOutStep)
#define R_SetFadedPalettesRet           (PBR->R_SetFadedPalettesRet)
#define R_QueueGraphicsToLoadWithFunc   (PBR->R_QueueGraphicsToLoadWithFunc)
#define R_Func_113a                     (PBR->R_Func_113a)
#define R_Func_113a_Entry               (PBR->R_Func_113a_Entry)
#define R_Func_113a_AfterCall           (PBR->R_Func_113a_AfterCall)
#define R_Ret                           (PBR->R_Ret)
#define R_ResolveGameObjectCollisions   (PBR->R_ResolveGameObjectCollisions)
#define R_PlaySoundEffect               (PBR->R_PlaySoundEffect)
#define R_PlaySong                      (PBR->R_PlaySong)
#define R_WaitFrame                     (PBR->R_WaitFrame)
#define R_WaitFrameLoop                 (PBR->R_WaitFrameLoop)
#define R_CopyScreenOnLoop              (PBR->R_CopyScreenOnLoop)
#define R_CopyScreenOffLoop             (PBR->R_CopyScreenOffLoop)
#define B_HandleBallPhysics             (PBR->B_HandleBallPhysics)
#define R_ResolveDone                   (PBR->R_ResolveDone)
#define B_DrawSpritesForStage           (PBR->B_DrawSpritesForStage)
#define R_DrawSpritesForStage           (PBR->R_DrawSpritesForStage)
#define B_HandleBallLoss                (PBR->B_HandleBallLoss)
#define R_HandleBallLoss                (PBR->R_HandleBallLoss)
#define B_UpdateFlipperStates           (PBR->B_UpdateFlipperStates)
#define R_UpdateFlipperStates           (PBR->R_UpdateFlipperStates)
#define B_LoadStageCollisionAttributes  (PBR->B_LoadStageCollisionAttributes)
#define R_LoadStageCollisionAttributes  (PBR->R_LoadStageCollisionAttributes)
#define B_LoadStageData                 (PBR->B_LoadStageData)
#define R_LoadStageData                 (PBR->R_LoadStageData)
#define B_CheckStageTransition          (PBR->B_CheckStageTransition)
#define R_CheckStageTransition          (PBR->R_CheckStageTransition)
#define B_ScrollScreenToShowPinball     (PBR->B_ScrollScreenToShowPinball)
#define R_ScrollScreenToShowPinball     (PBR->R_ScrollScreenToShowPinball)
#define B_DrawTimer                     (PBR->B_DrawTimer)
#define R_DrawTimer                     (PBR->R_DrawTimer)
#define B_CaptureAnimation              (PBR->B_CaptureAnimation)
#define R_CaptureAnimation              (PBR->R_CaptureAnimation)
#define B_PlayCry                       (PBR->B_PlayCry)
#define R_PlayCry                       (PBR->R_PlayCry)

#define W_BallType                      (PBR->W_BallType)
#define W_NextBonusStage                (PBR->W_NextBonusStage)
#define W_ExtraBalls                    (PBR->W_ExtraBalls)
#define W_DrawBottomMessageBox          (PBR->W_DrawBottomMessageBox)
#define W_CurrentStage                  (PBR->W_CurrentStage)
#define W_MoveToNextScreenState         (PBR->W_MoveToNextScreenState)
#define W_StageCollisionState           (PBR->W_StageCollisionState)
#define W_BallXPos                      (PBR->W_BallXPos)
#define W_BallYPos                      (PBR->W_BallYPos)
#define W_BallXVelocity                 (PBR->W_BallXVelocity)
#define W_LeftMapMoveCounter            (PBR->W_LeftMapMoveCounter)
#define W_RightMapMoveCounter           (PBR->W_RightMapMoveCounter)
#define W_StaryuState                   (PBR->W_StaryuState)
#define W_PikachuSaverCharge            (PBR->W_PikachuSaverCharge)
#define W_IndicatorStates               (PBR->W_IndicatorStates)
#define W_PinballIsVisible              (PBR->W_PinballIsVisible)
#define W_CurrentMap                    (PBR->W_CurrentMap)
#define W_InSpecialMode                 (PBR->W_InSpecialMode)
#define W_SpecialModeState              (PBR->W_SpecialModeState)
#define W_SpecialMode                   (PBR->W_SpecialMode)
#define W_EvolutionObjectsDisabled      (PBR->W_EvolutionObjectsDisabled)
#define W_CurrentEvolutionMon           (PBR->W_CurrentEvolutionMon)
#define W_NumEvolutionTrinkets          (PBR->W_NumEvolutionTrinkets)
#define W_MapMoveDirection              (PBR->W_MapMoveDirection)
#define W_RareMonsFlag                  (PBR->W_RareMonsFlag)
#define W_CollidedPointIndex            (PBR->W_CollidedPointIndex)
#define W_CurrentCatchEmMon             (PBR->W_CurrentCatchEmMon)
#define W_WildMonIsHittable             (PBR->W_WildMonIsHittable)
#define W_BallHitWildMon                (PBR->W_BallHitWildMon)
#define W_NumMonHits                    (PBR->W_NumMonHits)
#define W_CatchModeMonTimer             (PBR->W_CatchModeMonTimer)
#define W_BottomTextEnabled             (PBR->W_BottomTextEnabled)
#define W_DisableDrawScoreboardInfo     (PBR->W_DisableDrawScoreboardInfo)
#define W_CapturingMon                  (PBR->W_CapturingMon)
#define W_BallUpgradeTriggerStates      (PBR->W_BallUpgradeTriggerStates)
#define W_SlotIsOpen                    (PBR->W_SlotIsOpen)
#define W_OpenedSlotBy4CAVELights       (PBR->W_OpenedSlotBy4CAVELights)
#define W_OpenedSlotBy3Pokeballs        (PBR->W_OpenedSlotBy3Pokeballs)
#define W_BonusMultiplierTens           (PBR->W_BonusMultiplierTens)
#define W_BonusMultiplierOnes           (PBR->W_BonusMultiplierOnes)
#define W_NumBellsproutEntries          (PBR->W_NumBellsproutEntries)
#define W_BlueForceFieldDirection       (PBR->W_BlueForceFieldDirection)
#define W_LeftRightTiltOffset           (PBR->W_LeftRightTiltOffset)
#define W_UpperTiltOffset               (PBR->W_UpperTiltOffset)
#define W_SCX                           (PBR->W_SCX)
#define W_DisableHorizontalScrollForBallStart (PBR->W_DisableHorizontalScrollForBallStart)
#define W_RedStageStructureBackup       (PBR->W_RedStageStructureBackup)
#define W_d7f2                          (PBR->W_d7f2)
#define W_d7fa                          (PBR->W_d7fa)
#define W_d7fb                          (PBR->W_d7fb)
#define W_d7fc                          (PBR->W_d7fc)
#define W_SpriteBufferSize              (PBR->W_SpriteBufferSize)
#define W_CurrentScreen                 (PBR->W_CurrentScreen)
#define W_ScreenState                   (PBR->W_ScreenState)
#define W_KeyConfigs                    (PBR->W_KeyConfigs)
#define W_GoingToBonusStage             (PBR->W_GoingToBonusStage)
#define W_NextStage                     (PBR->W_NextStage)
#define W_NumPartyMons                  (PBR->W_NumPartyMons)
#define W_PartyMons                     (PBR->W_PartyMons)
#define W_Score                         (PBR->W_Score)
#define W_SelectedFieldIndex            (PBR->W_SelectedFieldIndex)
#define W_FieldSelectRegion             (PBR->W_FieldSelectRegion)
#define S_KeyConfigs                    (PBR->S_KeyConfigs)

/* the same in both ROMs */
#define W_VramQueueStart             0xCA00   /* $600 bytes: graphics queue (wca00, wcb00..wcf00) */
#define W_VramQueueFunc              0xCE00   /* routine of each entry: low bytes, then high at $CF00 */
#define W_QueueBuffers               0xC000   /* wc000, wc150, wc1b8: data of queue entries (billboard */
#define W_QueueBuffersSize           0x200    /* picture and palettes); measured: entries read C001-C1B9 */
#define W_BottomMessageBuffer        0xC600
#define W_StageCollisionMap          0xC700
#define W_SpriteBuffer               0xD000   /* $A0 bytes */
#define W_PaletteData                0xD200   /* $80 bytes, then fade buffers ($40 BG, $40 OBJ) */
/* VRAM tile data (offsets from $8000) of the window's dynamic graphics: status bar icons
 * and message letters, pause menu cursor (tiles $81-$8F, bank 0; $80 is the blank tile of
 * both fields). Measured with tools/pbdebug: the main program only writes $8830-$886F
 * there, and the field halves do not display these tiles. */
#define PB_WIN_TILES_LO              0x0810
#define PB_WIN_TILES_HI              0x0900
/* the status bar tiles ($8800-$88FF) as every field stage loads them, the same for both tables
 * and both halves: StageRedFieldTopStatusBarSymbolsGfx_GameBoyColor, ROM 27:4000 (both ROMs) */
#define ROM_StatusBarSymbols         0x9C000u
#define ROM_AsteriskGlyph            0xD6480u  /* InGameMenuSymbolsGfx + $80: the "*" of the bottom texts */

#define H_FarCallTempA               0xFF8A
#define H_SCY                        0xFFA0
#define H_SCX                        0xFFA1
#define H_WY                         0xFFA6

#define SCREEN_TITLESCREEN  3
#define SCREEN_PINBALL_GAME 4
#define SCREEN_POKEDEX      5
#define SCREEN_OPTIONS      6
#define SCREEN_HIGH_SCORES  7
#define SCREEN_FIELD_SELECT 8

#endif
