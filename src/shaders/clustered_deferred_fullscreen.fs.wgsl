// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

@group(${bindGroup_fullscreen}) @binding(0) var albedoTexture: texture_2d<f32>;
@group(${bindGroup_fullscreen}) @binding(1) var normalTexture: texture_2d<f32>;
@group(${bindGroup_fullscreen}) @binding(2) var depthTexture: texture_depth_2d;
@group(${bindGroup_fullscreen}) @binding(3) var textureSampler: sampler;


struct FragmentInput
{
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@fragment
fn main(input: FragmentInput) -> @location(0) vec4<f32> {
    let uv = vec2<f32>(input.uv.x, 1.0 - input.uv.y);
    let normal = textureSample(normalTexture, textureSampler, uv).xyz;
    let albedo = textureSample(albedoTexture, textureSampler, uv);
    
    let texSize: vec2<u32> = textureDimensions(depthTexture, 0);
    let pxCoord: vec2<i32> = vec2<i32>(
        i32(uv.x * f32(texSize.x - 1u)),
        i32(uv.y * f32(texSize.y - 1u))
    );
    let depth = textureLoad(depthTexture, pxCoord, 0);

    let far = camera.farPlane;
    let near = camera.nearPlane;

    let ndcPos = vec3<f32>(input.uv * 2.0 - 1.0, depth);
    let worldPosH = camera.invViewMat * camera.invProjMat * vec4<f32>(ndcPos, 1.0);
    let worldPos = worldPosH.xyz / worldPosH.w;

    let viewPos = camera.viewMat * vec4<f32>(worldPos, 1.0);
    let zDepth = viewPos.z;

    let clusterZ = u32(log(abs(zDepth) / near) / log(far / near) * f32(${clusterZ}));

    let screenPos = camera.viewProjMat * vec4<f32>(worldPos, 1.0);
    let ndcPos2 = screenPos.xyz / screenPos.w;
    let clusterX = u32((ndcPos2.x + 1.0) * 0.5 * f32(${clusterX}));
    let clusterY = u32((ndcPos2.y + 1.0) * 0.5 * f32(${clusterY}));

    let clusterIndex = clusterZ * u32(${clusterX}) * u32(${clusterY}) +
                       clusterY * u32(${clusterX}) +
                       clusterX;

    let cluster_ptr = &(clusterSet.clusters[clusterIndex]);
    var totalLightContrib = vec3<f32>(0.0, 0.0, 0.0);
    for (var i = 0u; i < (*cluster_ptr).cntLights; i++) {
        let light = lightSet.lights[(*cluster_ptr).lightIdx[i]];
        totalLightContrib += calculateLightContrib(light, worldPos, normal);
    }

    let finalColor = albedo.rgb * totalLightContrib;
    return vec4<f32>(finalColor, 1.0);
}