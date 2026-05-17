shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
    vec4 color = vec4(0.0);
    float total_weight = 0.0;
    
    float angle = 0.0;
    float golden_angle = 2.39996323;
    
    for (float i = 1.0; i <= 32.0; i++) {
        float r = sqrt(i) * blur_amount;
        vec2 offset = vec2(cos(angle), sin(angle)) * r * SCREEN_PIXEL_SIZE;
        
        color += texture(screen_texture, SCREEN_UV + offset);
        total_weight += 1.0;
        
        angle += golden_angle;
    }
    
    COLOR = color / total_weight;
}
