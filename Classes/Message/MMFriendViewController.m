//
//  FriendViewController.m
//  momo
//
//  Created by houxh on 15/12/30.
//
//

#import "MMFriendViewController.h"
#import "MMFriendTableViewCell.h"
#import "ContactDB.h"
#import "MMLoginService.h"
#import "MBProgressHUD.h"
#import "MMCommonAPI.h"
#import "Token.h"
#import "MMMomoUserMgr.h"
#import "MMFriendDB.h"

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//RGB颜色和不透明度
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

@interface MMFriendViewController ()<UITableViewDelegate, UITableViewDataSource>
@property(nonatomic) UITableView *tableView;
@property(nonatomic) NSMutableArray *potentialFriends;
@property(nonatomic) NSArray *friends;
@end

@implementation MMFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.potentialFriends = [NSMutableArray array];
    self.friends = [NSMutableArray array];
    
  	self.navigationItem.title = @"请求";
    
    //message table
    CGFloat height = self.view.frame.size.height;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollEnabled = YES;
   	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = YES;
    [self.tableView setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.tableView];

    
    ContactDB *db = [ContactDB instance];
    
    __block BOOL accessGranted = NO;
    
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(db.addressBook, ^(bool granted, CFErrorRef error) {
            NSLog(@"grant:%d", granted);
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } else if (status == kABAuthorizationStatusAuthorized){
        accessGranted = YES;
    } else {
        accessGranted = NO;
    }
    if (accessGranted) {
        [db registerAddressCallback];
        [db loadContacts];

        NSArray *mobiles = [db loadAllMobile];
        NSLog(@"mobiles:%@", mobiles);
        
        [[MMLoginService shareInstance] increaseActiveCount];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            int now = (int)time(NULL);

            NSArray *friends = nil;
            int ts = [MMFriendDB instance].updateTimestamp;
            //> 1 hour
            if (now  - ts > 60*60) {
                NSInteger statusCode = 0;
                friends = [[MMLoginService shareInstance] getFreinds:&statusCode];
                if (statusCode != 200) {
                    NSLog(@"get friends fail");
                    return;
                }
                NSLog(@"friends:%@", friends);
                [[MMFriendDB instance] setFriends:friends];
                [MMFriendDB instance].updateTimestamp = now;
            } else {
                friends = [[MMFriendDB instance] getFriends];
            }

            NSInteger statusCode = 0;
            NSArray *potentialFriends = [[MMLoginService shareInstance] getPotentialFriends:mobiles statusCode:&statusCode];
            if (statusCode != 200) {
                NSLog(@"get potential friends fail");
                return;
            }
            NSLog(@"potential friends:%@", potentialFriends);
            
            [[MMLoginService shareInstance] decreaseActiveCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray *array = [NSMutableArray array];
                for (NSDictionary *obj in potentialFriends) {
                    NSNumber *uid = [obj objectForKey:@"id"];
                    
                    NSInteger pos = [friends indexOfObjectPassingTest:^BOOL(NSDictionary *o, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSNumber *n = [o objectForKey:@"id"];
                        if ([n isEqual:uid]) {
                            *stop = YES;
                            return YES;
                        }
                        return NO;
                    }];
                    
                    if (pos == NSNotFound && [uid longLongValue] != [Token instance].uid) {
                        [array addObject:obj];
                    }
                }
                
                self.friends = friends;
                self.potentialFriends = array;
                
                for (NSDictionary *dict in self.friends) {
                    MMMomoUserInfo *user = [[MMMomoUserInfo alloc] init];
                    user.uid = [[dict objectForKey:@"id"] longLongValue];
                    user.realName = [dict objectForKey:@"name"];
                    user.avatarImageUrl = [dict objectForKey:@"avatar"];
                    
                    [[MMMomoUserMgr shareInstance] setUserInfo:user];
                }
                
                for (NSDictionary *dict in self.potentialFriends) {
                    MMMomoUserInfo *user = [[MMMomoUserInfo alloc] init];
                    user.uid = [[dict objectForKey:@"id"] longLongValue];
                    user.realName = [dict objectForKey:@"name"];
                    user.avatarImageUrl = [dict objectForKey:@"avatar"];
                    
                    [[MMMomoUserMgr shareInstance] setUserInfo:user];
                }
                
                [self.tableView reloadData];
            });
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.potentialFriends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMFriendTableViewCell* cell = (MMFriendTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"MMFriendTableViewCell"];
    if (cell == nil) {
        cell = [[MMFriendTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MMFriendTableViewCell"];
        
        [cell.button addTarget:self action:@selector(actionAddFriend:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    NSDictionary *obj = [self.potentialFriends objectAtIndex:indexPath.row];
    cell.textLabel.text = [obj objectForKey:@"name"];
    cell.button.tag = indexPath.row;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)actionAddFriend:(UIButton*)sender {
    NSLog(@"button tag:%zd", sender.tag);
    
    
    UIWindow *foreWindow  = [[UIApplication sharedApplication] keyWindow];
    UIView *backView = [[UIView alloc] initWithFrame:foreWindow.frame];
    [backView setBackgroundColor:RGBACOLOR(134, 136, 137, 0.95f)];
    [foreWindow addSubview:backView];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:backView animated:YES];
    
    NSDictionary *obj = [self.potentialFriends objectAtIndex:sender.tag];
    int64_t uid = [[obj objectForKey:@"id"] longLongValue];
    [[MMLoginService shareInstance] increaseActiveCount];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL r = [[MMLoginService shareInstance] addFriend:uid];
        [[MMLoginService shareInstance] decreaseActiveCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:NO];
            [backView removeFromSuperview];
            
            if (r) {
                NSLog(@"add friend success");
                [self.potentialFriends removeObjectAtIndex:sender.tag];
                [self.tableView reloadData];
            } else {
                NSLog(@"add friend fail");
                [MMCommonAPI alert:@"添加好友失败"];
            }
        });
    });
    
}


@end
