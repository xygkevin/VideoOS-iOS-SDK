//
//  VPMPContainerStatusView.m
//  VideoPlsLuaViewManagerSDK
//
//  Created by Zard1096-videojj on 2019/8/5.
//  Copyright © 2019 videopls. All rights reserved.
//

#import "VPMPContainerStatusView.h"
#import "VPUPHexColors.h"

@interface VPMPContainerStatusView()

@property (nonatomic) UIView *backgroundView;

@end

@implementation VPMPContainerStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}

- (void)initView {
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    _backgroundView.backgroundColor = [VPUPHXColor vpup_colorWithHexARGBString:@"3C4049"];
    _backgroundView.alpha = 1;
    [self addSubview:_backgroundView];
}

@end
