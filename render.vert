#version 460

layout(location = 0) in vec4 inPosition;
layout(push_constant) uniform CameraInfo { mat4 viewProj; } pc;

// Passed to the Fragment Shader
layout(location = 0) out flat int vThreadID;
layout(location = 1) out vec3 vBaseColor;

// Soft Catppuccin underlying tints
const vec3 baseColors[3] = vec3[](
    vec3(0.95, 0.80, 0.80), // Flamingo
    vec3(0.80, 0.85, 0.95), // Lavender
    vec3(0.95, 0.95, 0.85)  // Rosewater
);

void main() {
    vThreadID = int(inPosition.w);
    vBaseColor = baseColors[gl_VertexIndex % 3]; // Linear color selection

    gl_Position = pc.viewProj * vec4(inPosition.xyz, 1.0);
    gl_PointSize = 2.0; // Will work safely because you patched vulkan_core!
}
