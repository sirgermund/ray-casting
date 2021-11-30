#version 130

uniform vec2 u_resolution;
uniform vec2 u_mouse;

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra ) {
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

void main() {
    vec2 uv = gl_TexCoord[0].xy;
    vec2 mouse = (u_mouse / u_resolution);
    vec3 color = vec3(0);
    if (uv.x > mouse.x) {
        color.r = 1;
    }
    if (uv.y > mouse.y) {
        color.g = 1;
    }
    if (distance(uv, mouse) < 0.1) {
        color = vec3(1,1,1);
    }
    gl_FragColor = vec4(color, 1.0);
}
