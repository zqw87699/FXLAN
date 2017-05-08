//
//  FXLAN.m
//  TTTT
//
//  Created by 张大宗 on 2017/5/8.
//
//

#import "FXLAN.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define FX_SERVICE @"FXService"

@interface FXLAN()<MCSessionDelegate,MCNearbyServiceBrowserDelegate,MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, strong)MCNearbyServiceBrowser *browser;

@property (nonatomic, strong)MCPeerID *peerID;

@property (nonatomic, strong)MCSession*currentSession;

@property (nonatomic, strong)MCNearbyServiceAdvertiser*advertiser;

@property (nonatomic, strong)NSMutableArray*peerList;

@property (nonatomic, strong)MCPeerID*invitePeer;

@property (nonatomic, assign)BOOL pushDevice;

@end

@implementation FXLAN

+(instancetype)sharedInstance{
    static dispatch_once_t once;
    static id singleton;
    dispatch_once( &once, ^{
        singleton = [[self alloc] init];
        if ([singleton respondsToSelector:@selector(singleInit)]) {
            [singleton singleInit];
        }
    });
    return singleton;
}

- (void)singleInit{
    self.peerList = [[NSMutableArray alloc] init];
    NSString *name = [[UIDevice currentDevice] name];
    NSLog(@"%@",name);
    self.peerID = [[MCPeerID alloc] initWithDisplayName:name];
    self.currentSession = [[MCSession alloc] initWithPeer:self.peerID];
    self.currentSession.delegate = self;
}

- (void)advertiseSelf:(BOOL)shouldAdvertise{
    if (shouldAdvertise) {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:FX_SERVICE];
        self.advertiser.delegate=self;
        [self.advertiser startAdvertisingPeer];
    }else{
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
}

- (void)browserNearbyDevice{
    if (!self.browser) {
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:FX_SERVICE];
        self.browser.delegate = self;
    }
    self.pushDevice = true;
    [self.browser startBrowsingForPeers];
    if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(startSearch)]) {
        [self.delegate startSearch];
    }
}

- (void)inviteDevice:(NSString *)message{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    [self.browser invitePeer:self.invitePeer toSession:self.currentSession withContext:data timeout:30];
}

- (void)continueBrowser{
    if ([self.peerList indexOfObject:self.invitePeer] == NSNotFound) {
        NSLog(@"发生未知错误!");
    }else{
        if (self.invitePeer != self.peerList.lastObject) {
            NSUInteger index = [self.peerList indexOfObject:self.invitePeer];
            self.invitePeer = [self.peerList objectAtIndex:index+1];
            if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(searchDevice:)]) {
                [self.delegate searchDevice:self.invitePeer.displayName];
            }
        }else{
            self.pushDevice = true;
        }
    }
}

- (void)stopBrowser{
    [self.browser stopBrowsingForPeers];
    self.invitePeer = nil;
    [self.peerList removeAllObjects];
}

- (void)cancelConnect{
    [self.currentSession disconnect];
    [self stopBrowser];
}

- (void)sendMessage:(NSDictionary *)message{
    NSData*data = [NSJSONSerialization dataWithJSONObject:message options:NSJSONWritingPrettyPrinted error:nil];
    [self.currentSession sendData:data toPeers:@[self.invitePeer] withMode:MCSessionSendDataReliable error:nil];
}

#pragma mark MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(nullable NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler{
    NSLog(@"%@",peerID);
    self.invitePeer = peerID;
    NSError*error;
    NSString *message = [NSKeyedUnarchiver unarchiveObjectWithData:context];
    if (error) {
        NSString*errMsg = [NSString stringWithFormat:@"数据解析失败:%@",error.localizedDescription];
        NSLog(@"%@",errMsg);
    }else{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(acceptInvite:Block:)]) {
            [self.delegate acceptInvite:message Block:^(BOOL accept) {
                if (accept) {
                    invitationHandler(accept,self.currentSession);
                }else{
                    invitationHandler(accept,self.currentSession);
                }
            }];
        }
    }
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error{
    NSString *errMsg = [NSString stringWithFormat:@"无法广播,请检查是否开启蓝牙或WIFI:%@",error.localizedDescription];
    NSLog(@"%@",errMsg);
    if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(advertiseFail:)]) {
        [self.delegate advertiseFail:errMsg];
    }
}

#pragma mark MCNearbyServiceBrowserDelegate
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info{
    NSLog(@"%@",peerID);
    if ([self.peerList indexOfObject:peerID] == NSNotFound) {
        if (!self.invitePeer) {
            self.pushDevice = false;
            if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(searchDevice:)]) {
                [self.delegate searchDevice:peerID.displayName];
            }
            self.invitePeer = peerID;
        }else{
            if (self.invitePeer == self.peerList.lastObject) {
                if (self.pushDevice == true) {
                    self.pushDevice = false;
                    if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(searchDevice:)]) {
                        [self.delegate searchDevice:peerID.displayName];
                    }
                    self.invitePeer = peerID;
                }
            }
        }
        [self.peerList addObject:peerID];
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    [self.peerList removeObject:peerID];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error{
    NSString *errMsg = [NSString stringWithFormat:@"开启浏览失败:%@",error.localizedDescription];
    NSLog(@"%@",errMsg);
    if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(searchFail:)]) {
        [self.delegate searchFail:errMsg];
    }
}
#pragma mark MCSessionDelegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    if (peerID == self.invitePeer) {
        switch (state) {
            case MCSessionStateNotConnected:
                NSLog(@"对方未连接");
                if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(refreshConnectState:)]) {
                    [self.delegate refreshConnectState:FXLANConnectStateNotConnected];
                }
                break;
            case MCSessionStateConnecting:
                NSLog(@"正在建立连接");
                if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(refreshConnectState:)]) {
                    [self.delegate refreshConnectState:FXLANConnectStateConnecting];
                }
                break;
            case MCSessionStateConnected:
                NSLog(@"对方已连接");
                if (self.delegate !=nil && [self.delegate respondsToSelector:@selector(refreshConnectState:)]) {
                    [self.delegate refreshConnectState:FXLANConnectStateConnected];
                }
                break;
            default:
                break;
        }
    }
}
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSError*error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSLog(@"数据解析失败:%@",error.localizedDescription);
    }else{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(receiveMessage:)]) {
            [self.delegate receiveMessage:dict];
        }
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(nullable NSError *)error{
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(refreshConnectState:)]) {
        [self.delegate refreshConnectState:FXLANConnectStateFirst];
    }
    certificateHandler(YES);
}

@end
