using System.Collections.Generic;
using UnityEngine;

public class TycoonGame : MonoBehaviour
{
    public static TycoonGame Instance;
    public int money = 500;
    public int incomePerSecond = 0;
    public int selected = -1;
    public enum BuildingType { Shop, Factory }
    class Plot { public GameObject root; public BuildingType type; public int level = 1; public bool built; }
    readonly List<Plot> plots = new List<Plot>();
    readonly Color grass = new Color(.30f,.52f,.27f);
    Camera cam;
    Vector2 lastTouch;
    bool dragging;
    float yaw = 42f, pitch = 48f, distance = 17f;
    Vector3 target = new Vector3(0,0,0);
    GUIStyle titleStyle, bodyStyle, buttonStyle, smallStyle;

    void Awake() { Instance = this; }
    void Start()
    {
        Application.targetFrameRate = 60;
        BuildWorld();
        SetupCamera();
        RecalculateIncome();
    }

    void BuildWorld()
    {
        MakeCube("زمین", new Vector3(0,-.22f,0), new Vector3(13,.4f,13), grass, null);
        // Cross roads through the center
        MakeCube("خیابان", new Vector3(0,.005f,0), new Vector3(1.35f,.025f,13), new Color(.22f,.23f,.24f), null);
        MakeCube("خیابان", new Vector3(0,.008f,0), new Vector3(13,.03f,1.35f), new Color(.22f,.23f,.24f), null);
        for (int z=-2; z<=2; z++)
        for (int x=-2; x<=2; x++)
        {
            if (x==0 || z==0) continue;
            int id = plots.Count;
            Vector3 p = new Vector3(x*2.35f,.03f,z*2.35f);
            GameObject tile = MakeCube("زمین قابل ساخت",p,new Vector3(1.9f,.12f,1.9f),new Color(.42f,.63f,.34f),null);
            BoxCollider col = tile.AddComponent<BoxCollider>();
            Plot plot = new Plot(); plot.root = tile; plots.Add(plot);
            PlotClick click = tile.AddComponent<PlotClick>(); click.index = id;
        }
        // Decorative trees around the perimeter
        for (int i=0;i<12;i++)
        {
            float a = i*Mathf.PI*2f/12f;
            Vector3 p = new Vector3(Mathf.Cos(a)*6f,.1f,Mathf.Sin(a)*6f);
            GameObject trunk = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            trunk.name="درخت"; trunk.transform.position=p+Vector3.up*.45f; trunk.transform.localScale=new Vector3(.18f,.5f,.18f);
            Paint(trunk,new Color(.34f,.20f,.10f));
            GameObject crown=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown.transform.position=p+Vector3.up*1.2f; crown.transform.localScale=Vector3.one*.85f;
            Paint(crown,new Color(.16f,.39f,.17f));
        }
        // Simple decorative central fountain
        GameObject baseF=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        baseF.transform.position=new Vector3(0,.12f,0); baseF.transform.localScale=new Vector3(1.25f,.22f,1.25f); Paint(baseF,new Color(.55f,.58f,.59f));
        GameObject water=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        water.transform.position=new Vector3(0,.26f,0); water.transform.localScale=new Vector3(.85f,.08f,.85f); Paint(water,new Color(.18f,.58f,.78f));
        InvokeRepeating(nameof(CollectIncome),1f,1f);
    }

    void SetupCamera()
    {
        cam = Camera.main;
        if (!cam) { GameObject c=new GameObject("Main Camera"); cam=c.AddComponent<Camera>(); c.tag="MainCamera"; }
        cam.backgroundColor=new Color(.55f,.72f,.82f);
        cam.clearFlags=CameraClearFlags.SolidColor;
        cam.fieldOfView=42;
        UpdateCamera();
    }

    void Update()
    {
        if (Input.touchCount>0)
        {
            Touch t=Input.GetTouch(0);
            if (t.phase==TouchPhase.Began) { lastTouch=t.position; dragging=true; }
            else if (t.phase==TouchPhase.Moved && dragging)
            {
                Vector2 d=t.position-lastTouch; yaw-=d.x*.22f; pitch=Mathf.Clamp(pitch-d.y*.12f,28,68); lastTouch=t.position; UpdateCamera();
            }
            else if (t.phase==TouchPhase.Ended || t.phase==TouchPhase.Canceled) dragging=false;
            if (Input.touchCount==2)
            {
                Touch a=Input.GetTouch(0), b=Input.GetTouch(1);
                float delta=(a.deltaPosition-b.deltaPosition).magnitude;
                distance=Mathf.Clamp(distance-delta*.008f,11,24); UpdateCamera();
            }
        }
        else if (Input.GetMouseButton(0))
        {
            if (Input.GetMouseButtonDown(0)) lastTouch=Input.mousePosition;
            else { Vector2 d=(Vector2)Input.mousePosition-lastTouch; yaw-=d.x*.18f; pitch=Mathf.Clamp(pitch-d.y*.1f,28,68); lastTouch=Input.mousePosition; UpdateCamera(); }
        }
        if (Input.mouseScrollDelta.y!=0) { distance=Mathf.Clamp(distance-Input.mouseScrollDelta.y,11,24); UpdateCamera(); }
    }

    void UpdateCamera()
    {
        if (!cam) return;
        Quaternion rot=Quaternion.Euler(pitch,yaw,0);
        cam.transform.position=target+rot*new Vector3(0,0,-distance);
        cam.transform.rotation=rot;
    }

    GameObject MakeCube(string n, Vector3 p, Vector3 s, Color c, Transform parent)
    {
        GameObject g=GameObject.CreatePrimitive(PrimitiveType.Cube); g.name=n; g.transform.position=p; g.transform.localScale=s;
        if(parent) g.transform.SetParent(parent,true); Paint(g,c); return g;
    }
    void Paint(GameObject g,Color c)
    {
        Renderer r=g.GetComponent<Renderer>(); if(r) { r.material=new Material(Shader.Find("Standard")); r.material.color=c; }
    }

    public void SelectPlot(int id) { selected=id; }
    public bool BuildSelected(BuildingType type)
    {
        if(selected<0 || selected>=plots.Count || plots[selected].built) return false;
        int cost=type==BuildingType.Shop?120:220;
        if(money<cost) return false;
        money-=cost; Plot p=plots[selected]; p.type=type; p.built=true;
        CreateBuilding(p); RecalculateIncome(); return true;
    }
    void CreateBuilding(Plot p)
    {
        Vector3 pos=p.root.transform.position+Vector3.up*.12f;
        p.root.GetComponent<Renderer>().material.color=new Color(.48f,.48f,.45f);
        GameObject b=new GameObject(p.type==BuildingType.Shop?"فروشگاه":"کارخانه");
        b.transform.position=pos;
        Color wall=p.type==BuildingType.Shop?new Color(.86f,.66f,.38f):new Color(.48f,.57f,.66f);
        MakeCube("بدنه",pos+Vector3.up*.48f,new Vector3(1.22f,.95f,1.18f),wall,b.transform);
        MakeCube("سقف",pos+Vector3.up*1.05f,new Vector3(1.38f,.18f,1.34f),p.type==BuildingType.Shop?new Color(.65f,.17f,.12f):new Color(.25f,.29f,.34f),b.transform);
        MakeCube("در",pos+new Vector3(0,.25f,-.601f),new Vector3(.28f,.5f,.035f),new Color(.22f,.15f,.1f),b.transform);
        if(p.type==BuildingType.Factory)
        {
            GameObject chimney=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            chimney.transform.SetParent(b.transform); chimney.transform.localPosition=new Vector3(.35f,1.2f,.25f); chimney.transform.localScale=new Vector3(.2f,.65f,.2f); Paint(chimney,new Color(.32f,.34f,.36f));
        }
        p.root.GetComponent<PlotClick>().building=b;
    }
    public bool UpgradeSelected()
    {
        if(selected<0 || selected>=plots.Count || !plots[selected].built) return false;
        Plot p=plots[selected]; int cost=100*p.level;
        if(money<cost) return false;
        money-=cost; p.level++;
        if(p.root.GetComponent<PlotClick>().building) p.root.GetComponent<PlotClick>().building.transform.localScale*=1.08f;
        RecalculateIncome(); return true;
    }
    void RecalculateIncome()
    {
        incomePerSecond=0;
        foreach(Plot p in plots) if(p.built) incomePerSecond+=(p.type==BuildingType.Shop?8:16)*p.level;
    }
    void CollectIncome() { money+=incomePerSecond; }

    void InitStyles()
    {
        if(titleStyle!=null) return;
        titleStyle=new GUIStyle(GUI.skin.label){fontSize=Mathf.Max(18,Screen.width/25),fontStyle=FontStyle.Bold,alignment=TextAnchor.MiddleCenter};
        bodyStyle=new GUIStyle(GUI.skin.label){fontSize=Mathf.Max(14,Screen.width/34),alignment=TextAnchor.MiddleCenter};
        smallStyle=new GUIStyle(GUI.skin.label){fontSize=Mathf.Max(12,Screen.width/42),alignment=TextAnchor.MiddleCenter};
        buttonStyle=new GUIStyle(GUI.skin.button){fontSize=Mathf.Max(14,Screen.width/34),fontStyle=FontStyle.Bold};
    }
    void OnGUI()
    {
        InitStyles();
        float w=Screen.width,h=Screen.height, pad=w*.035f;
        GUI.color=new Color(.08f,.12f,.14f,.88f);
        GUI.Box(new Rect(pad,pad,w-pad*2,h*.105f),"");
        GUI.color=Color.white;
        GUI.Label(new Rect(pad,h*.015f,w*.48f,h*.045f),"شهرک‌ساز سه‌بعدی",titleStyle);
        GUI.Label(new Rect(w*.48f,h*.02f,w*.48f,h*.04f),"سکه: "+money.ToString("N0")+"   |   درآمد: "+incomePerSecond+"/ثانیه",bodyStyle);
        float bh=h*.075f, gap=pad, y=h-bh-pad;
        GUI.color=new Color(.08f,.12f,.14f,.92f); GUI.Box(new Rect(pad,y-gap,w-pad*2,bh+gap*2),""); GUI.color=Color.white;
        float bw=(w-pad*2-gap*3)/3f;
        if(GUI.Button(new Rect(pad,y,bw,bh),"فروشگاه ۱۲۰",buttonStyle)) BuildSelected(BuildingType.Shop);
        if(GUI.Button(new Rect(pad+bw+gap,y,bw,bh),"کارخانه ۲۲۰",buttonStyle)) BuildSelected(BuildingType.Factory);
        if(GUI.Button(new Rect(pad+(bw+gap)*2,y,bw,bh),"ارتقا",buttonStyle)) UpgradeSelected();
        string info="یک زمین خالی را لمس کن";
        if(selected>=0 && selected<plots.Count)
        {
            Plot p=plots[selected];
            info=p.built?(p.type==BuildingType.Shop?"فروشگاه":"کارخانه")+" | سطح "+p.level+" | درآمد "+(p.type==BuildingType.Shop?8:16)*p.level+"/ثانیه":"زمین انتخاب شد؛ یک ساختمان بساز";
        }
        GUI.Label(new Rect(pad,h*.125f,w-pad*2,h*.05f),info,bodyStyle);
    }
}

public class PlotClick : MonoBehaviour
{
    public int index;
    public GameObject building;
    void OnMouseDown() { if(TycoonGame.Instance) TycoonGame.Instance.SelectPlot(index); }
}
