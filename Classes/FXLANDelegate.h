//
//  FXLANDelegate.h
//  RoyalArt
//
//  Created by 张大宗 on 2017/5/8.
//
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger,FXLANConnectState){
    /*
     *  无连接
     */
    FXLANConnectStateFirstNone = 0,
    /*
     *  首次连接
     */
    FXLANConnectStateFirst = 0,
    /*
     *  正在连接
     */
    FXLANConnectStateConnecting = 1,
    /*
     *  已连接
     */
    FXLANConnectStateConnected = 2,
    /*
     *  断开连接
     */
    FXLANConnectStateNotConnected = 3,
};

@protocol FXLANDelegate <NSObject>

/*
 *  收到消息
 */
- (void)receiveMessage:(NSDictionary*)message;

/*
 *  开始搜索
 */
- (void)startSearch;

/*
 *  搜索到设备
 */
- (void)searchDevice:(NSString*)name;

/*
 *  浏览失败
 */
- (void)searchFail:(NSString*)errMsg;

/*
 *  广播失败
 */
- (void)advertiseFail:(NSString*)errMsg;

/*
 *  是否接受邀请
 */
- (void)acceptInvite:(NSString*)message Block:(void(^)(BOOL accept))block;

/*
 *  首次连接
 */
- (void)refreshConnectState:(FXLANConnectState)state;

@end
