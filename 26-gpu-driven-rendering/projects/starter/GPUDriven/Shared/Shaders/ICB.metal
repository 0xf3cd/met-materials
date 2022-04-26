#include <metal_stdlib>
using namespace metal;

#include "Common.h"

struct ICBContainer {
  command_buffer icb [[ id(0) ]];
};

struct Model {
  constant float *vertexBuffer;
  constant float *uvBuffer;
  constant uint *indexBuffer;
  constant float *materialbuffer;
};

kernel void encodeCommands(
  // `modelIndex` gives the thread position in the grid, which is also the index into the arrays of `models` and `modelParams`.
  uint modelIndex [[thread_position_in_grid]],

  // The indirect cmd buffer and uniforms will be further encoded to the vertex and fragment shaders.
  device ICBContainer *icbContainer [[buffer(ICBBuffer)]],
  constant Uniforms &uniforms [[buffer(UniformsBuffer)]],
  
  constant Model *models [[buffer(ModelsBuffer)]],
  constant ModelParams *modelParams [[buffer(ModelParamsBuffer)]],
  constant MTLDrawIndexedPrimitivesIndirectArguments *drawArgumentsBuffer [[buffer(DrawArgumentsBuffer)]]
) {
  // Retrieve the model and draw arguments.
  Model model = models[modelIndex];
  MTLDrawIndexedPrimitivesIndirectArguments drawArguments = drawArgumentsBuffer[modelIndex];
  
  render_command cmd(icbContainer->icb, modelIndex);
  
  cmd.set_vertex_buffer(&uniforms, UniformsBuffer);
  cmd.set_vertex_buffer(model.vertexBuffer, VertexBuffer);
  cmd.set_vertex_buffer(model.uvBuffer, UVBuffer);
  cmd.set_vertex_buffer(modelParams, ModelParamsBuffer);
  
  cmd.set_fragment_buffer(modelParams, ModelParamsBuffer);
  cmd.set_fragment_buffer(model.materialbuffer, MaterialBuffer);
  
  cmd.draw_indexed_primitives(
    primitive_type::triangle,
    drawArguments.indexCount,
    model.indexBuffer + drawArguments.indexStart,
    drawArguments.instanceCount,
    drawArguments.baseVertex,
    drawArguments.baseInstance);
}
