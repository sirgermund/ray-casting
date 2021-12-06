#version 460

in vec4 gl_FragCoord;

out vec4 outColor;

uniform vec2 u_resolution;

#define FAR_DISTANCE 1000000.0
#define SPHERE_COUNT 2
#define BOX_COUNT 1

struct Material {
    vec3 emmitance;
    vec3 reflectance;
    float roughness;
    float opacity;
};

struct Box {
    Material material;
    vec3 halfSize;
    mat3 rot;
    vec3 pos;
};

struct Sphere {
    Material material;
    vec3 pos;
    float r;
};

struct Ray {
    vec3 origin;
    vec3 dir;
};

struct Intersection {
    vec3 pos;
    vec3 normal;
    Material material;
};

Sphere spheres[SPHERE_COUNT];
Box boxes[BOX_COUNT];

void init() {
    spheres = Sphere[SPHERE_COUNT](
        Sphere(Material(vec3(1.0), vec3(1.0), 1.0, 1.0), vec3(0), 1.0),
        Sphere(Material(vec3(0.5), vec3(1.0), 1.0, 1.0), vec3(3.0, 0.0, 0.0), 3.0)
    );
}

// sphere of size ra centered at point ce
bool sphIntersect(in Ray ray, in Sphere sphere, out float distance) {
    vec3 oc = ray.origin - sphere.pos;
    float b = dot(oc, ray.dir);
    float c = dot(oc, oc) - sphere.r * sphere.r;
    float h = b * b - c;
    if (h < 0.0) return false; // no intersection
    h = sqrt(h);
    distance = -b - h;
    return true;
}

// axis aligned box centered at the origin, with size boxSize
vec2 boxIntersection(in Ray ray, in Box box, out vec3 outNormal) {
    ray.origin = ray.origin - box.pos;
    vec3 m = 1.0/ray.dir; // can precompute if traversing a set of aligned boxes
    vec3 n = m*ray.origin;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*box.halfSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.0); // no intersection
    outNormal = -sign(ray.dir)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    return vec2( tN, tF );
}

bool castRay(in Ray ray, out Intersection intersection) {
    float minDistance = FAR_DISTANCE;

    for (int i = 0; i < SPHERE_COUNT; ++i) {
        Sphere sphere = spheres[i];
        float distance;

        if (sphIntersect(ray, sphere, distance) && distance < minDistance) {
            minDistance = distance;
            vec3 pos = ray.origin + ray.dir * distance;
            vec3 normal = normalize(pos - ray.origin);

            intersection = Intersection(pos, normal, sphere.material);
        }
    }

    return minDistance != FAR_DISTANCE;
}

vec3 traceRay(Ray ray) {
    Intersection intersection;
    if (castRay(ray, intersection)) {
        return intersection.material.emmitance;
    }
    return vec3(0.0);
}

vec2 tranformCoord() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv -= 0.5;
    uv.x *= u_resolution.x / u_resolution.y;
    return uv;
}

void main() {
    vec2 uv = tranformCoord();
    init();
    Ray ray = Ray(vec3(-5.0, 0.0, 0.0), normalize(vec3(1.0, uv)));
    vec3 col = traceRay(ray);
    outColor = vec4(col, 1.0);
}