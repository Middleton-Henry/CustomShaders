using UnityEngine;

public class CRTManager : MonoBehaviour
{
    private static CRTManager _instance;
    public static CRTManager Instance { get { return _instance; } }

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(this.gameObject);
        }
        else
        {
            _instance = this;
        }
    }

    [SerializeField] private Material crtMaterial;

    private float timeElapsed;
    void Start()
    {
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 30;
        unpause();
    }

    void Update()
    {
        if(!Singleton.Instance.getPause())
        {
            timeElapsed += Time.deltaTime;
            crtMaterial.SetFloat("_TimeElapsed", timeElapsed);
        }
    }

    public void pause()
    {
        crtMaterial.SetInt("_pause", 1);
    }

    public void unpause()
    {
        crtMaterial.SetInt("_pause", 0);
    }
}
