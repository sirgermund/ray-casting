#version 130

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform vec3 u_pos;
uniform vec2 u_seed1;
uniform vec2 u_seed2;
uniform sampler2D u_sample;
uniform float u_sample_part;

const int MAX_REF = 8;
const float MAX_DIST = 99999.0;
const float PHI = 1.61803398874989484820459;  // Φ = Golden Ratio
const vec3 light = normalize(vec3(-0.5, 0.75, -1.0));
const vec3 skyblue = vec3(0.529, 0.808, 0.922);

uvec4 R_STATE;

bool isFirstRay;



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


uint TausStep(uint z, int S1, int S2, int S3, uint M)
{
    uint b = (((z << S1) ^ z) >> S2);
    return (((z & M) << S3) ^ b);
}
uint LCGStep(uint z, uint A, uint C)
{
    return (A * z + C);
}
vec2 hash22(vec2 p)
{
    p += u_seed1.x;
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
float random()
{
    R_STATE.x = TausStep(R_STATE.x, 13, 19, 12, uint(4294967294));
    R_STATE.y = TausStep(R_STATE.y, 2, 25, 4, uint(4294967288));
    R_STATE.z = TausStep(R_STATE.z, 3, 11, 17, uint(4294967280));
    R_STATE.w = LCGStep(R_STATE.w, uint(1664525), uint(1013904223));
    return 2.3283064365387e-10 * float((R_STATE.x ^ R_STATE.y ^ R_STATE.z ^ R_STATE.w));
}

vec3 randomOnSphere() {
    vec3 rand = vec3(random(), random(), random());
    float theta = rand.x * 2.0 * 3.14159265;
    float v = rand.y;
    float phi = acos(2.0 * v - 1.0);
    float r = pow(rand.z, 1.0 / 3.0);
    float x = r * sin(phi) * cos(theta);
    float y = r * sin(phi) * sin(theta);
    float z = r * cos(phi);
    return vec3(x, y, z);
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
    sun *= max(0.0, pow(dot(rd, light), 64.0));
    return clamp(sun + col, 0.0, 1.0);
}

vec4 castRay(inout vec3 ro, inout vec3 rd) {
    vec2 minIt = vec2(MAX_DIST);
    vec2 it;
    vec3 n;
    vec4 col;

    Sphere sphere = Sphere(vec3(1.0, 0.2, 0.1), vec3(0), 1.0);
    it = sphIntersect(ro, rd, sphere.origin, sphere.radius);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        vec3 itPos = ro + rd * it.x;
        n = normalize(itPos - sphere.origin);
        col = vec4(sphere.color, 1);
    }

    sphere = Sphere(vec3(1, 1, 1), vec3(-2, -2, 0), 1.0);
    it = sphIntersect(ro, rd, sphere.origin, sphere.radius);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        vec3 itPos = ro + rd * it.x;
        n = normalize(itPos - sphere.origin);
        col = vec4(sphere.color, -1);
    }

    sphere = Sphere(vec3(1, 1, 1), vec3(-4, -4, 0), 0.5);
    it = sphIntersect(ro, rd, sphere.origin, sphere.radius);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        vec3 itPos = ro + rd * it.x;
        n = normalize(itPos - sphere.origin);
        col = vec4(sphere.color, -2);
    }

    vec3 boxN;
    vec3 boxPos = vec3(0.0, 4.0, 0.0);
    it = boxIntersection(ro - boxPos, rd, vec3(1.0), boxN);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = boxN;
        col = vec4(0.1, 0.5, 0.2, 0.05);
    }

    boxPos = vec3(0.0, 8.0, 0.0);
    it = boxIntersection(ro - boxPos, rd, vec3(1.0), boxN);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = boxN;
        col = vec4(0.1, 0.5, 0.2, 1);
    }

    boxPos = vec3(0.0, 12.0, 0.0);
    it = boxIntersection(ro - boxPos, rd, vec3(1.0), boxN);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = boxN;
        col = vec4(0.1, 0.5, 0.2, 1);
    }

    vec3 planeNormal = vec3(0.0, 0.0, -1.0);
    it = vec2(plaIntersect(ro, rd, vec4(planeNormal, 1.0)), 0);
    if(it.x > 0.0 && it.x < minIt.x) {
        minIt = it;
        n = planeNormal;
        col = vec4(0.5, 0.5, 0.5, 0);
    }
    if(minIt.x == MAX_DIST) return vec4(getSky(rd), -2.0);
    if (col.a == -2.0) return col;
    vec3 reflected = reflect(rd, n);
    if(col.a < 0.0) {
        float fresnel = 1.0 - abs(dot(-rd, n));
        if(random() - 0.1 < fresnel * fresnel) {
            rd = reflected;
            return col;
        }
        ro += rd * (minIt.y + 0.001);
        rd = refract(rd, n, 1.0 / (1.0 - col.a));
        return col;
    }

    vec3 itPos = ro + rd * it.x;
    vec3 rand = randomOnSphere();
    vec3 spec = reflected;
    vec3 diff = normalize(rand * dot(rand, n));


    ro += rd * (minIt.x - 0.0001);
    rd = mix(diff, spec, col.a);

    return col;
}

vec3 traceRay(vec3 ro, vec3 rd) {
    isFirstRay = true;
    vec3 col = vec3(1.0);
    for(int i = 0; i < MAX_REF; i++)
    {
        vec4 refCol = castRay(ro, rd);
        col *= refCol.rgb;
        if(refCol.a == -2.0) return col;
        isFirstRay = false;
    }
    return vec3(0.0);
}

void main() {
    vec2 uv = (gl_TexCoord[0].xy - 0.5) * u_resolution / u_resolution.y;

    vec2 uvRes = hash22(uv + 1.0) * u_resolution + u_resolution;
    R_STATE.x = uint(u_seed1.x + uvRes.x);
    R_STATE.y = uint(u_seed1.y + uvRes.x);
    R_STATE.z = uint(u_seed2.x + uvRes.y);
    R_STATE.w = uint(u_seed2.y + uvRes.y);
//    vec3 color;

    vec3 rayOrigin = u_pos; // позиция камеры
    vec3 rayDirection = normalize(vec3(1, uv)); // вектор смотрящий вперед на пиксель

    // поворот в зависимости от мыши
    rayDirection *= rotY(u_mouse.y);
    rayDirection *= rotZ(u_mouse.x);

    //
//    color = traceRay(rayOrigin, rayDirection);


//    if (distance(uv, mouse) < 0.01) {
//        color = vec4(1);
//    }



    vec3 col = vec3(0.0);
    int samples = 16;
    for(int i = 0; i < samples; i++) {
        col += traceRay(rayOrigin, rayDirection);
    }
    col /= samples;

    col = pow(col, vec3(1.0 / 2.2));

    vec3 sampleCol = texture(u_sample, gl_TexCoord[0].xy).rgb;
    col = mix(sampleCol, col, u_sample_part);

    gl_FragColor = vec4(col, 1.0);
}
