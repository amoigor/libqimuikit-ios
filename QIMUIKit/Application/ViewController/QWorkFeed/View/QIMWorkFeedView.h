//
//  QIMWorkFeedView.h
//  QIMUIKit
//
//  Created by lilu on 2019/4/29.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "QIMCommonUIFramework.h"

NS_ASSUME_NONNULL_BEGIN

@interface QIMWorkFeedView : UIView

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, strong) UIViewController *rootVC;

- (void)updateMomentView;

@end

NS_ASSUME_NONNULL_END
