    //
//  MMPreferenceViewController.m
//  momo
//
//  Created by jackie on 10-8-5.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMGlobalDefine.h"
#import "MMPreferenceViewController.h"
#import "MMLoginViewController.h"
#import "MMGlobalData.h"
#import "MMThemeMgr.h"
#import "MMPreferenceCell.h"
#import "MMDraftViewController.h"
#import "MMDraftMgr.h"
#import "MMLoginService.h"
#import "MMCommonAPI.h"
#import "MMPreference.h"
#import "MMMomoUserMgr.h"
#import "DefineEnum.h"
#import "MMWebViewController.h"
#import "MMGlobalPara.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "MMAppDelegate.h"

static char MMTableViewRowsInSectionIsLogin[] = {3,3,4,1};

@interface MMPreferenceViewController (MQExpired) 

- (void)onOauthExpired;

@end

@implementation MMPreferenceViewController

@synthesize table_;

- (id) init {
    self = [super init];
	
	if (self != nil) {
			
		NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(onUserLogin:) name:kMMUserLogin object:nil];
        
        [[MMLoginService shareInstance] addObserver:self forKeyPath:@"userName" 
                                            options:NSKeyValueObservingOptionNew 
                                            context:nil];
        [[MMDraftMgr shareInstance] addObserver:self forKeyPath:@"draftArray" 
                                        options:NSKeyValueObservingOptionNew 
                                        context:nil];

        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(onOauthExpired) 
                                                     name:kMMMQOauthExpired 
                                                   object:nil];
	}
	
	return self;
}

- (void)dealloc {
	[table_ release];
    [[MMLoginService shareInstance] removeObserver:self forKeyPath:@"userName"];
    [[MMDraftMgr shareInstance] removeObserver:self forKeyPath:@"draftArray"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidUnload {
	[table_ release];
	table_ = nil;
    [super viewDidUnload];
}

-(void) onUserLogin:(NSNotification*)notification {
	
	[table_ reloadData];
}

- (void)loadView {
    [super loadView];
	self.navigationItem.title = @"更多";
	
    // TableView
    CGFloat height = [[UIScreen mainScreen] applicationFrame].size.height;
	table_ = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStyleGrouped];
	[table_ setDelegate:self];
	[table_ setDataSource:self];
	[table_ setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
	[table_ setShowsVerticalScrollIndicator:NO];
	table_.separatorStyle	= UITableViewCellSeparatorStyleNone;
    table_.backgroundColor = [UIColor clearColor];
	table_.scrollEnabled = YES;
	[self.view addSubview:table_];
}

- (void)viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBarHidden = NO;
}

- (void)updateSyncSwitch {
    NSIndexPath* firstRow = [NSIndexPath indexPathForRow:0 inSection:1];
    [table_ reloadRowsAtIndexPaths:[NSArray arrayWithObject:firstRow] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [MMLoginService shareInstance] && [keyPath isEqualToString:@"userName"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [table_ reloadData];
        });
    } else if (object == [MMDraftMgr shareInstance] && [keyPath isEqualToString:@"draftArray"]){
        //刷新草稿箱数目
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath* firstRow = [NSIndexPath indexPathForRow:1 inSection:0];
            [table_ reloadRowsAtIndexPaths:[NSArray arrayWithObject:firstRow] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return sizeof(MMTableViewRowsInSectionIsLogin);    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return MMTableViewRowsInSectionIsLogin[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	MMPreferenceCell *cell = (MMPreferenceCell *)[ tableView dequeueReusableCellWithIdentifier: @"normalCell"];
	if (cell == nil) {
		cell = [[[MMPreferenceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: @"normalCell"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	switch (indexPath.section) {
		case 0: 
		{
			switch (indexPath.row) {
				case 0:	
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = [NSString stringWithFormat:@" %@ :  设置个人名片",[[MMLoginService shareInstance] getLoginRealName]]; 
					break;
                case 1: {
                    cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					MMDraftMgr* dataSource = [MMDraftMgr shareInstance];
					cell.titleLabel.text = [NSString stringWithFormat:@" 草稿箱  (%d)", dataSource.draftArray.count];
                }
                    break;
				case 2:	
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 修改密码"; 
					break;	
				default:
					break;
			}					
		}			
			break;
		case 1:
		{
			switch (indexPath.row) {
				case 0:{
					cell.cellSwitch.hidden = NO;
                    cell.cellSwitch.enabled = NO;
					cell.cellSwitch.tag = kMMSwitchSync;					
					MMPreference *preference= [MMPreference shareInstance];
					if ([preference syncMode] == kSyncModeRemote) {
						cell.cellSwitch.on = YES;
					}else {
						cell.cellSwitch.on = NO;
					}
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.titleLabel.text = @" 自动同步";
				}
					break;
				case 1: {
                    cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 时光机"; 
                    
				}
					break;	
				case 2: {
                    cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 提醒设置"; 
                }				
					break;
				default:
					break;
			}		
		}
			break;		
		case 2:
		{
			switch (indexPath.row) {
                case 0:
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 喜欢MOMO, 给MOMO评分";
					break;
				case 1:
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 用户反馈";
					break;
				case 2:
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 关于MOMO";
					break;
				case 3:
					cell.cellSwitch.hidden = YES;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.titleLabel.text = @" 帮助";
					break;	
				default:
					break;
			}		
		}
			break;
		case 3:
		{
			switch (indexPath.row) {
				case 0:
				{
					UITableViewCell *tableViewCell = nil;						
					tableViewCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"offCell"];
					
					if (nil == tableViewCell) {
						tableViewCell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"offCell"]autorelease];
						tableViewCell.accessoryType = UITableViewCellAccessoryNone;
						tableViewCell.textLabel.backgroundColor = [UIColor clearColor];
						tableViewCell.textLabel.textAlignment = UITextAlignmentCenter;
						tableViewCell.textLabel.font = [UIFont systemFontOfSize:16.0f];
						
						UIImageView *backgroundView = nil;
						
						backgroundView = [[UIImageView alloc] initWithFrame:tableViewCell.frame];
						backgroundView.image = [MMThemeMgr imageNamed:@"change_call.png"];
						tableViewCell.backgroundView = backgroundView;
						[backgroundView release];
						
						backgroundView = [[UIImageView alloc] initWithFrame:tableViewCell.frame];	
						backgroundView.image = [MMThemeMgr imageNamed:@"change_call_press.png"];
						tableViewCell.selectedBackgroundView = backgroundView;
						[backgroundView release];
						
					}
					
					tableViewCell.textLabel.text = @"退出登录";
					
					return tableViewCell;
				}
					break;
				default:
					break;
			}
		}
			break;
		default:
			break;
	}
	
	return cell;
	
}    

- (void)doLogout {
    MMLoginService *loginService = [MMLoginService shareInstance];
    if (loginService.activeCount > 0) {
        [MMCommonAPI alert:@"正在下载，请稍候再试"];
        return;
    }
    [[MMLoginService shareInstance] doLogout:YES];
    [[MMPreference shareInstance] reset]; //配置项重置
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    MMLoginViewController *controller = [[MMLoginViewController alloc] init];
    controller.hidesBottomBarWhenPushed = YES;
    UINavigationController *navigationCtrl = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
    
    MMAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = navigationCtrl;
    [controller release];
    
    [appDelegate.window makeKeyAndVisible];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES]; 
	
	switch (indexPath.section) {
		case 0:{
			switch (indexPath.row) {
				case 0: {
				
				}
					break;
                case 1: {
                    MMDraftViewController* draftController = [[[MMDraftViewController alloc] init] autorelease];
                    draftController.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:draftController animated:YES];
				}
                    break;
				case 2: {

				}
					break;
			}
		}			
			break;
		case 1:
		{
			switch (indexPath.row) {
				case 0: {
//                    MMSyncPreferenceViewController* viewController = [[[MMSyncPreferenceViewController alloc] init] autorelease];
//                    viewController.hidesBottomBarWhenPushed = YES;
//                    [self.navigationController pushViewController:viewController animated:YES];
				}
					break;
				case 1: {
  
                }
					break;
				case 2: {

                }
					break;
				case 3:
					//do nothing
					break;

				default:
					break;
			}
		}
			break;		
		case 2:
		{
			switch (indexPath.row) {
                case 0:
				{
                NSString* iTunesLink = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=455867457";
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
				}
					break;
				case 1:
				{
                MMMomoUserInfo* friendInfo = [[[MMMomoUserInfo alloc] initWithUserId:FEED_BACK_ID realName:@"小秘" avatarImageUrl:nil] autorelease];
                friendInfo.avatarImageUrl = [[MMMomoUserMgr shareInstance] avatarImageUrlByUserId:FEED_BACK_ID];
                

				}
					break;
				case 2:
				{
					//转到关于momo介绍界面

				}
					break;
				case 3: {
					NSString* helpLink = @"http://m.momo.im/t/user/help";
					MMWebViewController* webViewController = [MMCommonAPI openUrl:helpLink];
                    if (webViewController) {
                        //隐藏toolbar
                        [webViewController addScript:SCRIPT_HIDE_TOOLBAR forURL:@"momo.im"];
                    }
				}
					break;	
				default:
					break;
			}	
		}
			break;
		case 3:
		{
			switch (indexPath.row) {
				case 0: {
                    [UIAlertView alertViewWithTitle:@"提示"  
                                            message:@"确定注销此账号?" 
                                  cancelButtonTitle:@"取消" 
                                  otherButtonTitles:[NSArray arrayWithObject:@"确定"]
                                          onDismiss:^(int buttonIndex){
                                              [self doLogout];
                                          } onCancel:nil];
				}
					break;
				default:
					break;
			}
		}
			break;

		default:
			break;
	}	
}

- (void)onOauthExpired {
    if ([self.navigationController.topViewController isKindOfClass:[MMLoginViewController class]]) {
        return;
    }
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" 
                                                    message:@"当前登陆状态已经失效, 请重新登陆!" 
                                                   delegate:self 
                                          cancelButtonTitle:@"确定" 
                                          otherButtonTitles: nil];
    alert.tag = 111;
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 111) {
        if (alertView.cancelButtonIndex == buttonIndex) {
            if ([MMGlobalPara getTabBarController].selectedViewController != self.navigationController) {
                UINavigationController* currentNavigationController = (UINavigationController*)[MMGlobalPara getTabBarController].selectedViewController;
                [currentNavigationController popToRootViewControllerAnimated:NO];
                
                [MMGlobalPara getTabBarController].selectedViewController = self.navigationController;
            }
            
            if (self.navigationController.topViewController != self) {
                [self.navigationController popToRootViewControllerAnimated:NO];
            }

            [self doLogout];
        }
    }
}

@end
