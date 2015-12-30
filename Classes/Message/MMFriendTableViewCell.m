//
//  MMFriendTableViewCell.m
//  momo
//
//  Created by houxh on 15/12/30.
//
//

#import "MMFriendTableViewCell.h"

@interface MMFriendTableViewCell()

@end

@implementation MMFriendTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self =  [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect frame = CGRectMake(54,
                                  0,
                                  self.contentView.frame.size.width - 100,
                                  40);
        
        self.nameLabel = [[UILabel alloc] initWithFrame:frame];
        self.nameLabel.font =  [UIFont systemFontOfSize:14.0f];
        self.nameLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.nameLabel];
        
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.frame = CGRectMake(self.contentView.bounds.size.width - 100, 0, 100, 40);
        [self.button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.button setTitle:@"加为好友" forState:UIControlStateNormal];
        [self.contentView addSubview:self.button];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
