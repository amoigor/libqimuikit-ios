//
//  QTalkSessionCell.m
//  qunarChatIphone
//
//  Created by Qunar-Lu on 16/7/20.
//
//

#import "QTalkSessionCell.h"
#import "UILabel+AttributedTextWithItems.h"
#import "QIMBadgeButton.h"
#import "QIMJSONSerializer.h"
#import "QIMCommonFont.h"
#import "NSBundle+QIMLibrary.h"

static NSDateFormatter  *__global_dateformatter;
#define NAME_LABEL_FONT     ([[QIMCommonFont sharedInstance] currentFontSize] )  //名字字体
#define CONTENT_LABEL_FONT  ([[QIMCommonFont sharedInstance] currentFontSize] - 4)  //新消息字体,时间字体
#define COLOR_TIME_LABEL [UIColor blueColor] //时间颜色;

#define kUtilityButtonsWidthMax 260
#define kUtilityButtonWidthDefault 90

static NSString * const kTableViewCellContentView = @"UITableViewCellContentView";

@interface QTalkSessionCell () <UIScrollViewDelegate> {
    
}

@property (nonatomic, assign) BOOL needRefreshName;

@property (nonatomic, assign) BOOL needRefreshHeader;

@property (nonatomic, assign) BOOL needRefreshNotReadCount;

@property (nonatomic, assign) BOOL isStick;

@property (nonatomic, assign) BOOL isReminded;              //是否为免打扰

@property (nonatomic, strong) UIImageView *headerView;      //头像

@property (nonatomic, strong) UIImageView *stickView;       //置顶标示View

@property (nonatomic, strong) UILabel *nameLabel;           //Name

@property (nonatomic, strong) UILabel *contentLabel;        //消息Content

@property (nonatomic, strong) UILabel *timeLabel;           //消息时间戳

@property (nonatomic, strong) QIMBadgeButton *notReadNumButton;   //未读数拖拽按钮

@property (nonatomic, strong) UIImageView *muteView;            //消息免打扰

@property (nonatomic, strong) UIImageView *muteNotReadView;     //接收不提醒小红点提醒

@property (nonatomic, strong) UIImageView *prefrenceImageView;  //热线咨询标识

#pragma mark - infoDic

@property (nonatomic, assign) QIMMessageType msgType;

@property (nonatomic, assign) QIMMessageSendState msgState;

@property (nonatomic, assign) QIMMessageDirection msgDirection;

@property (nonatomic, assign) long long msgDateTime;

@property (nonatomic, copy) NSString *showName;             //展示的Name

@property (nonatomic, copy) NSString *jid;

@property (nonatomic, copy) NSString *content;

@property (nonatomic, copy) NSString *nickName;

@property (nonatomic, copy) NSString *msgFrom;

@property (nonatomic, copy) NSString *markUpName;

@property (nonatomic, strong)QIMMessageModel *currentMsg;          //当前消息

@property (nonatomic, strong) dispatch_queue_t reloadNotReadCountQueue;

@property (nonatomic, strong) dispatch_queue_t reloadHeaderQueue;

@property (nonatomic, strong) dispatch_queue_t reloadNameQueue;

@end

@implementation QTalkSessionCell

- (void)setInfoDic:(NSDictionary *)infoDic {
    if (infoDic) {
        if (!self.bindId) {
            //这里不能根据MsgId判断，还有消息状态
            _infoDic = infoDic;
            NSString *msgId = [infoDic objectForKey:@"LastMsgId"];
            if ([self.currentMsg.messageId isEqualToString:msgId]) {
                return;
            }
            NSString *xmppId = [infoDic objectForKey:@"XmppId"];
            self.showName = [infoDic objectForKey:@"Name"];
            self.markUpName = [infoDic objectForKey:@"MarkUpName"];
            if (![self.jid isEqualToString:xmppId]) {
                self.jid = xmppId;
//                [self refreshName];
//                [self refreshHeaderImage];
            }
            self.msgType = [[infoDic objectForKey:@"MsgType"] integerValue];
            self.msgState = [[infoDic objectForKey:@"MsgState"] integerValue];
            self.content = [infoDic objectForKey:@"Content"];
            self.chatType = [[infoDic objectForKey:@"ChatType"] integerValue];
            self.msgDateTime = [[infoDic objectForKey:@"MsgDateTime"] longLongValue];
            self.msgDirection = [[infoDic objectForKey:@"MsgDirection"] integerValue];
            self.isStick = [[infoDic objectForKey:@"StickState"] boolValue];
            self.isReminded = [[infoDic objectForKey:@"Reminded"] boolValue];
            self.msgFrom = [infoDic objectForKey:@"MsgFrom"];
            /*
            NSDictionary *userInfo = [[QIMKit sharedInstance] getUserInfoByUserId:self.nickName];
            NSString *userName = [userInfo objectForKey:@"Name"];
            if (!userName || userName.length <= 0) {
                userName = [[self.nickName componentsSeparatedByString:@"@"] firstObject];
            }
            //备注
            NSString *remarkName = [[QIMKit sharedInstance] getUserMarkupNameWithUserId:userInfo[@"XmppId"]];
            self.nickName = (remarkName.length > 0) ? remarkName : userName;
            */
            dispatch_async(dispatch_get_main_queue(), ^{
                self.jid = xmppId;
//                [self refreshUI];
                [self generateCombineJidWithChatType:self.chatType];
            });
        } else {
            _infoDic = infoDic;
            self.jid = [infoDic objectForKey:@"XmppId"];
            ChatType chatType = [[infoDic objectForKey:@"ChatType"] intValue];
            self.msgType = [[infoDic objectForKey:@"MsgType"] intValue];
            self.msgState = [[infoDic objectForKey:@"MsgState"] intValue];
            self.content = [infoDic objectForKey:@"Content"];
            [self generateCombineJidWithChatType:chatType];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self refreshName];
//                [self refreshHeaderImage];
//                [self refreshUI];
//            });
        }
    }
}

- (void)generateCombineJidWithChatType:(ChatType)chatType {
    switch (chatType) {
        case ChatType_ConsultServer: {
            NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
            self.combineJid = [NSString stringWithFormat:@"%@<>%@", self.jid, realJid];
        }
            break;
        default: {
            self.combineJid = [NSString stringWithFormat:@"%@<>%@", self.jid, self.jid];
        }
            break;
    }
}

- (void)reloadPlaceHolderName {
    self.showName = [self.infoDic objectForKey:@"UserId"];
    if (!self.showName.length) {
        self.showName = [[self.jid componentsSeparatedByString:@"@"] firstObject];
    }
}

+ (CGFloat)getCellHeight{
    
    return 71;
}

#pragma mark - setter and getter

- (UIImageView *)headerView {
    
    if (!_headerView) {
        
        _headerView = [[UIImageView alloc] initWithFrame:CGRectMake(12, [self.class getCellHeight] / 2 - 24, 48, 48)];
        _headerView.backgroundColor = [UIColor clearColor];
        _headerView.layer.cornerRadius = 24.0f;
        _headerView.layer.masksToBounds = YES;
    }
    return _headerView;
}

- (UIImageView *)stickView {
    if (!_stickView) {
        _stickView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 11, 11)];
        _stickView.image = [UIImage qim_imageNamedFromQIMUIKitBundle:@"qim_sessionlist_sticky"];
    }
    return _stickView;
}

- (UIImageView *)muteNotReadView {
    if (!_muteNotReadView) {

        _muteNotReadView = [[UIImageView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] qim_leftWidth] - 20, self.timeLabel.bottom + 15, 8, 8)];
        _muteNotReadView.backgroundColor = [UIColor qim_colorWithHex:0xEB524A];
        _muteNotReadView.layer.cornerRadius  = _muteNotReadView.width / 2.0;
        _muteNotReadView.clipsToBounds = YES;
        _muteNotReadView.centerY = self.muteView.centerY;
    }
    return _muteNotReadView;
}

- (UIImageView *)prefrenceImageView {
    
    if (!_prefrenceImageView) {
        
        _prefrenceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.headerView.right - 18, self.headerView.bottom - 15, 15, 15)];
        [_prefrenceImageView setImage:[UIImage qim_imageNamedFromQIMUIKitBundle:@"hotline"]];
        [_prefrenceImageView setBackgroundColor:[UIColor whiteColor]];
        _prefrenceImageView.layer.masksToBounds = YES;
    }
    return _prefrenceImageView;
}

- (UILabel *)nameLabel {
    
    if (!_nameLabel) {
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 17, [[UIScreen mainScreen] qim_leftWidth] - 145, qim_sessionViewNameLabelSize)];
        _nameLabel.font = [UIFont boldSystemFontOfSize:qim_sessionViewNameLabelSize];
        _nameLabel.textColor = qim_sessionCellNameTextColor;
        _nameLabel.backgroundColor = [UIColor clearColor];
    }
    return _nameLabel;
}

- (UILabel *)contentLabel {
    
    if (!_contentLabel) {
        
        CGFloat timeLabelMaxX = CGRectGetMaxX(self.timeLabel.frame);
        CGFloat contentLabelWidth = timeLabelMaxX - self.nameLabel.left - 35;
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nameLabel.left, self.nameLabel.bottom + 7, contentLabelWidth, qim_sessionViewContentLabelSize)];
        _contentLabel.font = [UIFont systemFontOfSize:qim_sessionViewContentLabelSize];
        _contentLabel.textColor = qim_sessionCellContentTextColor;
        _contentLabel.backgroundColor = [UIColor clearColor];
    }
    return _contentLabel;
}

- (UILabel *)timeLabel {
    
    if (!_timeLabel) {
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] qim_leftWidth] - 85, self.nameLabel.bottom - 16, 75, 12)];
        _timeLabel.font = [UIFont systemFontOfSize:qim_sessionViewTimeLabelSize];
        _timeLabel.textColor = qim_sessionCellTimeTextColor;
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.textAlignment = NSTextAlignmentRight;
    }
    
    return _timeLabel;
}

- (UIImageView *)muteView {
    
    if (!_muteView) {
        
        _muteView = [[UIImageView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] qim_leftWidth] - 40, self.timeLabel.bottom + 15, 15, 15)];
        _muteView.layer.cornerRadius = _muteView.width / 2.0;
        _muteView.clipsToBounds = YES;
        _muteView.backgroundColor = self.backgroundColor;
        _muteView.image = [UIImage qimIconWithInfo:[QIMIconInfo iconInfoWithText:qim_sessionViewMute_font size:15 color:qim_sessionViewMuteColor]];
        _muteView.centerY = self.contentLabel.centerY;
    }
    return _muteView;
}

- (void)setUpNotReadNumButtonWithFrame:(CGRect)frame withBadgeString:(NSString *)badgeString {
    if (!CGRectEqualToRect(frame, self.notReadNumButton.frame) && !CGRectEqualToRect(frame, CGRectZero)) {
        [self.notReadNumButton removeFromSuperview];
        self.notReadNumButton = nil;
        _notReadNumButton = [[QIMBadgeButton alloc] initWithFrame:frame];
        [_notReadNumButton setBadgeFont:[UIFont systemFontOfSize:14]];
        _notReadNumButton.isShowSpringAnimation = YES;
        _notReadNumButton.isShowBomAnimation = YES;
        _notReadNumButton.right = self.timeLabel.right;
        _notReadNumButton.centerY = self.contentLabel.centerY;
        [self.contentView insertSubview:_notReadNumButton atIndex:0];
    } else {
        if (!_notReadNumButton) {
            _notReadNumButton = [[QIMBadgeButton alloc] initWithFrame:CGRectMake(self.timeLabel.right - 35, 11, 35, 20)];
            [_notReadNumButton setBadgeFont:[UIFont systemFontOfSize:14]];
            _notReadNumButton.isShowSpringAnimation = YES;
            _notReadNumButton.isShowBomAnimation = YES;
            _notReadNumButton.right = self.timeLabel.right;
            _notReadNumButton.centerY = self.contentLabel.centerY;
            [self.contentView insertSubview:_notReadNumButton atIndex:0];
        }
    }
    self.chatType = [[self.infoDic objectForKey:@"ChatType"] integerValue];
    [self.notReadNumButton setBadgeColor:qim_sessionViewNotReadNumButtonColor];
    [self.notReadNumButton setBadgeString:badgeString];
    __weak typeof(self) weakSelf = self;
    [self.notReadNumButton setDidClickBlock:^(QIMBadgeButton * badgeButton) {
        [weakSelf clearNotRead];
    }];
    [self.notReadNumButton setDidDisappearBlock:^(QIMBadgeButton * badgeButton) {
        [weakSelf clearNotRead];
    }];
    __block BOOL groupState = NO;
    if (self.isReminded == NO) {
        [self.notReadNumButton setBadgeColor:qim_sessionViewNotReadNumButtonColor];
    } else {
        [self.notReadNumButton hiddenBadgeButton:YES];
        [self.contentView addSubview:self.muteNotReadView];
    }
}

- (QIMBadgeButton *)notReadNumButton {
    return _notReadNumButton;
}

- (UITableViewRowAction *)deleteBtn {
    
    if (!_deleteBtn) {
        
        _deleteBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"移除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            
            if (self.sessionScrollDelegate && [self.sessionScrollDelegate respondsToSelector:@selector(deleteSession:)]) {
                
                [self.sessionScrollDelegate deleteSession:indexPath];
            }
            [self.containingTableView setEditing:NO animated:YES];
        }];
    }
    _deleteBtn.backgroundColor = [UIColor redColor];
    return _deleteBtn;
}

- (UITableViewRowAction *)stickyBtn {
    
    NSString *title = self.isStick ? @"取消置顶" : @"置顶";
    
    _stickyBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:title handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        if (self.sessionScrollDelegate && [self.sessionScrollDelegate respondsToSelector:@selector(stickySession:)]) {
            
            [self.sessionScrollDelegate stickySession:indexPath];
        }
        [self.containingTableView setEditing:NO animated:YES];
    }];
    _stickyBtn.backgroundColor = [UIColor qim_colorWithHex:0xC8C9CB];
    
    return _stickyBtn;
}

#pragma mark - life ctyle

- (void)initUI {
    
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.selectedBackgroundView.backgroundColor = [UIColor qim_colorWithHex:0xEEEEEE];
    [self.contentView addSubview:self.headerView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.muteView];
}

- (void)setUpNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCellNotReadCount:) name:kMsgNotReadCountChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRemindState:) name:kRemindStateChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCellHeaderImage:) name:kUserHeaderImgUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCellUserStatusChange:) name:kUserStatusChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCell:) name:kNotificationMessageUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroupNickName:) name:kGroupNickNameChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState:) name:kNotifyUserOnlineStateUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(revokeMsgHandle:) name:kRevokeMsg object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markNameUpdate:) name:kMarkNameUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(atallChangeHandle:) name:kAtALLChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(atallChangeHandle:) name:kAtMeChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroupNotMindState:) name:kGroupMsgRemindDic object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroupNickName:) name:kCollectionGroupNickNameChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:kUserVCardUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:kCollectionUserVCardUpdate object:nil];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self setUpNotification];
        self.reloadNameQueue = dispatch_queue_create("reload Name Queue", 0);
        self.reloadHeaderQueue = dispatch_queue_create("reload Header Queue", 0);
        self.reloadNotReadCountQueue = dispatch_queue_create("reload Content Queue", 0);
        
        [self initUI];
        self.bindId = nil;
        self.needRefreshName = YES;
//        self.needRefreshHeader = YES;
    }
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setInfoDic:nil];
}

#pragma mark - Overriden methods

- (void)clearNotRead {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (!self.bindId) {
            if (self.chatType == ChatType_GroupChat) {
                
                [[QIMKit sharedInstance] clearNotReadMsgByGroupId:self.jid];
            } else if (self.chatType == ChatType_SingleChat) {
                
                [[QIMKit sharedInstance] clearNotReadMsgByJid:self.jid];
            } else if (self.chatType == ChatType_System) {
                
                [[QIMKit sharedInstance] clearSystemMsgNotReadWithJid:self.jid];
            } else if (self.chatType == ChatType_PublicNumber) {
                [[QIMKit sharedInstance] clearNotReadMsgByPublicNumberId:self.jid];
            } else if (self.chatType == ChatType_ConsultServer) {
                NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
                NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
                [[QIMKit sharedInstance] clearNotReadMsgByJid:xmppId ByRealJid:realJid];
            } else if (self.chatType == ChatType_Consult) {
                NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
                [[QIMKit sharedInstance] clearNotReadMsgByJid:xmppId ByRealJid:xmppId];
            } else if (self.chatType == ChatType_CollectionChat) {
                NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
                [[QIMKit sharedInstance] clearNotReadCollectionMsgByJid:xmppId];
            } else {
                
                return;
            }
        } else {
            [[QIMKit sharedInstance] clearNotReadCollectionMsgByBindId:self.bindId WithUserId:self.jid];
        }
    });
}

- (void)updateGroupNotMindState:(NSNotification *)notify {
    
//    QIMVerboseLog(@"收到通知中心updateGroupNotMindState通知 : %@", notify);
    NSString *groupJid = notify.object;
    if ([groupJid isEqualToString:self.jid]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadNotReadCount) object:nil];
            [self performSelector:@selector(reloadNotReadCount) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
    }
}

#pragma mark - kMsgNotReadCountChange 更新Cell未读数
- (void)updateCellNotReadCount:(NSNotification *)notify {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *notifyDic = notify.object;
        BOOL ForceRefresh = [[notifyDic objectForKey:@"ForceRefresh"] boolValue];
        if (ForceRefresh == YES) {
            NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
            NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
            __weak __typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                weakSelf.notReadCount = [[QIMKit sharedInstance] getNotReadMsgCountByJid:xmppId WithRealJid:realJid withChatType:weakSelf.chatType];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadNotReadCount];
                });
                return;
            });
        }
        if (!self.bindId) {
            NSString *notifyJid = [notifyDic objectForKey:@"XmppId"];
            NSString *notifyRealJid = [notifyDic objectForKey:@"RealJid"];
            NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
            NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
            if ([notifyJid isEqualToString:xmppId] && [notifyRealJid isEqualToString:realJid]) {
                __weak __typeof(self) weakSelf = self;
                dispatch_async([[QIMKit sharedInstance] getLoadSessionUnReadCountQueue], ^{
                    weakSelf.notReadCount = [[QIMKit sharedInstance] getNotReadMsgCountByJid:xmppId WithRealJid:realJid withChatType:weakSelf.chatType];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self reloadNotReadCount];
                    });
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadNotReadCount];
            });
        }
    });
}

- (void)updateRemindState:(NSNotification *)notify {
    NSString *jid = [notify object];
    if ([jid isEqualToString:@"ForceRefresh"]) {
//        self.needRefreshNotReadCount = YES;
        self.isReminded = ![[QIMKit sharedInstance] groupPushState:self.jid];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadNotReadCount];
        });
        return;
    }
    if (!self.bindId) {
        if (self.chatType == ChatType_Consult || self.chatType == ChatType_ConsultServer) {
            NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
            NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
            if ([jid isEqualToString:[NSString stringWithFormat:@"%@-%@",xmppId,realJid]]) {
                self.isReminded = ![[QIMKit sharedInstance] groupPushState:[NSString stringWithFormat:@"%@-%@", xmppId, realJid]];
//                self.needRefreshNotReadCount = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadNotReadCount];
                });
            }
        } else {
            if ([jid isEqualToString:self.jid]) {
//                self.needRefreshNotReadCount = YES;
                self.isReminded = ![[QIMKit sharedInstance] groupPushState:self.jid];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadNotReadCount];
                });
            } else if ([jid isEqualToString:@"ForceRefresh"]) {
//                self.needRefreshNotReadCount = YES;
                self.isReminded = ![[QIMKit sharedInstance] groupPushState:self.jid];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadNotReadCount];
                });
            } else {
                
            }
        }
    } else {
//        self.needRefreshNotReadCount = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadNotReadCount];
        });
    }
}

#pragma mark - kUserHeaderImgUpdate 更新Cell头像
- (void)updateCellHeaderImage:(NSNotification *)notify {
    
    NSString *jid = [notify object];
    if ([jid isEqualToString:self.jid]) {
//        QIMVerboseLog(@"收到通知中心updateCellHeaderImage通知 : %@", notify);
        dispatch_async(dispatch_get_main_queue(), ^{
//            self.needRefreshHeader = YES;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshHeaderImage) object:nil];
            [self performSelector:@selector(refreshHeaderImage) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
    }
}

#pragma mark - kUserStatusChange 更新用户在线状态
- (void)updateCellUserStatusChange:(NSNotification *)notify {

    NSString *jid = [notify object];
    if ([jid isEqualToString:self.jid]) {
//        QIMVerboseLog(@"收到通知中心updateCellUserStatusChange通知 : %@", notify);
        dispatch_async(dispatch_get_main_queue(), ^{
//            self.needRefreshHeader = YES;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshHeaderImage) object:nil];
            [self performSelector:@selector(refreshHeaderImage) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
    }
}

#pragma mark - kGroupNickNameChanged 更新群昵称
- (void)updateGroupNickName:(NSNotification *)notify {
    
    __block BOOL flag = NO;
    NSArray *groupIds = [notify object];
    if (!groupIds) {
        return;
    }
    __block NSDictionary *cardDic = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if ([groupIds containsObject:self.jid] && !self.bindId) {
            cardDic = [[QIMKit sharedInstance] getGroupCardByGroupId:self.jid];
            flag = YES;
        } else if ([groupIds containsObject:self.jid] && self.bindId) {
            
            cardDic = [[QIMKit sharedInstance] getCollectionGroupCardByGroupId:self.jid];
            flag = YES;
        } else {
            
        }
        if (cardDic.count) {
            NSString *groupName = [cardDic objectForKey:@"Name"];
            self.showName = (groupName.length > 0) ? groupName : self.showName;
            dispatch_async(dispatch_get_main_queue(), ^{
               [self.nameLabel setText:self.showName];
            });
        }
        if (flag == YES) {
            return;
        }
    });
}

- (void)updateOnlineState:(NSNotification *)notify {

//    QIMVerboseLog(@"收到通知中心updateOnlineState通知 : %@", notify);
    NSArray *userIds = notify.object;
    if (userIds.count > 0 && [userIds containsObject:self.jid]) {
//        self.needRefreshHeader = YES;
        self.firstRefresh = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshHeaderImage) object:nil];
            [self performSelector:@selector(refreshHeaderImage) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
    }
}

#pragma mark - kRevokeMsg 撤回消息
- (void)revokeMsgHandle:(NSNotification *)notify{
//    QIMVerboseLog(@"收到通知中心revokeMsgHandle通知 : %@", notify);
    NSString *jid = notify.object;
    if ([jid isEqualToString:self.jid]) {
        NSString *revokeMsg = [notify.userInfo objectForKey:@"Content"];
        NSDictionary *revokeMsgDic = [[QIMJSONSerializer sharedInstance] deserializeObject:revokeMsg error:nil];
        if (revokeMsgDic.count > 0) {
            NSString *messageId = [revokeMsgDic objectForKey:@"messageId"];
            NSString *userJid = [revokeMsgDic objectForKey:@"fromId"];
            NSString *message = [revokeMsgDic objectForKey:@"message"];
            message = @"撤回了一条消息";
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                NSDictionary * userInfo = [[QIMKit sharedInstance] getUserInfoByUserId:userJid];
                NSString *remarkName = [[QIMKit sharedInstance] getUserMarkupNameWithUserId:userJid];
                if (!remarkName) {
                    remarkName = [userInfo objectForKey:@"Name"];
                }
                NSString *newContent = nil;
                if ([userJid isEqualToString:[[QIMKit sharedInstance] getLastJid]]) {
                    newContent = [NSString stringWithFormat:@"你%@", message];
                } else {
                    newContent = [NSString stringWithFormat:@"\"%@\"%@", remarkName ? remarkName : [[userJid componentsSeparatedByString:@"@"] firstObject], message];
                }
                if (newContent.length > 0) {
                    NSMutableDictionary * tempDic = [NSMutableDictionary dictionaryWithDictionary:_infoDic];
                    [tempDic setQIMSafeObject:newContent forKey:@"Content"];
                    [tempDic setQIMSafeObject:messageId forKey:@"LastMsgId"];
                    [tempDic setQIMSafeObject:@(QIMMessageType_Revoke) forKey:@"MsgType"];
                    _infoDic = tempDic;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.contentLabel setText:newContent];
                    });
                }
            });
        }
    }
}

#pragma mark - kMarkNameUpdate

- (void)markNameUpdate:(NSNotification *)notify{
//    QIMVerboseLog(@"收到通知中心markNameUpdate通知 : %@", notify);
    NSDictionary * info = notify.object;
    if ([info[@"jid"] isEqualToString:self.jid]) {
        
        self.needRefreshName = YES;
        self.showName = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshName) object:nil];
            [self performSelector:@selector(refreshName) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
        return;
    }
}

#pragma mark - kAtALLChange 艾特All
- (void)atallChangeHandle:(NSNotification *)notify {

//    QIMVerboseLog(@"收到通知中心atallChangeHandle通知 : %@", notify);
    if ([notify.object isEqualToString:self.jid] || [notify.object isEqualToString:@"allIds"]) {
        self.firstRefresh = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshUI) object:nil];
            [self performSelector:@selector(refreshUI) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
        });
        return;
    }
}


- (void)updateCell:(NSNotification *)notify {
    
//    QIMVerboseLog(@"收到通知中心updateCell通知 : %@", notify);
    NSString *userId = [notify object];
    if ([userId isEqualToString:self.jid]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.firstRefresh = NO;
           QIMMessageModel *msg = (QIMMessageModel *)[notify.userInfo objectForKey:@"message"];
            [self refreshContentWithMessage:msg.message];
            [self refreshTimeLabelWithTime:msg.messageDate];
        });
        return;
    }
}

#pragma mark - RefreshUI

- (NSString *)refreshContentWithMessage:(NSString *)message {
    NSString *content = nil;
    self.nickName = [[QIMKit sharedInstance] getUserMarkupNameWithUserId:self.msgFrom];
    switch (self.msgType) {
            case QIMMessageType_Text:
            case QIMMessageType_NewAt:
            case QIMMessageType_Shock: {
                if (self.msgDirection == QIMMessageDirection_Received && self.chatType != ChatType_SingleChat && self.chatType != ChatType_System && self.chatType != ChatType_ConsultServer && self.chatType != ChatType_Consult && self.nickName.length > 0) {
                    content = [NSString stringWithFormat:@"%@:%@", self.nickName, message];
                } else {
                    content = message;
                }
            }
            break;
            case QIMMessageType_Revoke: {
                content = [[QIMKit sharedInstance] getMsgShowTextForMessageType:self.msgType];
                if (self.msgDirection == QIMMessageDirection_Received && self.nickName.length > 0) {
                    content = [NSString stringWithFormat:@"\"%@\"%@", self.nickName, content];
                } else {
                    content = [NSString stringWithFormat:@"你%@", content];
                }
            }
            break;
            case PublicNumberMsgType_Notice:
            case PublicNumberMsgType_OrderNotify: {
                NSDictionary *dic = [[QIMJSONSerializer sharedInstance] deserializeObject:message error:nil];
                NSString *title = [dic objectForKey:@"title"];
                if (title.length > 0) {
                    
                    content = title;
                } else {
                    
                    content = @"你收到了一条消息。";
                }
            }
            break;
            case QIMMessageType_Consult: {
                
                NSDictionary *msgDic = [[QIMJSONSerializer sharedInstance] deserializeObject:message error:nil];
                NSString *tagStr = [msgDic objectForKey:@"source"];
                NSString *msgStr = [msgDic objectForKey:@"detail"];
                content = [NSString stringWithFormat:@"%@:%@",tagStr?tagStr:@"",msgStr];
            }
            break;
            case QIMMessageType_CNote: {
                if (message.length > 0) {
                    
                    content = [[QIMKit sharedInstance] getMsgShowTextForMessageType:self.msgType];
                    if (content.length <= 0) {
                        
                        content = @"发送了一条消息。";
                    }
                    if (self.msgDirection == QIMMessageDirection_Received) {
                        content = @"接收到一条消息。";
                    } else {
                        content = @"发送了一条消息。";
                    }
                }
            }
            break;
        default: {
            if (message.length > 0) {
                
                content = [[QIMKit sharedInstance] getMsgShowTextForMessageType:self.msgType];
                if (content.length <= 0) {
                    
                    content = @"发送了一条消息。";
                }
                if (self.msgDirection == QIMMessageDirection_Received && (self.chatType == ChatType_GroupChat || self.chatType == ChatType_CollectionChat) && self.nickName.length > 0) {
                    content = [NSString stringWithFormat:@"%@:%@", self.nickName, content];
                } else {
                    
                }
            }
        }
            break;
    }
    if (self.msgDirection == QIMMessageDirection_Sent) {
        if (self.msgState == QIMMessageSendState_Faild) {
            content = [NSString stringWithFormat:@"[obj type=\"faild\" value=\"\"]%@", content];
        } else if (self.msgState == QIMMessageSendState_Waiting) {
            content = [NSString stringWithFormat:@"[obj type=\"waiting\" value=\"\"]%@", content];
        }
    }
 
    NSDictionary *notSendDic = [[QIMKit sharedInstance] getNotSendTextByJid:self.jid];
    NSString *draftStr = notSendDic[@"text"];
    if (draftStr.length > 0) {
        content = [NSString stringWithFormat:@"[obj type=\"draft\" value=\"\"]%@", draftStr];
    }
    if (content.length <= 0) {
        
        content = @"收到了一条消息。";
    }
    if (self.isReminded == YES && self.notReadCount > 0) {
        content = [NSString stringWithFormat:@"[%ld条]%@", self.notReadCount, content];
    }
    return content;
}

- (void)refreshHeaderImage {
    
//    if (self.needRefreshHeader == NO) {
//        return;
//    }
    if (self.bindId) {
        
        self.chatType = [[self.infoDic objectForKey:@"ChatType"] integerValue];
        [self.headerView qim_setCollectionImageWithJid:self.jid WithChatType:self.chatType];
    } else {
        NSString *headerUrl = [self.infoDic objectForKey:@"HeaderSrc"];
        self.chatType = [[self.infoDic objectForKey:@"ChatType"] integerValue];
        if (headerUrl.length > 0) {
            if (![headerUrl qim_hasPrefixHttpHeader]) {
                headerUrl = [NSString stringWithFormat:@"%@/%@", [[QIMKit sharedInstance] qimNav_InnerFileHttpHost], headerUrl];
            }
            [self.headerView qim_setImageWithURL:[NSURL URLWithString:headerUrl] WithChatType:self.chatType];
        } else {
            self.chatType = [[self.infoDic objectForKey:@"ChatType"] integerValue];
            NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
            [self.headerView qim_setImageWithJid:self.jid WithRealJid:realJid WithChatType:self.chatType];
        }
    }
//    self.needRefreshHeader = NO;
}

- (void)reloadNotReadCount {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshNotReadCount) object:nil];
    [self performSelector:@selector(refreshNotReadCount) withObject:nil afterDelay:DEFAULT_DELAY_TIMES];
}

//刷新消息未读数
- (void)refreshNotReadCount {

    CGFloat timeLabelMaxX = CGRectGetMaxX(self.timeLabel.frame);
    CGFloat contentLabelWidth = timeLabelMaxX - self.nameLabel.left - 35;
    if (self.bindId) {
        self.notReadCount = [[QIMKit sharedInstance] getNotReadCollectionMsgCountByBindId:self.bindId WithUserId:self.jid];
    }
    __block NSString *countStr = nil;
    if (self.notReadCount > 0) {
        if (self.notReadCount > 99) {
            countStr = @"99+";
        }
        else {
            countStr = [NSString stringWithFormat:@"%ld", self.notReadCount];
        }
    } else {
        countStr = @"";
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (countStr.length > 0) {
            
            [self.notReadNumButton hiddenBadgeButton:NO];
            CGFloat width = (countStr.length * 7) + 13;
            [self setUpNotReadNumButtonWithFrame:CGRectMake(self.timeLabel.right - width, 11, width, 16) withBadgeString:countStr];
            if (self.isReminded == YES) {
                self.muteNotReadView.hidden = NO;
                self.muteNotReadView.centerY = self.muteView.centerY;
            } else {
                self.muteNotReadView.hidden = YES;
            }
            [self.contentLabel setFrame:CGRectMake(self.nameLabel.left, self.nameLabel.bottom + 7, contentLabelWidth, 15)];
        } else {
            
            [self.notReadNumButton hiddenBadgeButton:YES];
            [_muteNotReadView setHidden:YES];
            self.contentLabel.width = contentLabelWidth;
            [self.contentLabel setFrame:CGRectMake(self.nameLabel.left, self.nameLabel.bottom + 7, contentLabelWidth, 15)];
        }
        if (self.isReminded == YES && countStr.length > 0) {//接收不提醒
            self.muteView.hidden = NO;
            [self refeshContent];
            self.muteView.frame = CGRectMake([[UIScreen mainScreen] qim_leftWidth] - 40, self.timeLabel.bottom + 15, 15, 15);
            self.muteView.centerY = self.contentLabel.centerY;
        } else if (self.isReminded == YES && countStr.length <= 0) {//接收不提醒
            self.muteView.hidden = NO;
            [self refeshContent];
            self.muteView.frame = CGRectMake([[UIScreen mainScreen] qim_leftWidth] - 25, self.timeLabel.bottom + 15, 15, 15);
            self.muteView.centerY = self.contentLabel.centerY;
        } else {
            self.muteView.hidden = YES;

        }
    });
}

- (void)refreshName {
//    if (!self.needRefreshName) {
//        return;
//    }
    self.needRefreshName = YES;
    if (self.needRefreshName) {
        if (self.showName) {
            if (self.markUpName.length > 0) {
                self.showName = self.markUpName;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.nameLabel setText:self.showName];
            });
        } else {
            self.chatType = [[self.infoDic objectForKey:@"ChatType"] integerValue];
            dispatch_async([[QIMKit sharedInstance] getLoadSessionNameQueue], ^{

                switch (self.chatType) {
                    case ChatType_GroupChat: {
                        if (!self.bindId) {
                            NSDictionary *groupVcard = [[QIMKit sharedInstance] getGroupCardByGroupId:self.jid];
                            if (groupVcard.count > 0) {
                                NSString *groupName = [groupVcard objectForKey:@"Name"];
                                NSInteger groupUpdateTime = [[groupVcard objectForKey:@"LastUpdateTime"] integerValue];
                                if (groupName.length > 0 && groupUpdateTime > 0) {
                                    self.showName = groupName;
                                } else {
                                    [self reloadPlaceHolderName];
                                    [[QIMKit sharedInstance] updateGroupCardByGroupId:self.jid];
                                }
                            } else {
                                [[QIMKit sharedInstance] updateGroupCardByGroupId:self.jid];
                            }
                        } else {
                            NSDictionary *cardDic = [[QIMKit sharedInstance] getCollectionGroupCardByGroupId:self.jid];
                            NSString *collectionGroupName = [cardDic objectForKey:@"Name"];
                            if (collectionGroupName.length > 0) {
                                self.showName = collectionGroupName;
                            } else {
                                [self reloadPlaceHolderName];
                            }
                        }
                    }
                        break;
                    case ChatType_System: {
                        if ([self.jid hasPrefix:@"FriendNotify"]) {
                            self.showName = @"新朋友";
                        } else {
                            
                            if ([self.jid hasPrefix:@"rbt-notice"]) {
                                
                                self.showName = @"公告通知";
                            } else if ([self.jid hasPrefix:@"rbt-qiangdan"]) {
                                self.showName = @"抢单通知";
                            } else if ([self.jid hasPrefix:@"rbt-zhongbao"]) {
                                self.showName = @"抢单";
                            } else {
                                
                                self.showName = @"系统消息";
                            }
                        }
                    }
                        break;
                    case ChatType_CollectionChat: {
                        self.showName = @"我的其他绑定账号";
                    }
                        break;
                    case ChatType_SingleChat: {
                        if (!self.bindId) {
                            //备注
                            NSString *remarkName = [[QIMKit sharedInstance] getUserMarkupNameWithUserId:self.jid];
                            if (remarkName.length > 0) {
                                
                                self.showName = remarkName;
                            } else {
                                
                            }
                        } else {
                            NSDictionary *userInfo = [[QIMKit sharedInstance] getCollectionUserInfoByUserId:self.jid];
                            NSString *userName = [userInfo objectForKey:@"Name"];
                            if (userName.length > 0) {
                                self.showName = userName;
                            } else {
                                [self reloadPlaceHolderName];
                            }
                        }
                    }
                        break;
                    case ChatType_PublicNumber: {
                        self.showName = [NSBundle qim_localizedStringForKey:@"contact_tab_public_number"];
                    }
                        break;
                    case ChatType_ConsultServer: {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.contentView addSubview:self.prefrenceImageView];
                        });
                        NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
                        NSString *realJid = [self.infoDic objectForKey:@"RealJid"];
                        
                        NSDictionary *virtualInfo = [[QIMKit sharedInstance] getUserInfoByUserId:xmppId];
                        NSString *virtualName = [virtualInfo objectForKey:@"Name"];
                        if (virtualName.length <= 0) {
                            virtualName = [xmppId componentsSeparatedByString:@"@"].firstObject;
                        }
                        
                        NSDictionary *userInfo = [[QIMKit sharedInstance] getUserInfoByUserId:realJid];
                        NSString *realName = [userInfo objectForKey:@"Name"];
                        if (realName.length <= 0) {
                            realName = [realJid componentsSeparatedByString:@"@"].firstObject;
                        }
                        self.showName = [NSString stringWithFormat:@"%@-%@",virtualName,realName];
                    }
                        break;
                    case ChatType_Consult: {
                        NSString *xmppId = [self.infoDic objectForKey:@"XmppId"];
                        NSDictionary * virtualInfo = [[QIMKit sharedInstance] getUserInfoByUserId:xmppId];
                        NSString *virtualName = [virtualInfo objectForKey:@"Name"];
                        if (virtualName.length <= 0) {
                            virtualName = [xmppId componentsSeparatedByString:@"@"].firstObject;
                        }
                        self.showName = virtualName;
                    }
                        break;
                    default:
                        break;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.showName.length) {
                        
                        [self.nameLabel setText:self.showName];
                    } else {
                        [self reloadPlaceHolderName];
                        [self.nameLabel setText:self.showName];
                    }
                    self.needRefreshName = NO;
                });
             });
        }
    }
}

- (void)refreshTimeLabelWithTime:(long long)time {
    long long msgDate = 0;
    if (time <= 0) {
        msgDate = [[self.infoDic objectForKey:@"MsgDateTime"] longLongValue];
    } else {
        msgDate = time;
    }
    __block NSString *timeStr = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (msgDate > 0) {
            
            NSDate *senddate = [NSDate qim_dateWithTimeIntervalInMilliSecondSince1970:msgDate];
            
            if (__global_dateformatter == nil) {
                
                __global_dateformatter = [[NSDateFormatter alloc] init];
                [__global_dateformatter setDateFormat:@"MM-dd HH:mm"];
            }
            
            BOOL isToday = [senddate qim_isToday];
            if (isToday) {
                
                NSString *locationString = [__global_dateformatter stringFromDate:senddate];
                locationString = [locationString substringFromIndex:6];
                NSInteger hour = [[locationString substringToIndex:2] integerValue];
                if (hour < 12) {
                    
                    timeStr = [NSString stringWithFormat:@"%@ %@",/*@"上午"*/@"", locationString];
                } else {
                    
                    timeStr = [NSString stringWithFormat:@"%@ %@",/*@"下午"*/@"", locationString];
                }
                
            } else {
                
                [__global_dateformatter setDateFormat:@"MM-dd HH:mm"];
                
                NSString *locationString = [__global_dateformatter stringFromDate:senddate];
                timeStr = [[locationString componentsSeparatedByString:@" "] objectAtIndex:0];
            }
        } else {
            timeStr = @"";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.timeLabel setText:timeStr];
        });
    });
}

- (void)updateUI:(NSNotification *)notify {
    NSArray *array = notify.object;
    if ([array containsObject:self.jid]) {
//        self.needRefreshNotReadCount = NO;
//        self.needRefreshName = YES;
////        self.needRefreshHeader = YES;
//        self.showName = nil;
        [self refreshName];
        [self refreshHeaderImage];
    }
}

- (void)refreshUI {

    [self refreshName];
    [self refreshHeaderImage];
    [self refreshTimeLabelWithTime:self.msgDateTime];
    [self refeshContent];
    self.notReadCount = [[self.infoDic objectForKey:@"UnreadCount"] integerValue];
    [self refreshNotReadCount];
//    self.needRefreshNotReadCount = NO;
    if (self.isStick) {
        _stickView.hidden = NO;
        [self addSubview:self.stickView];
//        [self setBackgroundColor:[UIColor spectralColorLightColor]];
    } else {
        _stickView.hidden = YES;
        [self setBackgroundColor:[UIColor whiteColor]];
    }
}

- (void)refeshContent {
    NSString *message = self.content;
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    [ps setAlignment:NSTextAlignmentLeft];
    NSArray *atMeMessages = @[];
//    [[QIMKit sharedInstance] getHasAtMeByJid:self.jid];
    /*
    NSDictionary *atAllDic = [[QIMKit sharedInstance] getAtAllInfoByJid:self.jid];
    if (atAllDic) {
        
        NSDictionary * titleDic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor qim_colorWithHex:0xff0000 alpha:1], NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
        NSAttributedString *atStr = [[NSAttributedString alloc] initWithString:@"@全体成员:" attributes:titleDic];
        [str appendAttributedString:atStr];
    } else {
        
        NSArray *atNickNames = [[QIMKit sharedInstance] getHasAtMeByJid:self.jid];
        if (atNickNames.count > 0) {
            
            NSDictionary * titleDic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor qim_colorWithHex:0xEB524A alpha:1], NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
//            NSAttributedString *atStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"你被@了%lu次",(unsigned long)atNickNames.count] attributes:titleDic];
            NSAttributedString *atStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[有人@我]"] attributes:titleDic];
            [str appendAttributedString:atStr];
        } else {
            
        }
    }
    */
    if (atMeMessages.count > 0) {
        NSDictionary * titleDic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor qim_colorWithHex:0xEB524A alpha:1], NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
        NSAttributedString *atStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[有人@我]"] attributes:titleDic];
        [str appendAttributedString:atStr];
    }
    
    __block NSString *content = @"";
    if (message.length > 0) {
        dispatch_async([[QIMKit sharedInstance] getLoadSessionContentQueue], ^{
            content = [self refreshContentWithMessage:[message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (content.length > 0) {
                    
                    [str appendAttributedString:[self decodeMsg:content]];
                }
                [self.contentLabel setAttributedText:str];
            });
        });
    } else {
        [self.contentLabel setText:@"收到了一条消息"];
    }
}

- (NSAttributedString *)decodeMsg:(NSString *)msg {
    NSMutableAttributedString *attStr = nil;
    if (msg) {
        
        NSUInteger startLoc = 0;
        int index = 0;
        NSString * lastStr = @"";
        attStr = [[NSMutableAttributedString alloc] init];
        
        NSString *regulaStr = @"\\[obj type=\"(.*?)\" value=\"(.*?)\"( width=(.*?) height=(.*?))?\\]";
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        NSArray *arrayOfAllMatches = [regex matchesInString:msg options:0 range:NSMakeRange(0, [msg length])];
        for (NSTextCheckingResult *match in arrayOfAllMatches) {
            
            NSRange firstRange  =  [match rangeAtIndex:1];
            NSString *type = [msg substringWithRange:firstRange];
            NSRange secondRange =  [match rangeAtIndex:2];
            NSString *value = [msg substringWithRange:secondRange];
            NSUInteger len = match.range.location - startLoc;
            NSString *tStr = [msg substringWithRange:NSMakeRange(startLoc, len)];
            [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:tStr]];
            if ([type isEqualToString:@"image"]) {
                
                [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"[图片]"]];
            } else if ([type isEqualToString:@"emoticon"]) {
                
                [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"[表情]"]];
            } else if ([type isEqualToString:@"url"]){
                
                NSAttributedString *attStr1 = [[NSAttributedString alloc] initWithString:value attributes:@{NSForegroundColorAttributeName:qim_sessionCellContentTextColor}];
                [attStr appendAttributedString:attStr1];
            } else if ([type isEqualToString:@"draft"]) {
                NSAttributedString *attStr1 = [[NSAttributedString alloc] initWithString:@"[草稿]" attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
                [attStr appendAttributedString:attStr1];
            } else if ([type isEqualToString:@"faild"]) {
                
                UIFont *font = [UIFont fontWithName:@"QTalk-QChat" size:15];
                NSMutableDictionary *attributed = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor redColor]}];
                NSAttributedString *attStr1 = [[NSAttributedString alloc] initWithString:@"\U0000f0fc " attributes:attributed];
                [attStr appendAttributedString:attStr1];
            } else if ([type isEqualToString:@"waiting"]) {
                UIFont *font = [UIFont fontWithName:@"QTalk-QChat" size:15];
                NSMutableDictionary *attributed = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                NSAttributedString *attStr1 = [[NSAttributedString alloc] initWithString:@"\U0000e3d9 " attributes:attributed];
                [attStr appendAttributedString:attStr1];
            }
            startLoc = match.range.location + match.range.length;
            if (index == arrayOfAllMatches.count - 1) {
                
                lastStr = [[msg substringFromIndex:(match.range.location + match.range.length)] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                if ([lastStr length] > 0) {
                    
                    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:lastStr]];
                }
            }
            index++;
        }
        if (arrayOfAllMatches.count <= 0) {
            
            [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:msg]];
        }
    }
    return attStr;
}

@end
