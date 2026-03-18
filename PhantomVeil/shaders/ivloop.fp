void main()
{
    vec2 uv = TexCoord;
    vec2 center = vec2(0.5, 0.5);
    vec2 fromCenter = uv - center;
    float dist = length(fromCenter);

    vec2 dir = vec2(0.0, 0.0);
    if (dist > 0.0001)
    {
        dir = fromCenter / dist;
    }

    float ripple1 = sin(uv.y * 150.0) * 0.5 + 0.5;
    float ripple2 = sin(uv.x * 120.0) * 0.5 + 0.5;
    float ripple3 = sin((uv.x + uv.y) * 90.0) * 0.5 + 0.5;
    float ripple = (ripple1 + ripple2 + ripple3) / 3.0;

    float edge = smoothstep(0.06, 0.88, dist);
    float shell = smoothstep(0.18, 0.82, dist);

    vec2 distortion = dir * steps * (1.3 + ripple * 2.8) * edge;

    vec3 accum = vec3(0.0);
    vec2 startUV = uv - distortion * (float(samples) * 0.5);

    for (int i = 0; i < samples; i++)
    {
        vec2 sampleUV = startUV + distortion * float(i);
        accum += texture(InputTexture, sampleUV).rgb * increment;
    }

    vec3 original = texture(InputTexture, uv).rgb;

    vec2 chromaOffset = distortion * 0.75;
    float r = texture(InputTexture, uv + chromaOffset).r;
    float g = original.g;
    float b = texture(InputTexture, uv - chromaOffset).b;
    vec3 chroma = vec3(r, g, b);

    float blurMix = 0.24 + shell * 0.34;
    vec3 color = mix(original, accum, blurMix);

    float chromaMix = smoothstep(0.24, 0.90, dist) * 0.30;
    color = mix(color, chroma, chromaMix);

    float rim = pow(edge, 1.9) * 0.06;
    color += vec3(rim * 0.35, rim * 0.50, rim * 0.95);

    FragColor = vec4(color, 1.0);
}