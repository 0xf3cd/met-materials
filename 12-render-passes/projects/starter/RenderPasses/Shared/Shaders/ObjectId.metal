#import "Common.h"

struct FragmentOut {
  uint objectId [[color(0)]];
};

fragment FragmentOut fragment_objectId(
  constant Params &params [[buffer(ParamsBuffer)]]
) {
  return FragmentOut {
    .objectId = params.objectId
  };
}
