//
//  STIMWorkNoticeMessageModel.m
//  STIMUIKit
//
//  Created by lihaibin.li on 2019/1/17.
//  Copyright © 2019 STIM. All rights reserved.
//

#import "STIMWorkNoticeMessageModel.h"

@implementation STIMWorkNoticeMessageModel

- (NSString *)description{
    NSMutableString *str = [NSMutableString stringWithString:[self stimDB_properties_aps]];
    return str;
}

@end
