using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEditor.Build.Reporting;
using System.IO;

public static class TycoonAndroidBuild
{
    public static void BuildAndroid()
    {
        const string folder = "Assets/Scenes";
        const string scenePath = folder + "/Tycoon.unity";
        if (!AssetDatabase.IsValidFolder(folder))
            AssetDatabase.CreateFolder("Assets", "Scenes");

        if (!File.Exists(scenePath))
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            var manager = new GameObject("Tycoon Game");
            manager.AddComponent<TycoonGame>();
            var cam = Camera.main;
            if (cam)
            {
                cam.tag = "MainCamera";
                cam.transform.position = new Vector3(0, 13, -15);
                cam.transform.rotation = Quaternion.Euler(48, 0, 0);
            }
            EditorSceneManager.SaveScene(scene, scenePath);
        }

        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.tycoon.citybuilder");
        PlayerSettings.productName = "شهرک ساز";
        PlayerSettings.companyName = "Indie Studio";
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
        EditorUserBuildSettings.buildAppBundle = false;

        Directory.CreateDirectory("Builds/Android");
        var options = new BuildPlayerOptions
        {
            scenes = new[] { scenePath },
            locationPathName = "Builds/Android/ShahrakSaz.apk",
            target = BuildTarget.Android,
            options = BuildOptions.None
        };
        BuildReport report = BuildPipeline.BuildPlayer(options);
        if (report.summary.result != BuildResult.Succeeded)
            throw new System.Exception("Android build failed: " + report.summary.result);
        Debug.Log("APK created: " + options.locationPathName);
    }
}
