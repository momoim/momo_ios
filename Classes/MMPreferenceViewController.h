//
//  MMPreferenceViewController.h
//  momo
//
//  Created by jackie on 10-8-5.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMPreferenceViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    UITableView *table_;
}

@property(nonatomic, retain) UITableView *table_;

@end
