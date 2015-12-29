//
//  MMPreferenceCell.m
//  momo
//
//  Created by aminby on 2010-10-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MMPreferenceCell.h"
#import "MMThemeMgr.h"
#import "MMPreference.h"
#import "UIAlertView+MKBlockAdditions.h"

@implementation MMPreferenceCell

@synthesize cellSwitch = cellSwitch_;
@synthesize titleLabel = titleLabel_;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        titleLabel_ = [[[UILabel alloc] initWithFrame:CGRectMake(10, 0, 240, 44)] autorelease];
        titleLabel_.font = [UIFont fontWithName:@"Helvetica" size:16];
        titleLabel_.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:titleLabel_];
				
		cellSwitch_ = [[[UISwitch alloc] initWithFrame:CGRectMake(195, 7, 95, 30)] autorelease];
		cellSwitch_.backgroundColor = [UIColor clearColor];
		cellSwitch_.hidden = YES;
		[cellSwitch_ addTarget:self action:@selector(actionSwitch:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:cellSwitch_];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super			dealloc];
}

-(void)actionSwitch:(id)sender {
	UISwitch *switchBtn = (UISwitch *)sender;
	switch (switchBtn.tag) {
	//同步
		case kMMSwitchSync: {
			if (switchBtn.on) {
				[MMPreference shareInstance].syncMode = kSyncModeRemote;
			} else {
                [UIAlertView alertViewWithTitle:@"提示" 
                                        message:@"是否关闭自动同步" 
                              cancelButtonTitle:@"确定"
                              otherButtonTitles:[NSArray arrayWithObject:@"取消"] 
                                      onDismiss:^(int buttonIndex){
                                          [switchBtn setOn:YES animated:NO];
                                      } onCancel:^{
                                          [MMPreference shareInstance].syncMode = kSyncModeLocal;
                                      }];
				
			}
		}
			break;	
			
	//新消息提示音
		case kMMSwitchPlaySound: {
			if (switchBtn.on) {
                [MMPreference shareInstance].shouldPlaySound = YES;
			} else {
                [MMPreference shareInstance].shouldPlaySound = NO;
			}
		}
			break;
    //新消息震动
		case kMMSwitchVibratOnNewMessge: {
			if (switchBtn.on) {
                [[MMPreference shareInstance] setVibrateOnNewMessage:YES];
			} else {
                [[MMPreference shareInstance] setVibrateOnNewMessage:NO];
			}
		}
			break;
	//新消息自动播放
		case kMMSwitchAutoPlayAudioMessage: {
			if (switchBtn.on) {
                [[MMPreference shareInstance] setAutoPlayNewAudioMessage:YES];
			} else {
                [[MMPreference shareInstance] setAutoPlayNewAudioMessage:NO];
			}
			
		}
			break;
        case kMMSwitchDownBigAvatar: {
            if (switchBtn.on) {
                [[MMPreference shareInstance] setDownContactAvatar:YES];
			} else {
                [[MMPreference shareInstance] setDownContactAvatar:NO];
			}
        }
            break;
        case kMMSwitchDownBigAvatarOnGPRS: {
            if (switchBtn.on) {
                [[MMPreference shareInstance] setDownContactAvatarOnGPRS:YES];
			} else {
                [[MMPreference shareInstance] setDownContactAvatarOnGPRS:NO];
			}
        }
            break;
		default:
			break;
	}
}

@end
