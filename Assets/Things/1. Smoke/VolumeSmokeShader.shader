Shader "1.Smoke/VolumeSmoke"
{
    Properties
    {
        _DensityTex("Density Texture", 3D) = "white" {}
        _Color("Smoke Color", Color) = (1,1,1,1)
        _StepCount("Raymarch Steps", Int) = 64
        _Density("Density Scale", Float) = 1.0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
            };

            sampler3D _DensityTex;;
            float4 _DensityTex_ST;
            float4 _Color;
            int _StepCount;
            float _Density;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Начало и направление луча
                float3 rayStart = i.worldPos;
                float3 rayDir = i.viewDir;
                float rayLength = 10.0; // Дальность прохода луча

                // Параметры Raymarching
                float stepSize = rayLength / _StepCount;
                float3 rayStep = rayDir * stepSize;
                float3 currentPos = rayStart;

                // Накопление цвета и плотности
                float4 result = float4(0, 0, 0, 0);

                [unroll(200)]
                for (int i1 = 0; i1 < _StepCount; i1++)
                {
                    // Сэмплируем плотность из 3D-текстуры
                    float3 uv = (currentPos - _DensityTex_ST.xyz) / _DensityTex_ST.w;
                    float density = tex3D(_DensityTex, uv).r * _Density;

                    // Добавляем вклад в цвет
                    float4 col = _Color * density;
                    col.a = density;
                    result = (1.0 - result.a) * col + result;

                    // Выход, если полностью непрозрачный
                    if (result.a >= 0.99) break;

                    currentPos += rayStep;
                }

                return result;
            }
            ENDCG
        }
    }
}