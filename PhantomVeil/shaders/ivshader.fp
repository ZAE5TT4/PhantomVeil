void main()
{
    vec2 uv = TexCoord;
    vec2 center = vec2(0.5, 0.5);
    vec2 fromCenter = uv - center;
    float dist = length(fromCenter);

    vec3 base = texture(InputTexture, uv).rgb;
    vec3 color = base;

    float edge = smoothstep(0.10, 0.92, dist);
    float inner = 1.0 - smoothstep(0.00, 0.38, dist);

    if (ivActive > 0)
    {
        float gray = dot(base, vec3(0.299, 0.587, 0.114));

        vec3 coolTint = vec3(0.72, 0.90, 1.12);
        vec3 desat = mix(vec3(gray), base, 0.34);
        color = mix(base, desat * coolTint, 0.52);

        float shell =
            sin(uv.y * 160.0) * 0.5 +
            sin(uv.x * 118.0) * 0.5 +
            sin((uv.x + uv.y) * 92.0) * 0.35;

        shell *= 0.012;
        color += vec3(shell * 0.45, shell * 0.70, shell * 1.10);

        float fresnel = pow(edge, 1.75);
        color += vec3(0.010, 0.028, 0.060) * fresnel * 2.1;

        float centerFade = 1.0 - inner * 0.06;
        color *= centerFade;

        float glass = smoothstep(0.22, 0.95, dist) * 0.05;
        color += vec3(glass * 0.35, glass * 0.55, glass * 0.90);
    }

    if (ivEffectCounter > 0)
    {
        float t = clamp(float(ivEffectCounter) / 12.0, 0.0, 1.0);
        vec3 enterGlow = vec3(0.14, 0.22, 0.34) * t;
        color += enterGlow;
        color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))) * vec3(0.78, 0.92, 1.08), t * 0.18);
    }
    else if (ivEffectCounter < 0)
    {
        float t = clamp(float(-ivEffectCounter) / 8.0, 0.0, 1.0);
        float gray = dot(color, vec3(0.299, 0.587, 0.114));
        color = mix(color, vec3(gray), t * 0.16);
        color += vec3(0.025, 0.032, 0.040) * t;
    }

    color = max(color, vec3(0.0));
    FragColor = vec4(color, 1.0);
}