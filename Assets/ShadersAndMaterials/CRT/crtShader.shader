Shader "Custom/crtShader"
{
    Properties
    {
        [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
        _Resolution("Render Texture Resolution", Vector) = (512, 384, 0, 0)

        _LinesSize("LinesSize", Range(0.1,10)) = 3
        _LineMultiplier("Line Multiplier", Range(0.1, 5)) = 2.63
        _LineOffset ("Line Offset", Range(-3, 3)) = 1.21

        _VignetteStrength("Vignette Strength", Range(0,20)) = 9.02


        _WaveFrequency ("Wave Frequency", Range(0, 0.01)) = 0.0038
        _WaveAmplitude ("Wave Amplitude", Range(0, 0.1)) = 0.01
        _WaveCutoff ("Wave Cutoff", Range(1, 300)) = 109
        _WaveSpeed ("Wave Speed", Range(0, 2)) = 0.52

        _JitterAmount("Jitter Amount", Range(0,0.05)) = 0.00771

        _distance("Blur Distance", Range(0,0.01)) = 0.00288
        _blurStrength("Blur Strength", Range(0,1)) = 0.26

        _Brightness("Brightness", Range(0,10)) = 2

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 position : TEXCOORD1;
                float2 screenPosition : TEXCOORD2;
            };


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END

            float2 _Resolution;
            float _TimeElapsed;
            int _pause;

            float _LinesSize;
            float _LineMultiplier;
            float _LineOffset;

            float _VignetteStrength;

            float _WaveFrequency;
            float _WaveAmplitude;
            float _WaveCutoff;
            float _WaveSpeed;

            float _JitterAmount;


            float _distance;
            float _blurStrength;

            float _Brightness;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.position = mul(unity_ObjectToWorld, IN.vertex).xyz;
                OUT.screenPosition = ComputeScreenPos(OUT.positionHCS);
                OUT.uv = IN.uv;
                return OUT;
            }

            float rand(in float2 uv)
            {
                float2 noise = (frac(sin(dot(uv ,float2(12.9898,78.233)*2.0)) * 43758.5453));
                return abs(noise.x + noise.y) * 0.5;
            }

            float2 rand2D(float2 uv)
            {
                float r1 = rand(uv); 
                float r2 = rand(uv + float2(0.1, 0.2));
                return float2(r1, r2);
            }

            float vignette(float2 uv){
                float2 dist = uv - float2(0.5,0.5);
                return 1.0 - length(dist) * _VignetteStrength;
            }

            float scanLines(float2 uv)
            {
                float pixelY = floor(uv.y * _Resolution.y);
                float phase = fmod(pixelY, _LinesSize) / _LinesSize;

                float scan = 1.0 - abs(phase * 2.0 - 1.0);

                return scan * _LineMultiplier + _LineOffset;
            }

            float4 BoxBlur(float2 uv)
            {

                float2 directions[4] = {
                    float2(1,0),
                    float2(0,1),
                    float2(-1,0),
                    float2(0,-1)
                };

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv) * 0.2;
                
                for (int i = 0; i < 4; i++)
                {
                    float2 offset = directions[i] * _distance;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + offset) * 0.2;
                }

                return color;
            }

            float subPixelDistance(float2 uv)
            {
                float pixelX = uv.x * _Resolution.x;
                float pixelY = uv.y * _Resolution.y;

                float2 subpixelFrac = float2(frac(pixelX / 1.0), frac(pixelY / 3.0));
                float2 subpixelPos = float2(abs(subpixelFrac.x - 0.5), abs(subpixelFrac.y - 0.5));

                float distToCenter = sqrt(subpixelPos.x * subpixelPos.x + subpixelPos.y * subpixelPos.y);

                return 1.0 - saturate(distToCenter * 2.0);
            }




            float4 frag(Varyings IN) : SV_Target
            {
                
                float4 finalColor;
                float pixelX = floor(IN.uv.x * _Resolution.x);
                float pixelY = floor(IN.uv.y * _Resolution.y);
                float distance = subPixelDistance(IN.uv);

                float vignetteValue = vignette(IN.uv);
                float distAvg = scanLines(IN.uv);

                float wave = sin(pixelY * _WaveFrequency + _TimeElapsed * _WaveSpeed) * _WaveAmplitude;
                wave = floor(wave * _WaveCutoff) / _WaveCutoff;
                IN.uv.x += wave;

                if(_pause == 1){
                    float jitterPixels = round((rand(float2(pixelY, _Time.y)) - 0.5) * _JitterAmount * _Resolution.x);

                    IN.uv.x += jitterPixels / _Resolution.x;
                }

                
                IN.uv.x = floor(IN.uv.x * _Resolution.x) / _Resolution.x;
                IN.uv.y = floor(IN.uv.y * _Resolution.y) / _Resolution.y;

            
                float pixelPos = IN.uv.x * _Resolution.x;
                float subpixelPosR = frac(pixelPos / 3.0);
                float3 distances = float3(0.0, 0.0, 0.0);
                if(subpixelPosR < 1.0/3.0){
                    distances.r = 1.0; 
                }
                else if(subpixelPosR < 2.0/3.0){
                    distances.g = 1.0;
                }
                else{
                    distances.b = 1.0;
                }
                

                
                float4 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float4 RGBcolor = float4(baseCol.rgb * distances, 1.0) * distance;

                
                float4 blurColor = BoxBlur(IN.uv);

                finalColor = RGBcolor * (1.0 - _blurStrength) + blurColor * _blurStrength;
                finalColor *= clamp(vignetteValue + distAvg, 0.0, 1.0);

                finalColor.rgb *= _Brightness;

                return finalColor;
                

                

            }
            ENDHLSL
        }
    }
}