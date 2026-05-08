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
    
    // FIX 1: Since we disabled instancing, we MUST use gl_VertexIndex to get the color,
    // otherwise every particle will be stuck on Flamingo!
    vBaseColor = baseColors[gl_VertexIndex % 3];

    // FIX 2: Project the exact center position directly. No corners, no offsets!
    vec4 clipPos = pc.viewProj * vec4(inPosition.xyz, 1.0);
    gl_Position = clipPos;

    // FIX 3: Perspective Point Sizing! (Requires the largePoints feature we enabled)
    // The constant (3000.0) is your "Bloom Scale". Tweak this if they are too big/small.
    float pointSize = 4000.0 / clipPos.w; 
    
    // Clamp the size so we don't draw 100-pixel squares if the camera gets too close,
    // and don't go below 1.0 pixel in the distance.
    gl_PointSize = clamp(pointSize, 1.0, 4.0); 
}
