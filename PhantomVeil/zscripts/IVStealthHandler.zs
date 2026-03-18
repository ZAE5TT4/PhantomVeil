class IVStealthHandler : EventHandler
{
    private double playerCharge[MAXPLAYERS];
    private bool playerActive[MAXPLAYERS];
    private bool playerInitialized[MAXPLAYERS];
    private bool playerWasAlive[MAXPLAYERS];
    private int playerEffectCounter[MAXPLAYERS];

    private bool savedShadow[MAXPLAYERS];
    private bool savedCantSeek[MAXPLAYERS];
    private bool savedNoTargetCheat[MAXPLAYERS];

    private Actor lureActor;
    private int lureOwnerPlayer;
    private vector3 lurePosition;
    private bool lureWaitingForRemoval;

    override void OnRegister()
    {
        ResetAllRuntime();
    }

    override void NewGame()
    {
        ResetAllRuntime();
    }

    override void WorldLoaded(WorldEvent e)
    {
        double maxCharge = IVFunctions.GetMaxCharge();
        bool lureEnabled = IVFunctions.LureLogicEnabled();

        if (!lureEnabled && lureActor != null)
        {
            DestroyLure();
        }

        for (int i = 0; i < MAXPLAYERS; i++)
        {
            if (!PlayerInGame[i])
            {
                continue;
            }

            let pawn = PlayerPawn(players[i].mo);
            if (pawn == null)
            {
                continue;
            }

            if (!playerInitialized[i])
            {
                playerCharge[i] = maxCharge;
                playerActive[i] = false;
                playerEffectCounter[i] = 0;
                ClearSavedFlags(i);
            }
            else
            {
                playerCharge[i] = clamp(playerCharge[i], 0.0, maxCharge);

                if (playerActive[i] && pawn.health > 0)
                {
                    ApplyInvisibilityFlags(pawn, i, true);

                    if (lureEnabled && lureActor == null && lureOwnerPlayer == i)
                    {
                        CreateLureAtActivationPoint(i, pawn);
                    }
                }
            }

            playerInitialized[i] = true;
            playerWasAlive[i] = pawn.health > 0;
        }
    }

    override void WorldUnloaded(WorldEvent e)
    {
        DestroyLure();

        for (int i = 0; i < MAXPLAYERS; i++)
        {
            playerActive[i] = false;
            playerEffectCounter[i] = 0;
        }
    }

    override void PlayerEntered(PlayerEvent e)
    {
        if (e.PlayerNumber < 0 || e.PlayerNumber >= MAXPLAYERS)
        {
            return;
        }

        playerCharge[e.PlayerNumber] = IVFunctions.GetMaxCharge();
        playerActive[e.PlayerNumber] = false;
        playerInitialized[e.PlayerNumber] = true;
        playerWasAlive[e.PlayerNumber] = players[e.PlayerNumber].mo != null && players[e.PlayerNumber].mo.health > 0;
        playerEffectCounter[e.PlayerNumber] = 0;
        ClearSavedFlags(e.PlayerNumber);
    }

    override void PlayerDisconnected(PlayerEvent e)
    {
        if (e.PlayerNumber < 0 || e.PlayerNumber >= MAXPLAYERS)
        {
            return;
        }

        if (lureOwnerPlayer == e.PlayerNumber)
        {
            DestroyLure();
        }

        playerCharge[e.PlayerNumber] = 0.0;
        playerActive[e.PlayerNumber] = false;
        playerInitialized[e.PlayerNumber] = false;
        playerWasAlive[e.PlayerNumber] = false;
        playerEffectCounter[e.PlayerNumber] = 0;
        ClearSavedFlags(e.PlayerNumber);
    }

    override void NetworkProcess(ConsoleEvent e)
    {
        if (!(e.Name ~== "inv_activate"))
        {
            return;
        }

        int playerNumber = e.Player;
        if (!IsValidPlayerNumber(playerNumber))
        {
            return;
        }

        let pawn = PlayerPawn(players[playerNumber].mo);
        if (pawn == null || pawn.health <= 0)
        {
            return;
        }

        if (!playerInitialized[playerNumber])
        {
            playerCharge[playerNumber] = IVFunctions.GetMaxCharge();
            playerActive[playerNumber] = false;
            playerInitialized[playerNumber] = true;
            playerWasAlive[playerNumber] = true;
            playerEffectCounter[playerNumber] = 0;
            ClearSavedFlags(playerNumber);
        }

        if (playerActive[playerNumber])
        {
            StopInvisibility(playerNumber, true);
            return;
        }

        if (playerCharge[playerNumber] <= 0.0)
        {
            return;
        }

        StartInvisibility(playerNumber, true);
    }

    override void WorldTick()
    {
        double maxCharge = IVFunctions.GetMaxCharge();
        double rechargePerTic = IVFunctions.GetRegenSpeed();
        bool lureEnabled = IVFunctions.LureLogicEnabled();

        if (!lureEnabled && lureActor != null)
        {
            DestroyLure();
        }

        for (int i = 0; i < MAXPLAYERS; i++)
        {
            if (playerEffectCounter[i] > 0)
            {
                playerEffectCounter[i]--;
            }
            else if (playerEffectCounter[i] < 0)
            {
                playerEffectCounter[i]++;
            }

            if (!PlayerInGame[i])
            {
                continue;
            }

            let pawn = PlayerPawn(players[i].mo);
            if (pawn == null)
            {
                if (lureOwnerPlayer == i)
                {
                    DestroyLure();
                }

                playerActive[i] = false;
                playerWasAlive[i] = false;
                continue;
            }

            if (!playerInitialized[i])
            {
                playerCharge[i] = maxCharge;
                playerActive[i] = false;
                playerInitialized[i] = true;
                playerEffectCounter[i] = 0;
                ClearSavedFlags(i);
            }

            bool aliveNow = pawn.health > 0;
            if (!aliveNow)
            {
                if (playerActive[i])
                {
                    StopInvisibility(i, false);
                }

                if (lureOwnerPlayer == i)
                {
                    DestroyLure();
                }

                playerCharge[i] = maxCharge;
                playerWasAlive[i] = false;
                continue;
            }

            if (!playerWasAlive[i] && aliveNow)
            {
                playerCharge[i] = maxCharge;
                playerActive[i] = false;
                playerEffectCounter[i] = 0;
                ClearSavedFlags(i);

                if (lureOwnerPlayer == i)
                {
                    DestroyLure();
                }
            }
            playerWasAlive[i] = true;

            playerCharge[i] = clamp(playerCharge[i], 0.0, maxCharge);

            if (playerActive[i])
            {
                ApplyInvisibilityFlags(pawn, i, true);

                if (lureEnabled)
                {
                    if (lureActor == null || lureOwnerPlayer != i)
                    {
                        CreateLureAtActivationPoint(i, pawn);
                    }

                    if ((level.time & 7) == 0)
                    {
                        RedirectMonstersToLure(pawn);
                    }
                }

                playerCharge[i] -= 1.0;
                if (playerCharge[i] <= 0.0)
                {
                    playerCharge[i] = 0.0;
                    StopInvisibility(i, true);
                }
            }
            else if (playerCharge[i] < maxCharge)
            {
                playerCharge[i] += rechargePerTic;
                if (playerCharge[i] > maxCharge)
                {
                    playerCharge[i] = maxCharge;
                }
            }
        }

        if (lureEnabled)
        {
            UpdateLure();
        }
    }

    override void RenderOverlay(RenderEvent e)
    {
        int playerNumber = consoleplayer;
        bool validPlayer = playerNumber >= 0 && playerNumber < MAXPLAYERS && PlayerInGame[playerNumber];

        if (gamestate == GS_TITLELEVEL || !validPlayer)
        {
            DisableAllShadersUI();
            return;
        }

        PlayerInfo p = players[playerNumber];
        let pawn = PlayerPawn(p.mo);
        if (pawn == null)
        {
            DisableAllShadersUI();
            return;
        }

        bool useStealthShader = IVFunctions.StealthShaderEnabled(p);
        bool useBlurShader = IVFunctions.BlurShaderEnabled(p);
        bool activeOrFlashing = playerActive[playerNumber] || playerEffectCounter[playerNumber] != 0;

        if (useStealthShader && activeOrFlashing)
        {
            Shader.SetUniform1i(p, "ivshader", "ivActive", playerActive[playerNumber] ? 1 : 0);
            Shader.SetUniform1i(p, "ivshader", "ivEffectCounter", playerEffectCounter[playerNumber]);
            Shader.SetEnabled(p, "ivshader", true);
        }
        else
        {
            Shader.SetEnabled(p, "ivshader", false);
        }

        if (useBlurShader && activeOrFlashing)
        {
            double phase;
            if (playerActive[playerNumber])
            {
                phase = double(level.time % 24) / 24.0;
                if (phase > 0.5)
                {
                    phase = 1.0 - phase;
                }
                phase *= 2.0;
            }
            else
            {
                phase = double(abs(playerEffectCounter[playerNumber])) / 12.0;
            }

            int samples = 5 + int(phase * 4.0);
            if (samples < 1)
            {
                samples = 1;
            }

            double distance = 3.0 + (phase * 5.0);
            double increment = 1.0 / samples;
            vector2 steps = (distance / Screen.GetWidth(), distance / Screen.GetHeight()) * increment;

            Shader.SetUniform2f(p, "ivloop", "steps", steps);
            Shader.SetUniform1i(p, "ivloop", "samples", samples);
            Shader.SetUniform1f(p, "ivloop", "increment", increment);
            Shader.SetEnabled(p, "ivloop", true);
        }
        else
        {
            Shader.SetEnabled(p, "ivloop", false);
        }

        if (!IVFunctions.ShowHud(p))
        {
            return;
        }

        TextureID inactiveTexture = TexMan.CheckForTexture("IVPL", TexMan.Type_Any);
        TextureID activeTexture = TexMan.CheckForTexture("IVPM", TexMan.Type_Any);
        TextureID drawTexture = inactiveTexture;

        if (playerActive[playerNumber] && activeTexture.isValid())
        {
            drawTexture = activeTexture;
        }
        else if (!inactiveTexture.isValid() && activeTexture.isValid())
        {
            drawTexture = activeTexture;
        }

        if (!drawTexture.isValid())
        {
            return;
        }

        vector2 textureSize = TexMan.GetScaledSize(drawTexture);
        if (textureSize.x <= 0 || textureSize.y <= 0)
        {
            return;
        }

        double maxCharge = IVFunctions.GetMaxCharge();
        double ratio = maxCharge > 0 ? playerCharge[playerNumber] / maxCharge : 0.0;
        ratio = clamp(ratio, 0.0, 1.0);

        double offsetXPct = double(IVFunctions.GetCounterHorizontalOffset(p)) / 100.0;
        double offsetYPct = double(IVFunctions.GetCounterVerticalOffset(p)) / 100.0;
        int scalePercent = IVFunctions.GetCounterScalePercent(p);
        double scaleFactor = double(scalePercent) / 100.0;

        int destWidth = int((textureSize.x * scaleFactor) + 0.5);
        int destHeight = int((textureSize.y * scaleFactor) + 0.5);

        if (destWidth < 1) destWidth = 1;
        if (destHeight < 1) destHeight = 1;

        int drawX = int((Screen.GetWidth() * offsetXPct) - (destWidth * offsetXPct));
        int drawY = int((Screen.GetHeight() * offsetYPct) - (destHeight * offsetYPct));
        double srcY = textureSize.y - (textureSize.y * ratio);

        Screen.DrawTexture(
            drawTexture,
            false,
            drawX,
            drawY,
            DTA_Alpha, 0.22,
            DTA_DestWidth, destWidth,
            DTA_DestHeight, destHeight
        );

        Screen.DrawTexture(
            drawTexture,
            false,
            drawX,
            drawY,
            DTA_SrcY, srcY,
            DTA_DestWidth, destWidth,
            DTA_DestHeight, destHeight,
            DTA_TopOffsetF, -srcY
        );
    }

    private void StartInvisibility(int playerNumber, bool playSound)
    {
        let pawn = PlayerPawn(players[playerNumber].mo);
        if (pawn == null)
        {
            return;
        }

        savedShadow[playerNumber] = pawn.bShadow;
        savedCantSeek[playerNumber] = pawn.bCantSeek;
        savedNoTargetCheat[playerNumber] = (players[playerNumber].cheats & CF_NOTARGET) != 0;

        playerActive[playerNumber] = true;
        playerEffectCounter[playerNumber] = 12;

        ApplyInvisibilityFlags(pawn, playerNumber, true);

        if (IVFunctions.LureLogicEnabled())
        {
            CreateLureAtActivationPoint(playerNumber, pawn);
            RedirectMonstersToLure(pawn);
        }

        if (playSound)
        {
            pawn.A_StartSound("iv/start", CHAN_AUTO, CHANF_UI | CHANF_LOCAL, 1.0, ATTN_NONE);
        }
    }

    private void StopInvisibility(int playerNumber, bool playSound)
    {
        let pawn = PlayerPawn(players[playerNumber].mo);
        if (pawn != null)
        {
            ApplyInvisibilityFlags(pawn, playerNumber, false);

            if (playSound)
            {
                pawn.A_StartSound("iv/stop", CHAN_AUTO, CHANF_UI | CHANF_LOCAL, 1.0, ATTN_NONE);
            }
        }

        playerActive[playerNumber] = false;
        playerEffectCounter[playerNumber] = -8;

        if (IVFunctions.LureLogicEnabled())
        {
            if (lureOwnerPlayer == playerNumber && lureActor != null)
            {
                lureWaitingForRemoval = true;
                ReleaseMonstersFromLure();
            }
        }
        else
        {
            if (lureOwnerPlayer == playerNumber)
            {
                DestroyLure();
            }
        }
    }

    private void ApplyInvisibilityFlags(PlayerPawn pawn, int playerNumber, bool enable)
    {
        if (pawn == null)
        {
            return;
        }

        if (enable)
        {
            pawn.bShadow = true;
            pawn.bCantSeek = true;
            players[playerNumber].cheats |= CF_NOTARGET;
        }
        else
        {
            pawn.bShadow = savedShadow[playerNumber];
            pawn.bCantSeek = savedCantSeek[playerNumber];

            if (savedNoTargetCheat[playerNumber])
            {
                players[playerNumber].cheats |= CF_NOTARGET;
            }
            else
            {
                players[playerNumber].cheats &= ~CF_NOTARGET;
            }
        }
    }

    private void CreateLureAtActivationPoint(int playerNumber, PlayerPawn pawn)
    {
        if (pawn == null)
        {
            return;
        }

        DestroyLure();

        lureOwnerPlayer = playerNumber;
        lureWaitingForRemoval = false;
        lurePosition = (pawn.pos.x + 48.0, pawn.pos.y, pawn.pos.z + 20.0);

        lureActor = Actor.Spawn("IVLureBeacon", lurePosition);
        if (lureActor != null)
        {
            lureActor.SetOrigin(lurePosition, true);
        }
    }

    private void UpdateLure()
    {
        if (lureActor == null)
        {
            return;
        }

        if (!IsValidPlayerNumber(lureOwnerPlayer))
        {
            DestroyLure();
            return;
        }

        let pawn = PlayerPawn(players[lureOwnerPlayer].mo);
        if (pawn == null || pawn.health <= 0)
        {
            DestroyLure();
            return;
        }

        if (playerActive[lureOwnerPlayer])
        {
            if ((level.time & 7) == 0)
            {
                RedirectMonstersToLure(pawn);
            }
            return;
        }

        if (!lureWaitingForRemoval)
        {
            return;
        }

        if ((level.time & 3) == 0)
        {
            ReleaseMonstersFromLure();
        }

        if (AnyMonsterReacquiredPlayer(pawn) || PlayerIsDrawingAttention(lureOwnerPlayer))
        {
            DestroyLure();
        }
    }

    private void RedirectMonstersToLure(PlayerPawn pawn)
    {
        if (pawn == null || lureActor == null)
        {
            return;
        }

        Actor mo;
        ThinkerIterator thinker = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);

        while ((mo = Actor(thinker.Next())))
        {
            if (mo == null || !mo.bIsMonster || mo.health <= 0 || mo == lureActor)
            {
                continue;
            }

            if (mo.target == pawn || mo.LastHeard == pawn || mo.LastEnemy == pawn || mo.LastLookActor == pawn)
            {
                mo.target = lureActor;
                mo.LastHeard = lureActor;
                mo.LastEnemy = lureActor;
                mo.LastLookActor = lureActor;
            }
        }
    }

    private void ReleaseMonstersFromLure()
    {
        if (lureActor == null)
        {
            return;
        }

        Actor mo;
        ThinkerIterator thinker = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);

        while ((mo = Actor(thinker.Next())))
        {
            if (mo == null || !mo.bIsMonster || mo.health <= 0)
            {
                continue;
            }

            if (mo.target == lureActor)
            {
                mo.target = null;
            }

            if (mo.LastHeard == lureActor)
            {
                mo.LastHeard = null;
            }

            if (mo.LastEnemy == lureActor)
            {
                mo.LastEnemy = null;
            }

            if (mo.LastLookActor == lureActor)
            {
                mo.LastLookActor = null;
            }
        }
    }

    private bool AnyMonsterReacquiredPlayer(PlayerPawn pawn)
    {
        if (pawn == null)
        {
            return false;
        }

        Actor mo;
        ThinkerIterator thinker = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);

        while ((mo = Actor(thinker.Next())))
        {
            if (mo == null || !mo.bIsMonster || mo.health <= 0)
            {
                continue;
            }

            if (mo.target == pawn || mo.LastHeard == pawn || mo.LastEnemy == pawn || mo.LastLookActor == pawn)
            {
                return true;
            }
        }

        return false;
    }

    private bool PlayerIsDrawingAttention(int playerNumber)
    {
        if (!IsValidPlayerNumber(playerNumber))
        {
            return false;
        }

        int buttons = players[playerNumber].cmd.buttons;
        return (buttons & (BT_ATTACK | BT_ALTATTACK | BT_USE)) != 0;
    }

    private void DestroyLure()
    {
        if (lureActor != null)
        {
            let doomed = lureActor;
            lureActor = null;
            doomed.Destroy();
        }

        lureOwnerPlayer = -1;
        lureWaitingForRemoval = false;
        lurePosition = (0, 0, 0);
    }

    private bool IsValidPlayerNumber(int playerNumber)
    {
        return playerNumber >= 0 && playerNumber < MAXPLAYERS && PlayerInGame[playerNumber];
    }

    private ui void DisableAllShadersUI()
    {
        if (consoleplayer >= 0 && consoleplayer < MAXPLAYERS && PlayerInGame[consoleplayer])
        {
            let p = players[consoleplayer];
            Shader.SetEnabled(p, "ivshader", false);
            Shader.SetEnabled(p, "ivloop", false);
        }
    }

    private void ResetAllRuntime()
    {
        DestroyLure();

        for (int i = 0; i < MAXPLAYERS; i++)
        {
            playerCharge[i] = 0.0;
            playerActive[i] = false;
            playerInitialized[i] = false;
            playerWasAlive[i] = false;
            playerEffectCounter[i] = 0;
            ClearSavedFlags(i);
        }
    }

    private void ClearSavedFlags(int playerNumber)
    {
        savedShadow[playerNumber] = false;
        savedCantSeek[playerNumber] = false;
        savedNoTargetCheat[playerNumber] = false;
    }
}