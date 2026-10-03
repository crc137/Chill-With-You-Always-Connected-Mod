using Bulbul;
using UnityEngine;

namespace AlwaysConnected
{
    internal sealed class ConnectionWatchdog : MonoBehaviour
    {
        private const float Interval = 2f;
        private const float StatusEvery = 10f;

        private float _nextCheck;
        private float _nextStatus;

        private void Update()
        {
            if (!ConnectionPatches.Enabled) return;
            if (Time.unscaledTime < _nextCheck) return;
            _nextCheck = Time.unscaledTime + Interval;

            if (AlwaysConnectedPlugin.CfgVerboseState != null
                && AlwaysConnectedPlugin.CfgVerboseState.Value
                && Time.unscaledTime >= _nextStatus)
            {
                _nextStatus = Time.unscaledTime + StatusEvery;
                LogState();
            }

            GamePlayingDefectDirection defect = ConnectionPatches.Defect;
            if (defect == null || !defect.IsConnectionLost()) return;

            try
            {
                defect.PlayDefectDirection(GamePlayingDefectDirection.DefectType.None);
                AlwaysConnectedPlugin.Log?.LogWarning("cleared an active connection-lost state");
            }
            catch (System.Exception e)
            {
                AlwaysConnectedPlugin.Log?.LogError("could not clear connection-lost state: " + e.Message);
            }
        }

        internal static void LogState()
        {
            GamePlayingDefectDirection defect = ConnectionPatches.Defect;
            if (defect == null) return;

            ScenarioProgressData progress = SaveDataManager.Instance.ScenarioProgressData;

            AlwaysConnectedPlugin.Log?.LogInfo(
                "state | connectionLost=" + defect.IsConnectionLost()
                + " nextEp=" + progress.NextEpisodeNumber
                + " finishEp=" + progress.FinishReadMainEpisodeNumber
                + " canShowLost=" + progress.CanShowConnectionLostNextEpisode
                + " talkNextEp=" + progress.IsPossibleTalkNextMainEpisode()
                + " level=" + SaveDataManager.Instance.PlayerData.LevelData.CurrentLevel
                + " reconnectLevel=" + MyDefine.IsPossibleReconnectLevel);
        }
    }
}