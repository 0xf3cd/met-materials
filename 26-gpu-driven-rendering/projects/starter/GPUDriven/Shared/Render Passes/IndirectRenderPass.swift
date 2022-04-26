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

import MetalKit

struct IndirectRenderPass: RenderPass {
  var label = "Indirect Command Encoding"
  var descriptor: MTLRenderPassDescriptor?
  let depthStencilState: MTLDepthStencilState?
  let pipelineState: MTLRenderPipelineState
  
  var uniformsBuffer: MTLBuffer!
  var modelParamsBuffer: MTLBuffer!
  
  var icb: MTLIndirectCommandBuffer!

  init() {
    pipelineState = PipelineStates.createIndirectPSO()
    depthStencilState = Self.buildDepthStencilState()
  }
    
  mutating func initializeUniforms(_ models: [Model]) -> Void {
    let bufferLength = MemoryLayout<Uniforms>.stride
    uniformsBuffer = Renderer.device.makeBuffer(length: bufferLength, options: [])
    uniformsBuffer.label = "Uniforms"
    
    var modelParams: [ModelParams] = models.map { model in
      var modelParams = ModelParams()
      modelParams.modelMatrix = model.transform.modelMatrix
      modelParams.normalMatrix = modelParams.modelMatrix.upperLeft
      modelParams.tiling = model.tiling
      return modelParams
    }
    
    modelParamsBuffer = Renderer.device.makeBuffer(
      bytes: &modelParams,
      length: MemoryLayout<ModelParams>.stride * models.count,
      options: [])
    modelParamsBuffer.label = "Model Transforms Array"
  }
  
  mutating func initializeICBCommands(_ models: [Model]) -> Void {
    let icbDescriptor = MTLIndirectCommandBufferDescriptor()
    icbDescriptor.commandTypes = [.drawIndexed]
    icbDescriptor.inheritBuffers = false
    icbDescriptor.maxVertexBufferBindCount = 25
    icbDescriptor.maxFragmentBufferBindCount = 25
    icbDescriptor.inheritPipelineState = true
    
    guard let icb = Renderer.device?.makeIndirectCommandBuffer(
        descriptor: icbDescriptor,
        maxCommandCount: models.count, // One draw call for each model.
        options: [])
    else { fatalError("Failed to create ICB") }
    self.icb = icb
    
    for (modelIndex, model) in models.enumerated() {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      let icbCommand = icb.indirectRenderCommandAt(modelIndex)
      icbCommand.setVertexBuffer(
          uniformsBuffer,
          offset: 0,
          at: UniformsBuffer.index)
      icbCommand.setVertexBuffer(
        modelParamsBuffer,
        offset: 0,
        at: ModelParamsBuffer.index)
      icbCommand.setFragmentBuffer(
        modelParamsBuffer,
        offset: 0,
        at: ModelParamsBuffer.index)
      icbCommand.setVertexBuffer(
        mesh.vertexBuffers[VertexBuffer.index],
        offset: 0,
        at: VertexBuffer.index)
      icbCommand.setVertexBuffer(
        mesh.vertexBuffers[UVBuffer.index],
        offset: 0,
        at: UVBuffer.index)
      icbCommand.setFragmentBuffer(
        submesh.argumentBuffer!,
        offset: 0,
        at: MaterialBuffer.index)
    
      icbCommand.drawIndexedPrimitives(
        .triangle,
        indexCount: submesh.indexCount,
        indexType: submesh.indexType,
        indexBuffer: submesh.indexBuffer,
        indexBufferOffset: submesh.indexBufferOffset,
        instanceCount: 1,
        baseVertex: 0,
        baseInstance: modelIndex)
    }
  }
  
  mutating func initialize(models: [Model]) {
    initializeUniforms(models)
    initializeICBCommands(models)
  }
  
  func updateUniforms(scene: GameScene, uniforms: Uniforms) {
    var uniforms = uniforms
    uniformsBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)
  }
  
  func useResources(
    encoder: MTLRenderCommandEncoder,
    models: [Model]
  ) {
    encoder.pushDebugGroup("Using resources")
    encoder.useResource(uniformsBuffer, usage: .read)
    encoder.useResource(modelParamsBuffer, usage: .read)
    if let heap = TextureController.heap {
      encoder.useHeap(heap)
    }
    for model in models {
      let mesh = model.meshes[0]
      let submesh = mesh.submeshes[0]
      encoder.useResource(mesh.vertexBuffers[VertexBuffer.index], usage: .read)
      encoder.useResource(mesh.vertexBuffers[UVBuffer.index], usage: .read)
      encoder.useResource(submesh.indexBuffer, usage: .read)
      encoder.useResource(submesh.argumentBuffer!, usage: .read)
    }
    encoder.popDebugGroup()
  }

  mutating func resize(view: MTKView, size: CGSize) {
  }

  func draw(
    commandBuffer: MTLCommandBuffer,
    scene: GameScene,
    uniforms: Uniforms,
    params: Params
  ) {
    updateUniforms(scene: scene, uniforms: uniforms)
    
    guard let descriptor = descriptor,
      let renderEncoder =
      commandBuffer.makeRenderCommandEncoder(
        descriptor: descriptor) else {
      return
    }
    renderEncoder.label = label
    renderEncoder.setDepthStencilState(depthStencilState)
    renderEncoder.setRenderPipelineState(pipelineState)
    
    useResources(encoder: renderEncoder, models: scene.models)
    
    renderEncoder.executeCommandsInBuffer(icb, range: 0..<scene.models.count)

    renderEncoder.endEncoding()
  }
}
