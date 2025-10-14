// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.

@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

@group(${bindGroup_fullscreen}) @binding(0) var albedoTex: texture_2d<f32>;
@group(${bindGroup_fullscreen}) @binding(1) var albedoTexSampler: sampler;
@group(${bindGroup_fullscreen}) @binding(2) var normalTex: texture_2d<f32>;
@group(${bindGroup_fullscreen}) @binding(3) var normalTexSampler: sampler;
@group(${bindGroup_fullscreen}) @binding(4) var depthTex: texture_depth_2d;
@group(${bindGroup_fullscreen}) @binding(5) var depthTexSampler: sampler;


struct FragmentInput
{
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@fragment
fn main(input: FragmentInput) -> @location(0) vec4<f32> {
    return vec4(0.8, 0.2, 0.2, 1.0);
}