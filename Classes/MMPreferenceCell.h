//
//  MMPreferenceCell.h
//  momo
//
//  Created by aminby on 2010-10-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kMMSwitchSync = 10,
    kMMSwitchPlaySound,
    kMMSwitchVibratOnNewMessge,
    kMMSwitchAutoPlayAudioMessage,
    kMMSwitchDownBigAvatar,
    kMMSwitchDownBigAvatarOnGPRS,
} MMSwitchTag;

@interface MMPreferenceCell : UITableViewCell {
    UILabel* titleLabel_;
	UISwitch *cellSwitch_;
}
@property (nonatomic, readonly) UILabel* titleLabel;
@property(nonatomic, readonly) UISwitch *cellSwitch;

@end
