/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

#include <metal_stdlib>
using namespace metal;
#import "Common.h"
#import "ShaderDefs.h"

fragment float4 fragment_main(
  VertexOut in [[stage_in]],
  constant Params &params [[buffer(12)]]
) {
  // return float4(0.2, 0.5, 1.0, 1);
  
  /*
  float color;
  in.position.x < params.width * 0.5 ? color = 0 : color = 1;
  return float4(color, color, color, 1);
  */
  
  // Checker board.
  /*
  uint checks = 16;
  float2 uv = in.position.xy / params.width;
  uv = fract(uv * checks * 0.5) - 0.5;
  float3 color = step(uv.x * uv.y, 0.0);
  return float4(color, 1);
  */
  
  // Circle
  /*
  float center = 0.5;
  float radius = 0.2;
  float2 uv = in.position.xy / params.width - center;
  float3 color = step(length(uv), radius);
  return float4(color, 1.0);
  */
  
  // smoothstep
  /*
  float color = smoothstep(0, params.width, in.position.x);
  return float4(color, color, color, 1);
  */
  
  // return float4(in.normal, 1);
  
  float4 sky = float4(0.34, 0.9, 1.0, 1.0);
  float4 earth = float4(0.29, 0.58, 0.2, 1.0);
  float intensity = in.normal.y * 0.5 + 0.5;
  return mix(earth, sky, intensity);
}
