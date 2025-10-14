// TODO-2: implement the light clustering compute shader

// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.

//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.

//     - Store the number of lights assigned to this cluster.

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

@compute @workgroup_size(${BlockSizeX}, ${BlockSizeY}, ${BlockSizeZ})
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    
    if (global_id.x >= ${clusterX} || global_id.y >= ${clusterY} || global_id.z >= ${clusterZ}) {
        return;
    }

    let idx = global_id.z * ${clusterX} * ${clusterY} + global_id.y * ${clusterX} + global_id.x;
    let cur_cluster_ptr = &(clusterSet.clusters[idx]);
    let lightSet_ptr = &(lightSet);

    let left_bottom = vec2<f32>(global_id.xy) * camera.canvasResolution / vec2<f32>(${clusterX}, ${clusterY});
    let right_top = (vec2<f32>(global_id.xy) + vec2<f32>(1.0, 1.0)) * camera.canvasResolution / vec2<f32>(${clusterX}, ${clusterY});
    let ndc_lb = 2.0 * (left_bottom / camera.canvasResolution) - vec2<f32>(1.0, 1.0);
    let ndc_rt = 2.0 * (right_top / camera.canvasResolution) - vec2<f32>(1.0, 1.0);

    let tileNear = camera.nearPlane * pow(camera.farPlane / camera.nearPlane, f32(global_id.z) / f32(${clusterZ}));
    let tileFar = camera.nearPlane * pow(camera.farPlane / camera.nearPlane, f32(global_id.z + 1u) / f32(${clusterZ}));

    var viewMin = camera.invProjMat * vec4<f32>(ndc_lb, -1.0, 1.0);
    var viewMax = camera.invProjMat * vec4<f32>(ndc_rt, -1.0, 1.0);
    viewMin /= viewMin.w;
    viewMax /= viewMax.w;

    let minBoundsPos1 = viewMin.xyz * (tileNear / -viewMin.z);
    let maxBoundsPos1 = viewMax.xyz * (tileNear / -viewMax.z);
    let minBoundsPos2 = viewMin.xyz * (tileFar / -viewMin.z);
    let maxBoundsPos2 = viewMax.xyz * (tileFar / -viewMax.z);

    (*cur_cluster_ptr).minDep = min(min(minBoundsPos1, maxBoundsPos1), min(minBoundsPos2, maxBoundsPos2));
    (*cur_cluster_ptr).maxDep = max(max(minBoundsPos1, maxBoundsPos1), max(maxBoundsPos2, minBoundsPos2));

    var lightCount = 0u;

    for (var i = 0u; i < (*lightSet_ptr).numLights; i++) {
        let light = (*lightSet_ptr).lights[i];
        let lightPosView = (camera.viewMat * vec4<f32>(light.pos, 1.0)).xyz;

        let closest = clamp(lightPosView, (*cur_cluster_ptr).minDep, (*cur_cluster_ptr).maxDep);
        let dis = distance(lightPosView, closest);
        if(dis <= f32(${lightRadius})){
            if (lightCount < 1024u) {
                (*cur_cluster_ptr).lightIdx[lightCount] = i;
                lightCount++;
            }
        }
    }

    (*cur_cluster_ptr).cntLights = lightCount;
}
