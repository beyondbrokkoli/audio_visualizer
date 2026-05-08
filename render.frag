#version 460
layout(location = 0) in flat int vThreadID;
layout(location = 1) in vec3 vBaseColor; // Matches location 1 from vert!

layout(location = 0) out vec4 fragColor;

void main() {
    // Optional: Round the squares into perfect dots using gl_PointCoord
    vec2 uv = gl_PointCoord - vec2(0.5);
    if (length(uv) > 0.5) {
        discard;
    }

    // Multiply the Catppuccin base color by 1.5 to make it glow like neon!
    fragColor = vec4(vBaseColor * 1.5, 1.0); 
}
