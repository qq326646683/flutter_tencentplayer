
#import "TencentFrameUpdater.h"

@implementation TencentFrameUpdater
- (TencentFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry {
    NSAssert(self, @"super init cannot be nil");
    if (self == nil) return nil;
    _registry = registry;
    return self;
}

-(void)refreshDisplay{
    [_registry textureFrameAvailable:self.textureId];
}
@end
