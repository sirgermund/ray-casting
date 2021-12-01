
uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform vec3 u_pos;

const float MAX_DIST = 99999.0;
const vec3 light = normalize(vec3(-0.5, 0.75, -1.0));
const vec3 skyblue = vec3(0.529, 0.808, 0.922);

struct Sphere {
    vec3 color;
    vec3 origin;
    float radius;
};

mat3 rotY(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotZ(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

vec2 sphIntersect(in vec3 ro, in vec3 rd, in vec3 ce, float ra) {
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

// plane degined by p (p.xyz must be normalized)
float plaIntersect(in vec3 ro, in vec3 rd, in vec4 p ) {
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// axis aligned box centered at the origin, with size boxSize
vec2 boxIntersection(in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal ) {
    vec3 m = 1.0/rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m*ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.0); // no intersection
    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    return vec2( tN, tF );
}

vec3 getSky(vec3 rd) {
    vec3 col = skyblue;
    vec3 sun = vec3(0.95, 0.9, 1.0);
    sun *= max(0.0, pow(dot(rd, light), 32.0));
    return clamp(sun + col, 0.0, 1.0);
}

vec3 castRay(inout vec3 ro, inout vec3 rd) {
    vec2 minIt = vec2(MAX_DIST);
    vec2 it;
    vec3 n;
    vec3 col;

    Sphere sphere = Sphere(vec3(1.0, 0.2, 0.1), vec3(0), 1.0);
    it = sphIntersect(ro, rd, sphere.origin, sphere.radius);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        vec3 itPos = ro + rd * it.x;
        n = itPos - sphere.origin;
        col = sphere.color;
    }

    vec3 boxN;
    vec3 boxPos = vec3(0.0, 4.0, 0.0);
    it = boxIntersection(ro - boxPos, rd, vec3(1.0), boxN);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = boxN;
        col = vec3(0.1, 0.5, 0.2);
    }

    vec3 planeNormal = vec3(0.0, 0.0, -1.0);
    it = vec2(plaIntersect(ro, rd, vec4(planeNormal, 1.0)), 0);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = planeNormal;
        col = vec3(0.5);
    }
    if(minIt.x == MAX_DIST) return vec3(-1.0);
    float diffuse = dot(light, n) * 0.5 + 0.5;
    float specular = pow(max(0.0, dot(reflect(rd, n), light)), 32.0);
    col *= mix(diffuse, specular, 0.5);

    ro += rd * (minIt.x - 0.001);
    rd = n;

    return col;
}

vec3 traceRay(vec3 ro, vec3 rd) {
    vec3 col = castRay(ro, rd);
    if (col.x == -1.0) return getSky(rd);
    vec3 lightDir = light;
    if (dot(rd, light) > 0 && castRay(ro, lightDir).x != -1.0) col *= 0.5;
    return col;
}

void main() {
    vec2 uv = (gl_TexCoord[0].xy - 0.5) * u_resolution / u_resolution.y;
    vec3 color;

    vec3 rayOrigin = u_pos; // позиция камеры
    vec3 rayDirection = normalize(vec3(1, uv)); // вектор смотрящий вперед на пиксель

    // поворот в зависимости от мыши
    rayDirection *= rotY(u_mouse.y);
    rayDirection *= rotZ(u_mouse.x);

    //
    color = traceRay(rayOrigin, rayDirection);


//    if (distance(uv, mouse) < 0.01) {
//        color = vec4(1);
//    }

    // гамма-коррекция
    color.x = pow(color.x, 0.45);
    color.y = pow(color.y, 0.45);
    color.z = pow(color.z, 0.45);

    gl_FragColor = vec4(color, 1);
}
