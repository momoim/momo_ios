//
//  MMSelectCountryViewController.m
//  momo
//
//  Created by  on 11-10-25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMSelectCountryViewController.h"
#import "MMCommonAPI.h"
#import "SBJSON.h"
#import "MMPhoneticAbbr.h"

@implementation MMSelectCountryViewController
@synthesize delegate = delegate_;
@synthesize allCountries = allCountries_;
@synthesize filterCountryIndexs = filterCountryIndexs_;
@synthesize filterCountryDictionary = filterCountryDictionary_;

- (id)init {
    self = [super init];
    if (self) {
        [self loadCountries];
    }
    return self;
}

- (void)dealloc {
    [searchCtr release];
    self.allCountries = nil;
    self.filterCountryIndexs = nil;
    self.filterCountryDictionary = nil;
    [super dealloc];
}

- (void)loadCountries {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"countries.json" ofType:nil];
    NSString* jsonString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
                   
    NSArray* countriesArray = [sbjson objectWithString:jsonString error:nil];;
    if (![countriesArray isKindOfClass:[NSArray class]]) {
        return;
    }              
    
    NSMutableArray* array = [NSMutableArray array];
    for (NSDictionary* countryDict in countriesArray) {
        MMCountryInfo* countryInfo = [MMCountryInfo countryInfoFromDictionary:countryDict];
        [array addObject:countryInfo];
    }
    
    self.allCountries = array;
    [self sortByIndexForFilter:allCountries_];
}

- (void)loadView {
    [super loadView];
    [self.navigationController navigationBar].tintColor = [UIColor colorWithRed:0.29 green:0.72 blue:0.87 alpha:1.0];
    self.navigationItem.title = @"选择国家/地区";
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleBordered target:self action:@selector(actionLeft:)] autorelease];
    
    CGFloat height = self.view.frame.size.height - 44;
	tableView_ = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, height) style:UITableViewStyleGrouped] autorelease];
	tableView_.delegate = self;
	tableView_.dataSource = self;
	[self.view addSubview:tableView_];
	tableView_.tableFooterView = [[[UIView alloc] init] autorelease];
	
	UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    searchBar.delegate = self;
    searchBar.placeholder = @"请输入国家或地区名称来搜索";
    tableView_.tableHeaderView = searchBar;
    
    searchCtr = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchCtr.delegate = self;
    searchCtr.searchResultsDelegate = self;
    searchCtr.searchResultsDataSource = self;
}

- (void)actionLeft:(id)sender {
    if ([(NSObject*)delegate_ respondsToSelector:@selector(didSelectCountry:)]) {
		[delegate_ didSelectCountry:nil];
	}
}

- (void)sortByIndexForFilter:(NSArray *)sortArray {
    NSMutableDictionary* filterDictionary = [NSMutableDictionary dictionary];
    NSMutableArray* filterArray = [NSMutableArray array];
    
    for (MMCountryInfo* countryInfo in sortArray) {
        NSString* pinyin = [MMPhoneticAbbr getPinyin:countryInfo.cnCountryName];
        
        NSString* firstLetter = [[pinyin substringToIndex:1] uppercaseString];
        NSMutableArray* array = [filterDictionary objectForKey:firstLetter];
        if (array) {
            [array addObject:countryInfo];
        } else {
            array = [NSMutableArray array];
            [array addObject:countryInfo];
            [filterDictionary setObject:array forKey:firstLetter];
        }
    }
    
    [filterArray setArray:[[filterDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    //sort
    for (NSInteger i = 0; i < [filterDictionary count]; i++) {
		NSString *strkey = [filterArray objectAtIndex:i];
		
		NSArray* array = [filterDictionary objectForKey:strkey];	
		array = [MMCommonAPI sortArrayByAbbr:array key:@"cnCountryName"];
        [filterDictionary setObject:array forKey:strkey];
	}	
    
    self.filterCountryIndexs = filterArray;
    self.filterCountryDictionary = filterDictionary;
}

- (void)filterContentForSearchText:(NSString *)searchString  {
    if (searchString.length == 0) {
        [self sortByIndexForFilter:allCountries_];
    } else {
        NSMutableArray* searchResult = [NSMutableArray array];
        for (MMCountryInfo* countryInfo in allCountries_) {
            //先直接搜索
            NSRange resultRange = [countryInfo.cnCountryName rangeOfString:searchString options:NSCaseInsensitiveSearch];
            if (resultRange.location == NSNotFound) {
                //搜拼音
                if (![MMPhoneticAbbr contactMatch:countryInfo.cnCountryName pattern:searchString isFuzzy:NO isDigital:NO]) {
                    continue;
                }
            }
            
            [searchResult addObject:countryInfo];
        }
        [self sortByIndexForFilter:searchResult];
    }
}

#pragma mark UISearchDisplayDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[self filterContentForSearchText:searchString];
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
	NSString *searchText = [controller.searchBar text];
	[self filterContentForSearchText:searchText];
    return YES;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel* label = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, 320, 30)] autorelease];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.backgroundColor = [UIColor clearColor];
    label.text = [NSString stringWithFormat:@"    %@", [filterCountryIndexs_ objectAtIndex:section]];
    
    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView_ deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString* key = [filterCountryIndexs_ objectAtIndex:indexPath.section];
    NSArray* array = [filterCountryDictionary_ objectForKey:key];
    MMCountryInfo* countryInfo = [array objectAtIndex:indexPath.row];
    if ([(NSObject*)delegate_ respondsToSelector:@selector(didSelectCountry:)]) {
		[delegate_ didSelectCountry:countryInfo];
	}
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return filterCountryIndexs_.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString* key = [filterCountryIndexs_ objectAtIndex:section];
    NSArray* array = [filterCountryDictionary_ objectForKey:key];
    return array.count;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	if (title == UITableViewIndexSearch) 
	{
		[tableView_ scrollRectToVisible:tableView_.tableHeaderView.frame animated:NO];
		return -1;
	}
	return index-1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	NSMutableArray *indices = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
	return [indices arrayByAddingObjectsFromArray:filterCountryIndexs_];
	
	return nil; 
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"countryCell"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"countryCell"] autorelease];
    }
    
    NSString* key = [filterCountryIndexs_ objectAtIndex:indexPath.section];
    NSArray* array = [filterCountryDictionary_ objectForKey:key];
    MMCountryInfo* countryInfo = [array objectAtIndex:indexPath.row];
    cell.textLabel.text = countryInfo.cnCountryName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@", countryInfo.telCode];
    
    return cell;
}

@end
