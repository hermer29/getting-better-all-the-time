using UnityEngine;
using UnityEngine.Rendering;

public class SmokeController : MonoBehaviour
{
    public ComputeShader smokeShader;
    public ComputeShader smokeInitShader;
    public RenderTexture smokeTexture;  // 3D-текстура для визуализации
    public Texture2D perlin;
    public Material volumeMaterial;
    public Vector3 WindForce;
    private ComputeBuffer velocityBuffer;

    void Start()
    {
        if (smokeTexture == null)
        {
            // Инициализация 3D-текстуры (например, 32x32x32)
            smokeTexture = new RenderTexture(32, 32, 0, RenderTextureFormat.RFloat);
            smokeTexture.dimension = TextureDimension.Tex3D;
            smokeTexture.volumeDepth = 32;
            smokeTexture.enableRandomWrite = true;
            smokeTexture.Create();
        }

        InitializeSmoke();
        // Инициализация буферов
        velocityBuffer = new ComputeBuffer(smokeTexture.height * smokeTexture.width * smokeTexture.volumeDepth, sizeof(float) * 3);
    }
    
    void InitializeSmoke()
    {
        int kernel = smokeInitShader.FindKernel("SmokeInitCS");
        smokeInitShader.SetTexture(kernel, "Density", smokeTexture);
        smokeInitShader.SetTexture(kernel, "PerlinNoise", perlin);
        smokeInitShader.SetFloat("NoiseScale", 5.0f);
        smokeInitShader.Dispatch(kernel, 4, 4, 4);  // 32 / 8 = 4 (группы потоков)
        volumeMaterial.SetTexture("_DensityTex", smokeTexture);
    }

    void Update()
    {
        return;
        // Диспатч Compute Shader
        int kernel = smokeShader.FindKernel("SmokeCS");
        smokeShader.SetTexture(kernel, "Density", smokeTexture);
        smokeShader.SetBuffer(kernel, "Velocity", velocityBuffer);
        smokeShader.SetTexture(kernel, "Perlin", perlin);
        smokeShader.SetFloat("TimeStep", Time.deltaTime);
        smokeShader.SetVector("WindForce", WindForce); // Лёгкий ветер
        
        smokeShader.Dispatch(kernel, 4, 4, 4);  // 32 / 8 = 4 (по потокам)
        
        if (volumeMaterial != null)
            volumeMaterial.SetTexture("_DensityTex", smokeTexture);
    }

    void OnDestroy()
    {
        velocityBuffer.Release();
    }
}