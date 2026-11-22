using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.IO;

[InitializeOnLoad]
public static class TycoonSceneBootstrap
{
    static TycoonSceneBootstrap()
    {
        EditorApplication.delayCall += EnsureScene;
    }

    static void EnsureScene()
    {
        const string folder="Assets/Scenes";
        const string scenePath=folder+"/Tycoon.unity";
        if (File.Exists(scenePath)) return;
        if (!AssetDatabase.IsValidFolder(folder)) AssetDatabase.CreateFolder("Assets","Scenes");
        Scene scene=EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects,NewSceneMode.Single);
        GameObject manager=new GameObject("Tycoon Game");
        manager.AddComponent<TycoonGame>();
        Camera cam=Camera.main;
        if(cam) { cam.tag="MainCamera"; cam.transform.position=new Vector3(0,13,-15); cam.transform.rotation=Quaternion.Euler(48,0,0); }
        EditorSceneManager.SaveScene(scene,scenePath);
        AssetDatabase.SaveAssets();
        EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(scenePath,true)};
        Debug.Log("Tycoon demo scene created at "+scenePath);
    }
}
