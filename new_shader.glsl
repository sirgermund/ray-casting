#version 460

in vec4 gl_FragCoord;

out vec4 outColor;

uniform vec2 u_resolution;
uniform vec3 u_pos;
uniform vec2 u_mouse;

#define FAR_DISTANCE 1000000.0
#define SPHERE_COUNT 2
#define BOX_COUNT 1
#define PLANE_COUNT 1
#define MAX_DEPTH 2

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

struct Plane {
    Material material;
    vec3 normal;
    float z;
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
Plane planes[PLANE_COUNT];

void init() {
    spheres = Sphere[SPHERE_COUNT](
        Sphere(Material(vec3(0.05, 0.0, 0.0), vec3(1.0, 0.0, 0.0), 0.0, 0.0), vec3(0), 1.0),
        Sphere(Material(vec3(1.0, 1.0, 1.0), vec3(0.0), 0.0, 0.0), vec3(-1.0, 1.0, 2.0), 0.5)
    );

    planes = Plane[PLANE_COUNT](
        Plane(Material(vec3(0.0, 0.5, 0.5), vec3(1.0, 1.0, 1.0), 0.0, 0.0), vec3(0.0, 0.0, 1.0), 2.0)
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

// plane degined by p (p.xyz must be normalized)
bool plaIntersect(in Ray ray, in Plane plane, out float distance) {
    vec4 p = vec4(plane.normal, plane.z);
    distance = -(dot(ray.origin,p.xyz)+p.w)/dot(ray.dir,p.xyz);
    return distance > 0.0;
}

bool castRay(in Ray ray, out Intersection intersection) {
    float minDistance = FAR_DISTANCE;

    for (int i = 0; i < SPHERE_COUNT; ++i) {
        Sphere sphere = spheres[i];
        float distance;

        if (sphIntersect(ray, sphere, distance) && distance < minDistance) {
            minDistance = distance;
            vec3 pos = ray.origin + ray.dir * distance;
            vec3 normal = normalize(pos - sphere.pos);

            intersection = Intersection(pos, normal, sphere.material);
        }
    }

    for (int i = 0; i < PLANE_COUNT; ++i) {
        Plane plane = planes[i];
        float distance;

        if (plaIntersect(ray, plane, distance) && distance < minDistance) {
            minDistance = distance;
            vec3 pos = ray.origin + ray.dir * distance;
            vec3 normal = plane.normal;

            intersection = Intersection(pos, normal, plane.material);
        }
    }

    return minDistance != FAR_DISTANCE;
}

vec3 traceRay(Ray ray) {
    vec3 L = vec3(0.0); // суммарное количество света
    vec3 F = vec3(1.0); // коэффициент отражения

    Intersection intersection;

    for (int i = 0; i < MAX_DEPTH; i++) {
        if (castRay(ray, intersection)) {
            ray.dir = reflect(ray.dir, intersection.normal);
            ray.origin = intersection.pos;

            L += F * intersection.material.emmitance;
            F *= intersection.material.reflectance;
        } else {
            F = vec3(0.0);
        }
    }
    return L;
}

vec2 tranformCoord() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv -= 0.5;
    uv.x *= u_resolution.x / u_resolution.y;
    uv.y = -uv.y;
    return uv;
}

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

void main() {
    vec2 uv = tranformCoord();
    init();

    Ray ray = Ray(u_pos, normalize(vec3(1.0, uv)));
    ray.dir *= rotY(u_mouse.y);
    ray.dir *= rotZ(u_mouse.x);

    vec3 col = traceRay(ray);
    outColor = vec4(col, 1.0);
}