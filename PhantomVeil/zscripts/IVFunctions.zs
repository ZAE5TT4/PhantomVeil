class IVFunctions : Object
{
    static int GetDurationSeconds()
    {
        let cv = CVar.GetCVar('iv_duration');
        if (cv == null)
        {
            return 15;
        }

        return clamp(cv.GetInt(), 5, 120);
    }

    static int GetMaxCharge()
    {
        return GetDurationSeconds() * 35;
    }

    static int GetRegenSpeed()
    {
        let cv = CVar.GetCVar('iv_regen_speed');
        if (cv == null)
        {
            return 6;
        }

        return clamp(cv.GetInt(), 0, 35);
    }

    static bool LureLogicEnabled()
    {
        let cv = CVar.GetCVar('iv_lure_enable');
        if (cv == null)
        {
            return true;
        }

        return cv.GetBool();
    }

    static bool ShowHud(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_show_hud', p);
        if (cv == null)
        {
            return true;
        }

        return cv.GetBool();
    }

    static int GetCounterHorizontalOffset(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_counter_horizontal_offset', p);
        if (cv == null)
        {
            return 95;
        }

        return clamp(cv.GetInt(), 0, 100);
    }

    static int GetCounterVerticalOffset(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_counter_vertical_offset', p);
        if (cv == null)
        {
            return 10;
        }

        return clamp(cv.GetInt(), 0, 100);
    }

    static int GetCounterScale(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_counter_scale', p);
        if (cv == null)
        {
            return 100;
        }

        int value = cv.GetInt();

        if (value >= 1 && value <= 10)
        {
            return 50 + ((value - 1) * 6);
        }

        return clamp(value, 50, 250);
    }

    static int GetCounterScalePercent(PlayerInfo p)
    {
        return GetCounterScale(p);
    }

    static int GetUIScale(PlayerInfo p)
    {
        let cv = CVar.GetCVar('uiscale', p);
        if (cv == null)
        {
            return 1;
        }

        int value = cv.GetInt();
        if (value < 1)
        {
            value = 1;
        }

        return clamp(value, 1, 4);
    }

    static bool StealthShaderEnabled(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_shader_stealth_enable', p);
        if (cv == null)
        {
            return true;
        }

        return cv.GetBool();
    }

    static bool BlurShaderEnabled(PlayerInfo p)
    {
        let cv = CVar.GetCVar('iv_shader_blur_enable', p);
        if (cv == null)
        {
            return true;
        }

        return cv.GetBool();
    }
}