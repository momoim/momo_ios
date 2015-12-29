//
//  MMSelectCountryViewController.h
//  momo
//
//  Created by  on 11-10-25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DbStruct.h"

@protocol MMSelectCountryDelegate <NSObject>

- (void)didSelectCountry:(MMCountryInfo*)countryInfo;

@end

@interface MMSelectCountryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>
{
    UISearchDisplayController* searchCtr;
    UITableView* tableView_;
    
    NSArray* allCountries_;
    
    NSArray* filterCountryIndexs_;
    NSDictionary* filterCountryDictionary_;
    
    id<MMSelectCountryDelegate> delegate_;
}
@property (nonatomic, retain) NSArray* allCountries;
@property (nonatomic, retain) NSArray* filterCountryIndexs;
@property (nonatomic, retain) NSDictionary* filterCountryDictionary;

@property (nonatomic, assign) id<MMSelectCountryDelegate> delegate;

- (void)loadCountries;

- (void)sortByIndexForFilter:(NSArray *)sortArray;

- (void)actionLeft:(id)sender;

@end
