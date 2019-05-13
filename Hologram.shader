Shader "Unlit/Hologram"
{
	//public variables that will appear in inspector for user input
    Properties
    {
		//VariableName(display name, type)="value" 
        _MainTex ("Texture", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1,1,1,1) 
		_Transparency("Transparency", Range(0.0, 0.5)) =0.25

		//Threshold to cutout any value other than a specified color
		_CutoutThresh("Cutout Threshold",Range(0.0,1.0))= 0.2

		//Properties that will be used for the vertex processing (for wiggling the vertices around)
		_Distance("Distance", Float) = 1
		_Amplitude("Amplitude", Float) = 1
		_Speed("Speed", Float) = 1
		_Amount("Amount", Range(0.0,1.0))=1
    }
	//Contains the code (instructions for unity) on how to setup the renderer
	//You could have several subshaders (e.g. ps4 sub shader, mobile sub shader)
    SubShader
    {
		//Tags talk to unity renderer
        Tags {"Queue"="Transparent" "RenderType"="Transparent" }

		//Level of details
        LOD 100
		
		//Set rendering to depth buffer off for transparency
		//More info: https://docs.unity3d.com/Manual/SL-CullAndDepth.html
		ZWrite Off

		//Blend SrcAlpha blend factor to OneMinusSrcAlpha
		//More info: https://docs.unity3d.com/Manual/SL-Blend.html
		Blend SrcAlpha OneMinusSrcAlpha

		//Actual CG code
        Pass
        {
            CGPROGRAM

			//vertex function called vert
            #pragma vertex vert

			//fragment function called frag
            #pragma fragment frag

			//Shaders don't have have innhertiance, this file is added during compile time
            #include "UnityCG.cginc"

			//this struct passes information aout vertics
            struct appdata
            {
				//pass the vertices into their local position 
                float4 vertex : POSITION; //float4 is a packed array

				//pass the uv to texture coordinates
                float2 uv : TEXCOORD0;
            };
			
			//Vert to frag struct
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;//Screen space position
            };

			//We need to declare the public variables here as well in order to use them
            sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _TintColor;
			float _Transparency;
			float _CutoutThresh;
			float _Distance;
			float _Amplitude;
			float _Speed;
			float _Amount;

			//Vertex modifications and calculations
            v2f vert (appdata v)
            {
                v2f o;
				//Time is a stream of values incoming from unity as float4 (x,y,z,w), y is time in seconds
				//Time.time equivalent in c#
				//Apply sinusoidal movement to our vertices in object space along x-axis before they get translated in UnityObjectToClipPos function  
				v.vertex.x += sin(_Time.y * _Speed * v.vertex.y * _Amplitude) * _Distance * _Amount;
				//Where the model is relative to the data and camera
                o.vertex = UnityObjectToClipPos(v.vertex);//pass the vertex of the model in local space
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);//The tiling transformation 
                return o;
            }

			//Colors and pixels 
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) + _TintColor;//Get the color from the texture and add the tint color
				col.a = _Transparency; //Set the alpha to _Transparency variable
				clip(col.r - _CutoutThresh); //Discard certain pixel data, clip any pixels that have less than a certain amount of red (don't draw them)
				// if (col.r < _CutoutThresh) discard; //Alternatie method of discard anything but red
					return col;
            }
            ENDCG
        }
    }
}
