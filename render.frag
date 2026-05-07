#version 460
layout(location = 0) flat in int vThreadID;
layout(location = 1) in float vDiffuse;
layout(location = 2) in vec3 vBaseColor;

layout(location = 0) out vec4 outColor;

void main() {
    // We ignore the pastel base colors and inject pure Neon!
    vec3 finalColor = vec3(1.0);

    // SYNTHWAVE / OUTRUN PALETTE
    if (vThreadID == 0) finalColor = vec3(1.0, 0.0, 0.4);   // Laser Pink
    if (vThreadID == 1) finalColor = vec3(0.0, 1.0, 0.8);   // Neon Cyan
    if (vThreadID == 2) finalColor = vec3(0.8, 0.0, 1.0);   // Deep Violet
    if (vThreadID == 3) finalColor = vec3(1.0, 0.8, 0.0);   // Electric Yellow

    // Increase the contrast of the diffuse lighting for a harsher, punchier look
    float punchyDiffuse = pow(vDiffuse, 1.5) * 1.2;

    outColor = vec4(finalColor * punchyDiffuse, 1.0);
}
