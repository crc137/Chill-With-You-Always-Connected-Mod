using Bulbul;
using HarmonyLib;

namespace AlwaysConnected
{
    [HarmonyPatch(typeof(GamePlayingDefectDirection), nameof(GamePlayingDefectDirection.CheckNeedUseDefectDirection))]
    internal static class CheckNeedUseDefectDirectionPatch
    {
        private static void Postfix(ref GamePlayingDefectDirection.DefectType __result)
        {
            if (__result != GamePlayingDefectDirection.DefectType.ConnectionLost) return;
            if (!ConnectionPatches.Enabled) return;

            __result = GamePlayingDefectDirection.DefectType.None;
            ConnectionPatches.LogOnce(ref ConnectionPatches.LoggedBlocked, "blocked the scripted ConnectionLost");
        }
    }

    [HarmonyPatch(typeof(GamePlayingDefectDirection), nameof(GamePlayingDefectDirection.PlayDefectDirection))]
    internal static class PlayDefectDirectionPatch
    {
        private static void Postfix(GamePlayingDefectDirection __instance, GamePlayingDefectDirection.DefectType defectType)
        {
            ConnectionPatches.Defect = __instance;

            if (defectType != GamePlayingDefectDirection.DefectType.ConnectionLost) return;
            if (!ConnectionPatches.Enabled) return;

            __instance.PlayDefectDirection(GamePlayingDefectDirection.DefectType.None);
            ConnectionPatches.LogOnce(ref ConnectionPatches.LoggedReverted, "reverted an applied ConnectionLost back to None");
        }
    }

    [HarmonyPatch(typeof(ScenarioProgressData), nameof(ScenarioProgressData.IsPossibleTalkNextMainEpisode))]
    internal static class IsPossibleTalkNextMainEpisodePatch
    {
        private static void Postfix(ScenarioProgressData __instance, ref bool __result)
        {
            if (__result) return;
            if (__instance.NextEpisodeNumber != 32f) return;
            if (!ConnectionPatches.Enabled) return;

            __result = true;
            ConnectionPatches.LogOnce(ref ConnectionPatches.LoggedUnlocked, "episode 32 talk unlocked, skipping the 50 minute wait");
        }
    }

    [HarmonyPatch(typeof(GamePlayingDefectDirection), nameof(GamePlayingDefectDirection.Setup))]
    internal static class DefectSetupPatch
    {
        private static void Postfix(GamePlayingDefectDirection __instance)
        {
            ConnectionPatches.Defect = __instance;
        }
    }

    internal static class ConnectionPatches
    {
        internal static GamePlayingDefectDirection Defect;

        internal static bool LoggedBlocked;
        internal static bool LoggedReverted;
        internal static bool LoggedUnlocked;

        internal static bool Enabled
        {
            get
            {
                var cfg = AlwaysConnectedPlugin.CfgEnabled;
                return cfg != null && cfg.Value;
            }
        }

        internal static void LogOnce(ref bool flag, string message)
        {
            if (flag) return;
            flag = true;
            AlwaysConnectedPlugin.Log?.LogInfo(message);
        }
    }
}