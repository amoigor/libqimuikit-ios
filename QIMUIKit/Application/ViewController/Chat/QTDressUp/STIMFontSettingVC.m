//
//  STIMFontSettingVC.m
//  qunarChatIphone
//
//  Created by chenjie on 16/3/7.
//
//

#define kFontSettingViewHeight      170

#import "STIMFontSettingVC.h"
#import "STIMJSONSerializer.h"
#import "STIMGroupChatCell.h"
//#import "TextCellCaChe.h"
#import "STIMUUIDTools.h"
#import "STIMSliderView.h"
#import "QTalkNewSessionTableViewCell.h"
#import "STIMMessageParser.h"
#import "STIMTextContainer.h"
#import "STIMMessageCellCache.h"
#import "NSBundle+STIMLibrary.h"

@interface STIMFontSettingVC ()<UITableViewDataSource,UITableViewDelegate,STIMSliderViewDelegate>
{
    UITableView             * _chatTableView;
    UITableView             * _sessionTableView;
    UIScrollView            * _mainScrollView;
    
    NSMutableArray          * _chatDatasource;
    NSMutableArray          * _sessionDatasource;
    
    UIPageControl           * _pageControl;
    
    STIMSliderView            * _sliderView;
    BOOL                      _popGesEnabled;
    
    BOOL                      _isValueChanged;
}
@end

@implementation STIMFontSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initUI];
    _isValueChanged = NO;
    
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        _popGesEnabled = self.navigationController.interactivePopGestureRecognizer.enabled;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = _popGesEnabled;
    }
}


- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_isValueChanged) {
        NSDictionary *fontInfo = [[STIMKit sharedInstance] userObjectForKey:kCurrentFontInfo];
        NSString * infoDicStr = [[STIMJSONSerializer sharedInstance] serializeObject:fontInfo];
        [[STIMKit sharedInstance] updateRemoteClientConfigWithType:STIMClientConfigTypeKCurrentFontInfo WithSubKey:[[STIMKit sharedInstance] getLastJid] WithConfigValue:infoDicStr WithDel:NO];
        [[STIMMessageCellCache sharedInstance] clearUp];
    }
}

- (void)initUI{
    [self initNav];
    
    [self initPlaceholder];
    
    [self initMainScrollView];
    [self initChatTableView];
    [self initSessionTableView];
    
    [self initSliderView];
    [self initPageControl];
}

- (void)initNav{
    self.navigationItem.title = [NSBundle stimDB_localizedStringForKey:@"custom_font_size_entrance"];
}

- (void)initMainScrollView{
    if (_mainScrollView == nil) {
        _mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - kFontSettingViewHeight)];
        _mainScrollView.delegate = self;
        _mainScrollView.showsHorizontalScrollIndicator = NO;
        _mainScrollView.showsVerticalScrollIndicator = NO;
        _mainScrollView.pagingEnabled = YES;
        _mainScrollView.contentSize = CGSizeMake(self.view.width * 2, _mainScrollView.height);
        [self.view addSubview:_mainScrollView];
    }
}


- (void)initChatTableView{
    if (_chatTableView == nil) {
        _chatTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - kFontSettingViewHeight) style:UITableViewStylePlain];
        _chatTableView.dataSource = self;
        _chatTableView.delegate = self;
        _chatTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _chatTableView.backgroundColor = [UIColor qtalkChatBgColor];
        [_mainScrollView addSubview:_chatTableView];
    }
}

- (void)initSessionTableView{
    if (_sessionTableView == nil) {
        _sessionTableView = [[UITableView alloc] initWithFrame:CGRectMake(_chatTableView.right, 0, self.view.width, self.view.height - kFontSettingViewHeight) style:UITableViewStylePlain];
        _sessionTableView.dataSource = self;
        _sessionTableView.delegate = self;
        _sessionTableView.backgroundColor = [UIColor whiteColor];
        _sessionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_mainScrollView addSubview:_sessionTableView];
    }
}

- (void)initPlaceholder{
    if (_chatDatasource == nil) {
        _chatDatasource = [NSMutableArray arrayWithCapacity:1];
        STIMMessageModel * msg = [STIMMessageModel new];
        msg.messageId = [STIMUUIDTools UUID];
        msg.messageType = STIMMessageType_Text;
        msg.message = [NSBundle stimDB_localizedStringForKey:@"Preview_text_size"];
        msg.messageDirection = STIMMessageDirection_Sent;
        msg.messageSendState = STIMMessageSendState_Success;
//        msg.nickName = [STIMKit getLastUserName];
        [_chatDatasource addObject:msg];
        
        STIMMessageModel * msg1 = [STIMMessageModel new];
        msg1.messageId = [STIMUUIDTools UUID];
        msg1.messageType = STIMMessageType_Text;
        msg1.message = [NSBundle stimDB_localizedStringForKey:@""];
        msg1.message = [NSBundle stimDB_localizedStringForKey:@"Drag_Change_Text_Size"];
        msg1.messageDirection = STIMMessageDirection_Received;
        msg1.messageSendState = STIMMessageSendState_Success;
//        msg1.nickName = [NSBundle stimDB_localizedStringForKey:@"qtalk_team"];
        [_chatDatasource addObject:msg1];
        
        STIMMessageModel * msg2 = [STIMMessageModel new];
        msg2.messageId = [STIMUUIDTools UUID];
        msg2.messageType = STIMMessageType_Text;
        msg2.message = [NSBundle stimDB_localizedStringForKey:@"Text_Size_FeedBack"];
        msg2.messageDirection = STIMMessageDirection_Received;
        msg2.messageSendState = STIMMessageSendState_Success;
//        msg2.nickName = [NSBundle stimDB_localizedStringForKey:@"qtalk_team"];
        [_chatDatasource addObject:msg2];
        
        STIMMessageModel * msg3 = [STIMMessageModel new];
        msg3.messageId = [STIMUUIDTools UUID];
        msg3.messageType = STIMMessageType_Text;
        msg3.message = [NSBundle stimDB_localizedStringForKey:@"thanks"];
        msg3.messageDirection = STIMMessageDirection_Sent;
        msg3.messageSendState = STIMMessageSendState_Success;
//        msg3.nickName = [STIMKit getLastUserName];
        [_chatDatasource addObject:msg3];
    }
    
    if (_sessionDatasource == nil) {
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            @autoreleasepool {
                
                NSDictionary *friendDic = [[STIMKit sharedInstance] getLastFriendNotify];
                NSInteger friendNotifyCount = [[STIMKit sharedInstance] getFriendNotifyCount];
                NSArray *temp = [[STIMKit sharedInstance] getSessionList];
//                NSMutableDictionary *stickList = [NSMutableDictionary dictionaryWithDictionary:[[STIMKit sharedInstance] stickList]];
//                NSMutableArray *lastStickList = [NSMutableArray array];
                NSMutableArray *tempStickList = [NSMutableArray array];
                NSMutableArray *normalList = [NSMutableArray array];
                BOOL isAddFN = NO;
                long long fnTime = 0;
                NSString *fnDescInfo = nil;
                if (friendDic && friendNotifyCount) {
                    
                    fnTime = [[friendDic objectForKey:@"LastUpdateTime"] longLongValue] * 1000;
                    NSString *name = [friendDic objectForKey:@"Name"];
                    if (name == nil) {
                        
                        name = @"";
                    }
                    int state = [[friendDic objectForKey:@"State"] intValue];
                    NSString *newName = [NSString stringWithFormat:@"%@为好友", name];
                    switch (state) {
                        case 0: {
                            //xxx请求添加为好友
                            fnDescInfo = [name stringByAppendingString:@"请求添加为好友"];
                        }
                            break;
                        case 1: {
                            fnDescInfo = [@"已同意添加" stringByAppendingString:newName];
                        }
                            break;
                        case 2: {
                            fnDescInfo = [@"已拒绝添加" stringByAppendingString:newName];
                        }
                            break;
                        default:
                            break;
                    }
                }
                
                for (NSDictionary *infoDic in temp) {
                    
                    long long sTime = [[infoDic objectForKey:@"MsgDateTime"] longLongValue];
                    long long msgState = [[infoDic objectForKey:@"MsgState"] longLongValue];
                    NSString *xmppId = [infoDic objectForKey:@"XmppId"];
                    NSString *realJid = [infoDic objectForKey:@"RealJid"];
                    NSString *combineJid = (realJid.length > 0) ? [NSString stringWithFormat:@"%@<>%@", xmppId, realJid] : [NSString stringWithFormat:@"%@<>%@", xmppId, xmppId];
                    if ([[STIMKit sharedInstance] isStickWithCombineJid:combineJid]) {
                        [tempStickList addObject:infoDic];
//                        [stickList removeObjectForKey:combineJid];
                    } else {
                        if (friendDic && isAddFN == NO && fnTime > sTime) {
                            [normalList addObject:@{@"XmppId": @"FriendNotify", @"ChatType": @(ChatType_System), @"MsgType": @(1), @"MsgState": @(msgState), @"Content": fnDescInfo, @"MsgDateTime": @(fnTime)}];
                            isAddFN = YES;
                        } else {
                            [normalList addObject:infoDic];
                        }
                    }
                }
                /*
                for (NSDictionary *tempStickDic in [stickList allValues]) {
                    NSString *combineXmppId = [tempStickDic objectForKey:@"ConfigSubKey"];
                    NSString *xmppId = [[combineXmppId componentsSeparatedByString:@"<>"] firstObject];
                    NSString *realJid = [[combineXmppId componentsSeparatedByString:@"<>"] lastObject];
                    NSString *stickValue = [tempStickDic objectForKey:@"ConfigValue"];
                    NSDictionary *stickValueDic = [[STIMJSONSerializer sharedInstance] deserializeObject:stickValue error:nil];
                    
                    NSInteger chatType = [[stickValueDic objectForKey:@"chatType"] integerValue];
                    NSMutableDictionary *customStickDic = [NSMutableDictionary dictionaryWithCapacity:3];
                    [customStickDic setSTIMSafeObject:xmppId forKey:@"XmppId"];
                    [customStickDic setSTIMSafeObject:@(chatType) forKey:@"ChatType"];
                    [customStickDic setSTIMSafeObject:realJid forKey:@"RealJid"];
                    [lastStickList addObject:customStickDic];
                }
                */
                /*
                 for (NSString *tempStickJid in stickList) {
                 if ([tempStickJid containsString:@"conference"]) {
                 [lastStickList addObject:@{@"XmppId": tempStickJid, @"ChatType": @(ChatType_GroupChat)}];
                 } else {
                 if ([tempStickJid containsString:@"SystemMessage"]) {
                 [lastStickList addObject:@{@"XmppId": tempStickJid, @"ChatType": @(ChatType_System)}];
                 } else {
                 [lastStickList addObject:@{@"XmppId": tempStickJid, @"ChatType": @(ChatType_SingleChat)}];
                 }
                 }
                 }
                 */
                if (friendDic && friendNotifyCount && isAddFN == NO) {
                    
                    NSDictionary *dict = @{@"XmppId": @"FriendNotify", @"ChatType": @(ChatType_System), @"MsgType": @(1), @"Content": fnDescInfo, @"MsgDateTime": @(fnTime)};
                    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                    [normalList addObject:mutableDict];
                }
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _sessionDatasource = [NSMutableArray array];
                    [_sessionDatasource addObjectsFromArray:tempStickList];
//                    [_sessionDatasource addObjectsFromArray:lastStickList];
                    [_sessionDatasource addObjectsFromArray:normalList];
                    [_sessionTableView reloadData];
                });
            }
        });
    }
    
}

- (void)initSliderView{
    if (_sliderView == nil) {
        _sliderView = [[STIMSliderView alloc] initWithFrame:CGRectMake(0, self.view.height - kFontSettingViewHeight, self.view.width, kFontSettingViewHeight)];
        _sliderView.delegate = self;
        [self.view addSubview:_sliderView];
    }
}

- (void)initPageControl{
    _pageControl = [[UIPageControl alloc]init];
    [_pageControl setFrame:CGRectMake(0,_sliderView.top + 10,_sliderView.width,20)];
    [_pageControl addTarget:self action:@selector(pageControlHandle:) forControlEvents:UIControlEventValueChanged];
    [self.view insertSubview:_pageControl aboveSubview:_sliderView];
    [_pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
    [_pageControl setCurrentPageIndicatorTintColor:[UIColor stimDB_colorWithHex:0x1687e9 alpha:1.0]];
    _pageControl.numberOfPages = 2;
    _pageControl.currentPage   = 0;
}

#pragma mark - action

- (void)pageControlHandle:(UIPageControl *)sender{
   [_mainScrollView setContentOffset:CGPointMake(sender.currentPage * CGRectGetWidth(self.view.bounds), _mainScrollView.contentOffset.y) animated:YES];
}

#pragma mark  scrollView Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _mainScrollView) {
        int page = (scrollView.contentOffset.x + _mainScrollView.width / 2)/_mainScrollView.width;
        _pageControl.currentPage = page;
    }
    
}

#pragma mark - UITableViewDataSource,UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == _chatTableView) {
        return _chatDatasource.count;
    }else if (tableView == _sessionTableView){
        return _sessionDatasource.count;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _chatTableView) {
       STIMMessageModel * message = [_chatDatasource objectAtIndex:indexPath.row];
        STIMTextContainer *textContaner = [STIMMessageParser textContainerForMessage:message];
        return [textContaner getHeightWithFramesetter:nil width:textContaner.textWidth] + (message.messageDirection == STIMMessageDirection_Sent ? 30 : 60);
    }else if (tableView == _sessionTableView){
        return [QTalkNewSessionTableViewCell getCellHeight];
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _chatTableView) {
       STIMMessageModel * message = [_chatDatasource objectAtIndex:indexPath.row];
        NSString *cellIdentifier = [NSString stringWithFormat:@"Cell text %@",@(message.messageDirection)];
        STIMGroupChatCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[STIMGroupChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [cell setFrameWidth:self.view.frame.size.width];
        }
        [cell setChatType:ChatType_GroupChat];
        [cell setMessage:message];
        [cell refreshUI];
        return cell;
    }else if (tableView == _sessionTableView){
        NSMutableDictionary * dict  =  [_sessionDatasource objectAtIndex:indexPath.row];
        NSString *chatId = [dict objectForKey:@"XmppId"];
        NSString *cellIdentifier = [NSString stringWithFormat:@"Cell ChatId(%@)", chatId];
        QTalkNewSessionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[QTalkNewSessionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.firstRefresh = YES;
        cell.infoDic = dict;
//        [cell refreshUI];
        return cell;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - STIMSliderViewDelegate
-(void)sliderView:(STIMSliderView *)slider didChangeSelectedValue:(NSInteger)index{
    for (STIMMessageModel * msg in _chatDatasource) {
        [[STIMMessageCellCache sharedInstance] removeObjectForKey:msg.messageId];
    }
    [_chatTableView reloadData];
    [_sessionTableView reloadData];
    if (_isValueChanged == NO) {
        _isValueChanged = YES;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCurrentFontUpdate object:nil];
}

@end
