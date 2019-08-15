//
//  FLTFrameUpdater.h
//  flutter_plugin_demo3
//
//  Created by Wei on 2019/5/15.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTFrameUpdater : NSObject
@property(nonatomic) int64_t textureId;
@property(nonatomic, readonly) NSObject<FlutterTextureRegistry>* registry;

-(void)refreshDisplay;
- (FLTFrameUpdater*)initWithRegistry:(NSObject<FlutterTextureRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
