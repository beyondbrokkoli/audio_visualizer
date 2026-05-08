#version 460
layout(location = 0) in flat int vThreadID;
layout(location = 1) in vec3 vBaseColor; // Matches location 1 from vert!

layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = vec4(vBaseColor * 1.5, 1.0); // Neon glow
}
