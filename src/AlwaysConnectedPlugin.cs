using System;
using BepInEx;
using BepInEx.Configuration;
using BepInEx.Logging;
using HarmonyLib;
using UnityEngine;

namespace AlwaysConnected
{
    [BepInPlugin(GUID, PluginName, Version)]
    public class AlwaysConnectedPlugin : BaseUnityPlugin
    {
        public const string GUID = "crc137.chillwithyou.alwaysconnected";
        public const string PluginName = "Always Connected";
        public const string Version = "26.1.0";

        internal static ManualLogSource Log;
        internal static ConfigEntry<bool> CfgEnabled;
        internal static ConfigEntry<bool> CfgVerboseState;

        private Harmony _harmony;

        private void Awake()
        {
            Log = Logger;

            CfgEnabled = Config.Bind("Connection", "SkipConnectionLost", true, "Never let the game cut the heroine off. Disables the scripted \"connection lost\" event that blocks talking to her.");

            CfgVerboseState = Config.Bind("Connection", "VerboseState", false, "Log the heroine's connection state every 10 seconds. Only needed for troubleshooting.");

            _harmony = new Harmony(GUID);
            try
            {
                _harmony.PatchAll();
                Log.LogInfo("harmony patches applied");
                foreach (var method in _harmony.GetPatchedMethods())
                {
                    Log.LogInfo("  patched: " + method.DeclaringType?.Name + "." + method.Name);
                }
            }
            catch (Exception e)
            {
                Log.LogError("harmony PatchAll failed: " + e);
            }

            ConnectionWatchdog watchdog = new GameObject("AlwaysConnectedWatchdog").AddComponent<ConnectionWatchdog>();
            UnityEngine.Object.DontDestroyOnLoad(watchdog.gameObject);

            if (ConnectionPatches.Enabled)
            {
                Log.LogInfo("always-connected active (SkipConnectionLost = true)");
            }
            else
            {
                Log.LogInfo("always-connected installed but disabled (SkipConnectionLost = false), original event will play");
            }
        }
    }
}