//
//  FXLAN.h
//  TTTT
//
//  Created by 张大宗 on 2017/5/8.
//
//

#import <Foundation/Foundation.h>
#import "FXLANDelegate.h"

@interface FXLAN : NSObject

@property (nonatomic, weak)id<FXLANDelegate>delegate;

+(instancetype)sharedInstance;

/*
 *  是否广播自己
 */
- (void)advertiseSelf:(BOOL)shouldAdvertise;

/*
 *  寻找附近设备
 */
-(void)browserNearbyDevice;

/*
 *  发起邀请
 */
-(void)inviteDevice:(NSString*)message;

/*
 *  继续搜索
 */
-(void)continueBrowser;

/*
 *  取消连接
 */
-(void)cancelConnect;

/*
 *  停止搜索
 */
-(void)stopBrowser;

/*
 *  发送消息
 */
-(void)sendMessage:(NSDictionary*)message;

@end
