import MetalKit

struct Quad {
  let vertexBuffer: MTLBuffer
  let indexBuffer: MTLBuffer
  let colorBuffer: MTLBuffer
  
  var oldVertices: [Float] = [
    -1,  1,  0,
     1,  1,  0,
    -1, -1,  0,
    -1,  1,  0,
     1,  1,  0,
     1, -1,  0
  ]
  
  var vertices: [Float] = [
    -1,  1,  0,
     1,  1,  0,
    -1, -1,  0,
     1, -1,  0
  ]
  
  var indices: [UInt16] = [
    0, 3, 2,
    0, 1, 3
  ]
  
  var colors: [simd_float3] = [
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 0]
  ]
  
  init(device: MTLDevice, scale: Float = 1) {
    vertices = vertices.map { $0 * scale }
    guard let vertexBuffer = device.makeBuffer(
      bytes: &vertices,
      length: MemoryLayout<Float>.stride * vertices.count,
      options: [])
    else {
      fatalError("Unable to create quad vertex buffer")
    }
    self.vertexBuffer = vertexBuffer
    
    guard let indexBuffer = device.makeBuffer(
      bytes: &indices,
      length: MemoryLayout<UInt16>.stride * indices.count,
      options: [])
    else {
      fatalError("Unable to create quad index buffer")
    }
    self.indexBuffer = indexBuffer
    
    guard let colorBuffer = device.makeBuffer(
      bytes: &colors,
      length: MemoryLayout<simd_float3>.stride * colors.count,
      options: [])
    else {
      fatalError("Unable to create quad color buffer")
    }
    self.colorBuffer = colorBuffer
  }
}
