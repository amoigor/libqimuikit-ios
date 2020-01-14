//
//  STIMMessageTableViewManager.h
//  STChatIphone
//
//  Created by 李海彬 on 2018/2/5.
//

#import "STIMCommonUIFramework.h"

@protocol QTalkMessageTableScrollViewDelegate<NSObject>

#pragma mark - Forward转发相关

- (void)QTalkMessageUpdateForwardBtnState:(BOOL)enable;

#pragma mark - 滚动
- (void)QTalkMessageScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)QTalkMessageScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)QTalkMessageScrollViewWillEndDragging:(UIScrollView *)scrollView
                                 withVelocity:(CGPoint)velocity
                          targetContentOffset:(inout CGPoint *)targetContentOffset;

@end

@interface STIMMessageTableViewManager : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id <QTalkMessageTableScrollViewDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property(nonatomic, strong) NSMutableSet *forwardSelectedMsgs;

@property (nonatomic, assign) CGFloat width;

- (instancetype)initWithChatId:(NSString *)chatId ChatType:(ChatType)chatType OwnerVc:(QTalkViewController *)ownerVc;

@end
