// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights

// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput {
    @location(0) pos: vec3<f32>,
    @location(1) nor: vec3<f32>,
    @location(2) uv: vec2<f32>,
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4<f32> {
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5) {
        discard;
    }

    let far = camera.farPlane;
    let near = camera.nearPlane;

    let screenPos = camera.viewProjMat * vec4<f32>(in.pos, 1.0);
    let ndcPos = screenPos.xyz / screenPos.w;

    let posView = camera.viewMat * vec4<f32>(in.pos, 1.0);
    let Z_pos = u32(log(abs(posView.z) / near) / log(far / near) * f32(${clusterZ}));
    let X_pos = u32((ndcPos.x + 1.0) * 0.5 * f32(${clusterX}));
    let Y_pos = u32((ndcPos.y + 1.0) * 0.5 * f32(${clusterY}));
   
    let clusterIndex = Z_pos * u32(${clusterX}) * u32(${clusterY}) +
                       Y_pos * u32(${clusterX}) +
                       X_pos;

    let cluster_ptr = &(clusterSet.clusters[clusterIndex]);
    var totalLightContrib = vec3<f32>(0.0,0.0,0.0);
    for (var i = 0u; i < (*cluster_ptr).cntLights; i++) {
        let light = lightSet.lights[(*cluster_ptr).lightIdx[i]];
        totalLightContrib += calculateLightContrib(light, in.pos, in.nor);
    }

    let finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4<f32>(finalColor, 1.0);
}
