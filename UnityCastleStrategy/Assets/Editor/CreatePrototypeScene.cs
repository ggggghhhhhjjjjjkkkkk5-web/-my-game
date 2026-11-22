#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.IO;

public static class CreatePrototypeScene
{
    [MenuItem("Tools/Kingdoms of Color/Create Prototype Scene")]
    public static void Create()
    {
        const string folder = "Assets/Scenes";
        if (!AssetDatabase.IsValidFolder(folder))
        {
            if (!AssetDatabase.IsValidFolder("Assets"))
                AssetDatabase.CreateFolder("Assets", "Scenes");
            else
                AssetDatabase.CreateFolder("Assets", "Scenes");
        }

        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var root = new GameObject("PrototypeBootstrap");
        root.AddComponent<PrototypeBootstrap>();

        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        EditorSceneManager.SaveScene(scene, folder + "/Main.unity");

        var scenes = new System.Collections.Generic.List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
        const string scenePath = "Assets/Scenes/Main.unity";
        if (!scenes.Exists(s => s.path == scenePath))
            scenes.Add(new EditorBuildSettingsScene(scenePath, true));
        EditorBuildSettings.scenes = scenes.ToArray();

        AssetDatabase.Refresh();
        Debug.Log("Kingdoms of Color prototype scene created and added to Build Settings.");
    }
}
#endif
