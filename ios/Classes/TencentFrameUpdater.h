
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface TencentFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, readonly) NSObject<FlutterTextureRegistry>* registry;

-(void)refreshDisplay;
- (TencentFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
