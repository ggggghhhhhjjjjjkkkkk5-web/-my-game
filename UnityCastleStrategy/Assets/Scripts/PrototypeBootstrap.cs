using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;

public class PrototypeBootstrap : MonoBehaviour
{
    private int coins = 250;
    private Text resourceText;
    private Transform buildingRoot;
    private Camera gameCamera;
    private Vector2 lastPointer;
    private bool dragging;

    private void Start()
    {
        Application.targetFrameRate = 60;
        BuildWorld();
        BuildCamera();
        BuildUI();
    }

    private Material Mat(Color color)
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");
        var material = new Material(shader);
        material.color = color;
        return material;
    }

    private GameObject Cube(string name, Vector3 position, Vector3 scale, Material material, Transform parent = null)
    {
        var obj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        obj.name = name;
        obj.transform.SetParent(parent);
        obj.transform.position = position;
        obj.transform.localScale = scale;
        obj.GetComponent<Renderer>().material = material;
        return obj;
    }

    private GameObject Cylinder(string name, Vector3 position, Vector3 scale, Material material, Transform parent = null)
    {
        var obj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        obj.name = name;
        obj.transform.SetParent(parent);
        obj.transform.position = position;
        obj.transform.localScale = scale;
        obj.GetComponent<Renderer>().material = material;
        return obj;
    }

    private void BuildWorld()
    {
        var grass = Mat(new Color(0.35f, 0.72f, 0.34f));
        var grassLight = Mat(new Color(0.48f, 0.82f, 0.40f));
        var stone = Mat(new Color(0.72f, 0.72f, 0.68f));
        var stoneDark = Mat(new Color(0.42f, 0.45f, 0.46f));
        var roof = Mat(new Color(0.88f, 0.30f, 0.22f));
        var wood = Mat(new Color(0.48f, 0.27f, 0.13f));
        var leaf = Mat(new Color(0.15f, 0.52f, 0.24f));
        var gold = Mat(new Color(1.0f, 0.72f, 0.12f));
        var water = Mat(new Color(0.20f, 0.62f, 0.83f));

        Cube("Meadow", Vector3.zero, new Vector3(38f, 0.5f, 38f), grass);
        Cube("River", new Vector3(-13f, 0.02f, 1f), new Vector3(5f, 0.08f, 39f), water);
        buildingRoot = new GameObject("Buildings").transform;

        // Central keep and colorful towers
        Cube("Castle Keep", new Vector3(0f, 1.7f, 0f), new Vector3(5.5f, 3.4f, 5f), stone, buildingRoot);
        Cube("Keep Roof", new Vector3(0f, 3.55f, 0f), new Vector3(6f, 0.35f, 5.5f), roof, buildingRoot);
        Tower(-3.0f, -2.7f, stone, roof);
        Tower(3.0f, -2.7f, stone, roof);
        Tower(-3.0f, 2.7f, stone, roof);
        Tower(3.0f, 2.7f, stone, roof);
        Cube("Gate", new Vector3(0f, 0.9f, -2.58f), new Vector3(1.6f, 1.8f, 0.16f), wood, buildingRoot);
        Cube("Banner Pole", new Vector3(0f, 5.1f, 0f), new Vector3(0.12f, 3f, 0.12f), gold, buildingRoot);
        Cube("Kingdom Banner", new Vector3(0.55f, 5.7f, 0f), new Vector3(1.1f, 0.65f, 0.08f), roof, buildingRoot);

        // Simple walls and a road
        Cube("North Wall", new Vector3(0f, 0.9f, 5.2f), new Vector3(13f, 1.8f, 0.7f), stoneDark, buildingRoot);
        Cube("South Wall", new Vector3(0f, 0.9f, -5.2f), new Vector3(13f, 1.8f, 0.7f), stoneDark, buildingRoot);
        Cube("East Wall", new Vector3(6.2f, 0.9f, 0f), new Vector3(0.7f, 1.8f, 10.5f), stoneDark, buildingRoot);
        Cube("West Wall", new Vector3(-6.2f, 0.9f, 0f), new Vector3(0.7f, 1.8f, 10.5f), stoneDark, buildingRoot);
        Cube("Road", new Vector3(0f, 0.28f, -10f), new Vector3(2.5f, 0.08f, 10f), Mat(new Color(0.72f, 0.59f, 0.39f)));

        // Trees around the settlement
        for (int i = 0; i < 18; i++)
        {
            float x = Mathf.Sin(i * 2.4f) * 14f;
            float z = Mathf.Cos(i * 1.7f) * 14f;
            if (Mathf.Abs(x) < 8f && Mathf.Abs(z) < 8f) continue;
            Cylinder("Tree Trunk", new Vector3(x, 0.9f, z), new Vector3(0.45f, 0.9f, 0.45f), wood);
            var crown = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown.name = "Round Tree Crown";
            crown.transform.position = new Vector3(x, 2.25f, z);
            crown.transform.localScale = new Vector3(2f, 2.2f, 2f);
            crown.GetComponent<Renderer>().material = leaf;
        }

        // Decorative resource piles
        for (int i = 0; i < 5; i++)
        {
            float x = 9f + i * 1.5f;
            Cylinder("Gold Deposit", new Vector3(x, 0.6f, -7f), new Vector3(0.9f, 0.6f, 0.9f), gold);
        }

        RenderSettings.ambientLight = new Color(0.72f, 0.76f, 0.82f);
    }

    private void Tower(float x, float z, Material stone, Material roof)
    {
        Cylinder("Castle Tower", new Vector3(x, 2.0f, z), new Vector3(1.35f, 2f, 1.35f), stone, buildingRoot);
        var cap = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        cap.name = "Tower Roof";
        cap.transform.position = new Vector3(x, 4.2f, z);
        cap.transform.localScale = new Vector3(1.6f, 0.35f, 1.6f);
        cap.GetComponent<Renderer>().material = roof;
        cap.transform.SetParent(buildingRoot);
    }

    private void BuildCamera()
    {
        var cameraObject = new GameObject("Main Camera");
        gameCamera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        cameraObject.transform.position = new Vector3(18f, 22f, -22f);
        cameraObject.transform.rotation = Quaternion.Euler(42f, -38f, 0f);
        gameCamera.fieldOfView = 42f;
        gameCamera.clearFlags = CameraClearFlags.SolidColor;
        gameCamera.backgroundColor = new Color(0.58f, 0.78f, 0.92f);
        cameraObject.AddComponent<AudioListener>();
    }

    private void BuildUI()
    {
        var canvasObject = new GameObject("Game HUD");
        var canvas = canvasObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvasObject.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        canvasObject.GetComponent<CanvasScaler>().referenceResolution = new Vector2(1080, 1920);
        canvasObject.AddComponent<GraphicRaycaster>();

        var eventSystem = new GameObject("EventSystem");
        eventSystem.AddComponent<EventSystem>();
        eventSystem.AddComponent<StandaloneInputModule>();

        var panel = new GameObject("Top Panel").AddComponent<Image>();
        panel.transform.SetParent(canvas.transform, false);
        panel.color = new Color(0.12f, 0.22f, 0.19f, 0.88f);
        var panelRect = panel.rectTransform;
        panelRect.anchorMin = new Vector2(0.04f, 0.91f);
        panelRect.anchorMax = new Vector2(0.96f, 0.985f);
        panelRect.offsetMin = Vector2.zero;
        panelRect.offsetMax = Vector2.zero;

        resourceText = MakeText(canvas.transform, "Coins: " + coins, 30, new Vector2(0.08f, 0.92f), new Vector2(0.5f, 0.98f));
        MakeButton(canvas.transform, "Build House (80)", new Vector2(0.08f, 0.025f), new Vector2(0.48f, 0.095f), BuildHouse);
        MakeButton(canvas.transform, "More Soon", new Vector2(0.52f, 0.025f), new Vector2(0.92f, 0.095f), () => { });
    }

    private Text MakeText(Transform parent, string value, int size, Vector2 min, Vector2 max)
    {
        var obj = new GameObject("HUD Text");
        obj.transform.SetParent(parent, false);
        var text = obj.AddComponent<Text>();
        text.text = value;
        text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        text.fontSize = size;
        text.color = Color.white;
        text.alignment = TextAnchor.MiddleCenter;
        var rect = text.rectTransform;
        rect.anchorMin = min;
        rect.anchorMax = max;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
        return text;
    }

    private void MakeButton(Transform parent, string label, Vector2 min, Vector2 max, UnityEngine.Events.UnityAction action)
    {
        var obj = new GameObject(label);
        obj.transform.SetParent(parent, false);
        var image = obj.AddComponent<Image>();
        image.color = new Color(0.92f, 0.58f, 0.16f, 0.98f);
        var button = obj.AddComponent<Button>();
        button.targetGraphic = image;
        button.onClick.AddListener(action);
        var rect = obj.GetComponent<RectTransform>();
        rect.anchorMin = min;
        rect.anchorMax = max;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
        MakeText(obj.transform, label, 26, Vector2.zero, Vector2.one);
    }

    private void BuildHouse()
    {
        if (coins < 80)
        {
            resourceText.text = "Not enough coins!";
            return;
        }
        coins -= 80;
        float x = Random.Range(-9f, 9f);
        float z = Random.Range(-11f, 11f);
        var wall = Mat(new Color(0.93f, 0.78f, 0.48f));
        var roof = Mat(new Color(0.78f, 0.24f, 0.18f));
        Cube("Small House", new Vector3(x, 1f, z), new Vector3(2.2f, 2f, 2.2f), wall, buildingRoot);
        Cube("House Roof", new Vector3(x, 2.15f, z), new Vector3(2.7f, 0.45f, 2.7f), roof, buildingRoot);
        resourceText.text = "Coins: " + coins;
    }

    private void Update()
    {
        if (gameCamera == null) return;
        if (Input.touchCount == 1)
        {
            var touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Moved)
                gameCamera.transform.position -= new Vector3(touch.deltaPosition.x, 0f, touch.deltaPosition.y) * 0.025f;
        }
        else if (Input.GetMouseButtonDown(0))
        {
            lastPointer = Input.mousePosition;
            dragging = true;
        }
        else if (Input.GetMouseButtonUp(0)) dragging = false;
        else if (dragging && Input.GetMouseButton(0))
        {
            Vector2 delta = (Vector2)Input.mousePosition - lastPointer;
            gameCamera.transform.position -= new Vector3(delta.x, 0f, delta.y) * 0.025f;
            lastPointer = Input.mousePosition;
        }
    }
}
