using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine.Video;
using UnityEngine.UI;

public class Singleton : MonoBehaviour
{
    private static Singleton _instance;

    public static Singleton Instance { get { return _instance; } }

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(this.gameObject);
        }
        else
        {
            _instance = this;
            DontDestroyOnLoad(gameObject);
        }
    }

    void Update()
    {
        if(Input.GetKeyDown(KeyCode.P))
        {
            if(!isPaused)
            {
                onPause();
            }
            else
            {
                onResume();
            }
        }
    }

    private bool isPaused = false;
    [SerializeField] private TMP_Text statusText;
    [SerializeField] private VideoPlayer videoPlayer;
    
    public void onPause()
    {
        isPaused = true;
        CRTManager.Instance.pause();

        if (videoPlayer != null)
        {
            videoPlayer.Pause();
        }
        else
        {
            Debug.Log("Video Player is not assigned");
        }
        
        if(statusText != null)
        {
            statusText.text = "PAUSED";
        }
        else
        {
            Debug.Log("Status Text is not assigned");
        }
    }
    
    public void onResume()
    {
        isPaused = false;
        CRTManager.Instance.unpause();

        if(videoPlayer != null)
        {
            videoPlayer.Play();
        }
        else
        {
            Debug.Log("Video Player is not assigned");
        }

        if(statusText != null)
        {
            statusText.text = "PLAYING";
        }
        else
        {
            Debug.Log("Status Text is not assigned");
        }
    }

    public bool getPause()
    {
        return isPaused;
    }
}
