//
//  VPLuaAppletsView.m
//  VideoPlsLuaViewManagerSDK
//
//  Created by Zard1096-videojj on 2019/7/30.
//  Copyright © 2019 videopls. All rights reserved.
//

#import "VPLuaAppletsView.h"
#import "VideoPlsUtilsPlatformSDK.h"
#import "VideoPlsLuaViewSDK.h"
//#import "VPLuaServiceManager.h"
#import "VPUPRSAUtil.h"
#import "VPLuaSDK.h"
#import "VPLuaPlayer.h"
#import "VPLuaAppletContainer.h"
#import "VPLuaAppletLandscapeContainer.h"

@interface VPLuaAppletsView () <VPLuaAppletContainerDelegate>

@property (nonatomic, weak) VPLuaNetworkManager *networkManager;

@property (nonatomic) NSMutableDictionary<NSString *, id<VPLuaAppletContainer>> *containers;

@property (nonatomic,   copy) NSString *luaPath;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isPortrait;

@property (nonatomic, assign) BOOL isStartLoading;
@property (nonatomic, assign) BOOL isOpenConfig;
@property (nonatomic, assign) BOOL configIsFullScreen;

@end

@implementation VPLuaAppletsView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame platformId:nil videoId:nil];
}

- (instancetype)initWithFrame:(CGRect)frame platformId:(NSString *)platformId videoId:(NSString *)videoId {
    return [self initWithFrame:frame platformId:platformId videoId:videoId extendInfo:nil];
}

- (instancetype)initWithFrame:(CGRect)frame platformId:(NSString *)platformId videoId:(NSString *)videoId extendInfo:(NSDictionary *)extendInfo
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initNetworkManager];
//        [VPLuaServiceManager startService];
        self.luaPath = [VPUPPathUtil luaAppletsPath];
        
        self.videoInfo = [[VPLuaVideoInfo alloc] init];
        self.videoInfo.platformID = platformId;
        self.videoInfo.nativeID = videoId;
        if ([extendInfo objectForKey:@"category"]) {
            self.videoInfo.category = [extendInfo objectForKey:@"category"];
        }
        if (extendInfo) {
            self.videoInfo.extendJSONString = VPUP_DictionaryToJson(extendInfo);
        }
        [VPLuaSDK sharedSDK].videoInfo = self.videoInfo;
    }
    
    return self;
}

- (void)updateFrame:(CGRect)frame videoRect:(CGRect)videoRect isFullScreen:(BOOL)isFullScreen {
    self.frame = frame;
    self.isFullScreen = isFullScreen;
    if (frame.size.width > frame.size.height) {
        self.isPortrait = NO;
    } else {
        self.isPortrait = YES;
    }
    
//    [self.luaController updateFrame:self.bounds isPortrait:self.isPortrait isFullScreen:self.isFullScreen];
    //TODO: containers update frame
}

- (void)updateVideoPlayerOrientation:(VPLuaVideoPlayerOrientation)type {
    self.frame = [UIScreen mainScreen].bounds;
    switch (type) {
        case VPLuaVideoPlayerOrientationPortraitSmallScreen:
            self.isFullScreen = NO;
            self.isPortrait = YES;
            break;
        case VPLuaVideoPlayerOrientationPortraitFullScreen:
            self.isFullScreen = YES;
            self.isPortrait = YES;
            break;
        case VPLuaVideoPlayerOrientationLandscapeFullScreen:
            self.isFullScreen = YES;
            self.isPortrait = NO;
            break;
            
        default:
            break;
    }
    
    if (self.isPortrait) {
        [self.containers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<VPLuaAppletContainer>  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.type == VPLuaAppletContainerTypeLandscape) {
                [obj hide];
            }
        }];
    } else {
        [self.containers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<VPLuaAppletContainer>  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.type == VPLuaAppletContainerTypeLandscape) {
                [obj show];
            }
        }];
    }
//    self.luaController.currentOrientation = type;
//    [self.luaController updateFrame:self.bounds isPortrait:self.isPortrait isFullScreen:self.isFullScreen];
    
    //TODO: containers update orientation
    
}

- (void)setGetUserInfoBlock:(NSDictionary *(^)(void))getUserInfoBlock {
    _getUserInfoBlock = getUserInfoBlock;
    
//    [self.luaController setGetUserInfoBlock:getUserInfoBlock];
    //TODO: containers set userinfoblock
}

- (void)startLoading {
    self.isStartLoading = YES;
    if (!self.videoInfo) {
        self.videoInfo = [[VPLuaVideoInfo alloc] init];
    }
//    [self initLuaView];
}

- (void)stop {
    [self.containers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<VPLuaAppletContainer>  _Nonnull obj, BOOL * _Nonnull stop) {
        obj.containerDelegate = nil;
        [obj destroyView];
    }];
    
    [self.containers removeAllObjects];
}

- (void)closeActionWebViewForAd:(NSString *)adId {
//    [self.luaController closeActionWebViewForAd:adId];
}

- (void)pauseVideoAd {
    [[NSNotificationCenter defaultCenter] postNotificationName:VPLuaPauseVideoPlayerNotification object:nil];
}

- (void)playVideoAd {
//    [self.luaController playVideoAd];
}

- (void)closeInfoView {
//    [self.luaController closeInfoView];
}

#pragma mark - private

- (void)initNetworkManager {
    self.networkManager = [VPLuaNetworkManager Manager];
}

//跳转小程序   LuaView://applets?appletId=xxxx&type=x(type: 1横屏,2竖屏)
//容器内部跳转 LuaView://applets?appletId=xxxx&template=xxxx.lua&id=xxxx&priority=x
- (void)loadAppletWithID:(NSString *)appletID data:(id)data {
    if (self.isStartLoading) {
        if (!self.containers) {
            self.containers = [NSMutableDictionary dictionary];
        }
        
        NSDictionary *queryParams = [data objectForKey:VPUPRouteQueryParamsKey];
        
        if ([queryParams objectForKey:@"type"] != nil) {
            //新建流程
            NSInteger typeInt = [[queryParams objectForKey:@"type"] integerValue];
            VPLuaAppletContainerType type;
            if (typeInt > 0 && typeInt < 3) {
                type = typeInt;
            } else {
                type = VPLuaAppletContainerTypeLandscape;
            }
            
            [self createNewContainerWithType:type appletID:appletID queryParams:queryParams data:data];
            
        } else {
            //容器内部跳转
            [self pushLuaWithAppletID:appletID queryParams:queryParams data:data];
        }
    }
}

- (void)createNewContainerWithType:(VPLuaAppletContainerType)type
                          appletID:(NSString *)appletID
                       queryParams:(NSDictionary *)queryParams
                              data:(id)data {
    
    switch (type) {
        case VPLuaAppletContainerTypeLandscape:
        {
            if (self.isPortrait) {
                //通知改横屏
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
                //1是横屏切竖屏,2是横屏切竖屏
                [dict setObject:@(2) forKey:@"orientation"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                
                    [[NSNotificationCenter defaultCenter] postNotificationName:VPLuaScreenChangeNotification object:nil userInfo:dict];
                });
            }
            if ([self checkContainerExistWithAppletID:appletID]) {
                if ([queryParams objectForKey:@"template"] != nil) {
                    [self pushLuaWithAppletID:appletID queryParams:queryParams data:data];
                } else {
                    //存在? 也没有跳转入口
                    
                    return;
                }
            }
            VPLuaAppletLandscapeContainer *container = [[VPLuaAppletLandscapeContainer alloc] initWithAppletID:appletID networkManager:self.networkManager videoInfo:self.videoInfo luaPath:self.luaPath data:data];
            container.containerDelegate = self;
            
            [self.containers setObject:container forKey:appletID];
            
            [container showInSuperview:self];
            
            break;
        }
        case VPLuaAppletContainerTypePortrait:
        {
            
            break;
        }
        default:
            break;
    }
}

- (void)pushLuaWithAppletID:(NSString *)appletID
            queryParams:(NSDictionary *)queryParams
                       data:(id)data {
    
    if (![self checkContainerExistWithAppletID:appletID]) {
        //理论不会发生,外面已经check过
        return;
    }
    if (![queryParams objectForKey:@"template"]) {
        //理论不会发生,已经check过
        return;
    }
    id<VPLuaAppletContainer> container = [self.containers objectForKey:appletID];
    NSString *luaUrl = [queryParams objectForKey:@"template"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [container loadLua:luaUrl data:data];
    });
}

- (BOOL)checkContainerExistWithAppletID:(NSString *)appletID {
    if (!self.containers) {
        return NO;
    }
    if ([self.containers objectForKey:appletID]) {
        return YES;
    }
    return NO;
}

- (void)closeAllContainers {
    [self.containers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<VPLuaAppletContainer>  _Nonnull obj, BOOL * _Nonnull stop) {
        
        obj.containerDelegate = nil;
        [obj closeContainer];
    }];
    [self.containers removeAllObjects];
}

- (void)deleteContainerWithAppletID:(NSString *)appletID {
    if ([self checkContainerExistWithAppletID:appletID]) {
        [self.containers removeObjectForKey:appletID];
    }
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    
    return hitView;
}

- (void)dealloc {
    [self stop];
//    [VPLuaServiceManager stopService];
    [VPLuaNetworkManager releaseManaer];
}


@end