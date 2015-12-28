//
//  MMSelectAddressViewController.m
//  momo
//
//  Created by linsz on 11-9-22.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMMapViewController.h"
#import "MMSelectAddressViewController.h"
#import "MMMomoUserMgr.h"
#import "MMAvatarMgr.h"
#import "MMLogger.h"
#import "MMThemeMgr.h"
#import "SBJSON.h"
#import "MMGlobalCategory.h"
#import <CoreLocation/CoreLocation.h>
#import "MMCommonAPI.h"

#define PIC_SIZE	32.0f
#define FRIEND_ANNOTATION_TAG 1
#define USER_ANNOTATION_TAG 2

@implementation MMAddressInfo
@synthesize addressName = addressName_;
@synthesize isCorrect = isCorrect_;
@synthesize corrdinate = corrdinate_;
@end

enum REQUEST_HTTP
{
    REQUEST_HTTP_NEARBY,
    REQUEST_HTTP_SEARCH
};

@implementation MMSelectAddressViewController
@synthesize selectAddressdelegate = selectAddressdelegate_;
@synthesize addressArray = addressArray_;
@synthesize addressSearchArray = addressSearchArray_;
@synthesize  currentSearchRequest = currentSearchRequest_;
@synthesize geocoder = geocoder_;
@synthesize nearSearchRequest = nearSearchRequest_;

- (id)init {
	if (self = [super init]) {
        self.addressArray = [NSMutableArray array];
	}
	return self;
}

- (void)loadView {
    [super loadView];
    
    UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
    UIButton *itemButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34,30)] autorelease];
    [itemButton setImage:image forState:UIControlStateNormal];
    [itemButton setImage:image forState:UIControlStateHighlighted];
    [itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
    [itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];	
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
    
    UIView* headerView = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 245)] autorelease];
    UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    searchBar.delegate = self;
	searchBar.placeholder = @"你在哪里？";
    [headerView addSubview:searchBar];
    
    mapView_ = [[[MKMapView alloc] initWithFrame:CGRectMake(0, 44, 320, 245-44)] autorelease];
    mapView_.zoomEnabled       = YES;
    mapView_.showsUserLocation = YES;
	mapView_.delegate          = self;
    mapView_.mapType = MKMapTypeStandard;
    [headerView addSubview:mapView_];
    
    addressTable_ = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)] autorelease];
    addressTable_.tableHeaderView = headerView;
    addressTable_.backgroundColor = [UIColor clearColor];
	addressTable_.scrollsToTop    = YES;
    addressTable_.delegate        = self;
    addressTable_.dataSource      = self;
    [self.view addSubview:addressTable_];
	
    searchCtr_ = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchCtr_.delegate = self;
    searchCtr_.searchResultsDelegate = self;
    searchCtr_.searchResultsDataSource = self;
    
    self.navigationItem.title = @"地理";
    
#if !TARGET_IPHONE_SIMULATOR
    if (![CLLocationManager locationServicesEnabled]) {
        [MMCommonAPI alert:@"定位服务不可用, 请打开\"设置\"->\"定位服务\" 开启定位功能!"];
    }
#endif
}

- (void)actionLeft:(id)sender {
    if (nearSearchRequest_) {
        [nearSearchRequest_ clearDelegatesAndCancel];
    }
    
    if (currentSearchRequest_) {
        [currentSearchRequest_ clearDelegatesAndCancel];
    }
    
    mapView_.showsUserLocation = NO;
    mapView_.delegate = nil;
    mapView_ = nil;
    if ([geocoder_ isQuerying]) {
        [geocoder_ cancel];
    }
    geocoder_.delegate = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc {
    self.addressArray = nil;
    self.addressSearchArray = nil;
    self.currentSearchRequest = nil;
    self.geocoder = nil;
    self.nearSearchRequest = nil;
    self.currentSearchRequest = nil;
    [super dealloc];
}

- (void)viewDidUnload {    
    [super viewDidUnload];
    
    mapView_ = nil;
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)lmapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!userLocation || !CLLocationCoordinate2DIsValid(userLocation.coordinate)) {
        return;
    }
    
    if (userLocation.location.horizontalAccuracy < 0 || userLocation.location.horizontalAccuracy > 10000) {
        return;
    }
    
    BOOL updateLocationInfo = NO;
    if (!CLLocationCoordinate2DIsValid(userCoordinate_)) {
        updateLocationInfo = YES;
    } else {
        CLLocation *loc = [[[CLLocation alloc] initWithLatitude:userCoordinate_.latitude
                                                      longitude:userCoordinate_.longitude] autorelease];
        CLLocation *loc2 = [[[CLLocation alloc] initWithLatitude:userLocation.coordinate.latitude 
                                                       longitude:userLocation.coordinate.longitude] autorelease];
        CLLocationDistance dist = [loc distanceFromLocation:loc2];
        if (dist > 10) {
            updateLocationInfo = YES;
        }
    }
    
    if (updateLocationInfo) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 300, 300);
        [lmapView setRegion:region animated:YES];
        userCoordinate_ = userLocation.coordinate;
        [self startGetNearAddress:userLocation.coordinate];
        
        //获取当前位置信息
        if ([geocoder_ isQuerying]) {
            [geocoder_ cancel];
        }
        
        self.geocoder = [[[MKReverseGeocoder alloc] initWithCoordinate:userCoordinate_] autorelease];
        geocoder_.delegate = self;
        [geocoder_ start];
        
        if (self.addressArray.count > 0) {
            NSMutableDictionary* currentLocationDict = [addressArray_ objectAtIndex:0];
            [currentLocationDict setObject:@"" forKey:@"name"];
            [currentLocationDict setObject:@"当前位置" forKey:@"address"];
            [currentLocationDict setObject:[NSString stringWithFormat:@"%f", userCoordinate_.longitude] forKey:@"x"];
            [currentLocationDict setObject:[NSString stringWithFormat:@"%f", userCoordinate_.latitude] forKey:@"y"];
        } else {
            NSMutableDictionary* currentLocationDict = [NSMutableDictionary dictionary];
            [currentLocationDict setObject:@"" forKey:@"name"];
            [currentLocationDict setObject:@"当前位置" forKey:@"address"];
            [currentLocationDict setObject:[NSString stringWithFormat:@"%f", userCoordinate_.longitude] forKey:@"x"];
            [currentLocationDict setObject:[NSString stringWithFormat:@"%f", userCoordinate_.latitude] forKey:@"y"];
            [addressArray_ addObject:currentLocationDict];
        }
        
        [addressTable_ reloadData];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]){      
        rows = [self.addressSearchArray count]; 
    }else{  
        rows = [self.addressArray count];
    }
    
    return rows;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddressCell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AddressCell"] autorelease];
	}

    NSUInteger row = [indexPath row];
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]){    
        NSDictionary* dataDict = [self.addressSearchArray objectAtIndex:row];
        cell.textLabel.text = [dataDict objectForKey:@"name"];
        cell.detailTextLabel.text = [dataDict objectForKey:@"address"];
    }else{ 
        NSDictionary* dataDict = [addressArray_ objectAtIndex:row];
        cell.textLabel.text = [dataDict objectForKey:@"name"];
        cell.detailTextLabel.text = [dataDict objectForKey:@"address"];    
    }   

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectAddressdelegate && [self.selectAddressdelegate respondsToSelector:@selector(didFinishSelectAddress:)] ) {
        NSUInteger row = [indexPath row];
        
        MMAddressInfo* addressInfo = [[MMAddressInfo alloc] autorelease];
        CLLocationCoordinate2D userLocation;
        if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]){    
            NSDictionary* dataDict = [self.addressSearchArray objectAtIndex:row];
            userLocation.longitude = [[dataDict objectForKey:@"x"] floatValue];
            userLocation.latitude  = [[dataDict objectForKey:@"y"] floatValue];
            addressInfo.corrdinate = userLocation;
            addressInfo.addressName= [dataDict objectForKey:@"name"];
            addressInfo.isCorrect  = YES;
        }else{ 
            NSDictionary* dataDict = [addressArray_ objectAtIndex:row];
            userLocation.longitude = [[dataDict objectForKey:@"x"] floatValue];
            userLocation.latitude = [[dataDict objectForKey:@"y"] floatValue];
            addressInfo.corrdinate = userLocation;
            addressInfo.addressName= [dataDict objectForKey:@"name"];
            addressInfo.isCorrect  = YES;
        }   
        
        [self.selectAddressdelegate didFinishSelectAddress:addressInfo];
        [self actionLeft:nil];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 57;
}

#pragma mark ASIHttpRequestDelegate
- (void)startGetNearAddress:(CLLocationCoordinate2D)coordinate {
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return;
    }
    
    NSString* url = [NSString stringWithFormat:@"http://search1.mapabc.com/sisserver?&config=BELSBXY&resType=json&cityCode=&cenX=%f&cenY=%f&searchName=&range=1000&number=20&batch=1&srctype=POI&searchType=&sr=0&a_k=c2b0f58a6f09cafd1503c06ef08ac7aeb7ddb91ad0ffc4b98ff17266d07343e06ce58bd1def90173",coordinate.longitude, coordinate.latitude];
    MMHttpRequest* request = [MMHttpRequest requestWithURL:[NSURL URLWithString:url]];
    request.delegate = self;
    request.tag = REQUEST_HTTP_NEARBY;
    [request startAsynchronous];
    
    self.nearSearchRequest = request;
}

- (void)startSearchAddress: (NSString*) searchAddress{
    if (!CLLocationCoordinate2DIsValid(userCoordinate_)) {
        return;
    }
    
    if (currentSearchRequest_) {
        [currentSearchRequest_ clearDelegatesAndCancel];
        self.currentSearchRequest = nil;
    }
    
    NSString* strUrl = [NSString stringWithFormat:@"http://search1.mapabc.com/sisserver?&config=BELSBXY&resType=json&cityCode=&cenX=%f&cenY=%f&searchName=%@&range=100000&number=20&batch=1&srctype=POI&searchType=&sr=0&a_k=c2b0f58a6f09cafd1503c06ef08ac7aeb7ddb91ad0ffc4b98ff17266d07343e06ce58bd1def90173",userCoordinate_.longitude, userCoordinate_.latitude, searchAddress];
    
    unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    strUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:encode];
    NSURL *url = [NSURL URLWithString:strUrl];
    MMHttpRequest* request = [MMHttpRequest requestWithURL:url];
    request.delegate = self;
    request.tag = REQUEST_HTTP_SEARCH;
    [request startAsynchronous];
    
    self.currentSearchRequest = request;
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString* responseString = [[[NSString alloc] initWithData:[request responseData] encoding:encode] autorelease];
    if (responseString.length == 0) {
        return;
    }
    

    NSDictionary* retDict = [responseString JSONValue];
    if (!retDict || ![retDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    if (![retDict objectForKey:@"poilist"] || ![[retDict objectForKey:@"poilist"] isKindOfClass:[NSArray class]]) {
        return;
    }
    
    if ([(MMHttpRequest*)request tag] == REQUEST_HTTP_NEARBY) {
        NSArray* tmpArray = [retDict objectForKey:@"poilist"];
        if ([tmpArray isKindOfClass:[NSArray class]] && tmpArray.count > 0) {
            [addressArray_ removeObjectsInRange:NSMakeRange(1, addressArray_.count - 1)];
            
            [self.addressArray addObjectsFromArray:tmpArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                [addressTable_ reloadData];
                self.nearSearchRequest = nil;
            });
        }
    } else{
        self.addressSearchArray =  [NSMutableArray arrayWithArray:[retDict objectForKey:@"poilist"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.searchDisplayController.searchResultsTableView reloadData];
            self.currentSearchRequest = nil;
        });
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
//    [requestArray_ removeObject:request];
//    
//    if ([(MMHttpRequest*)request tag] == 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self afterFiterFriendGPS:friendCoordinate_];
//        });
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self afterFiterUserGPS:userCoordinate_];
//            [self updateDistance];
//        });
//    }   
}

#pragma mark MKReverseGeocoderDelegate
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    NSString* locationDescription = [NSString stringWithFormat:@"%@%@%@%@", PARSE_NULL_STR(placemark.locality),
                                     PARSE_NULL_STR(placemark.subLocality),
                                     PARSE_NULL_STR(placemark.thoroughfare),
                                     PARSE_NULL_STR(placemark.subThoroughfare)];

    NSMutableDictionary* locationAddressDict = [addressArray_ objectAtIndex:0];
    [locationAddressDict setObject:locationDescription forKey:@"name"];
    
    if (![searchCtr_.searchBar isFirstResponder]) {
        [addressTable_ reloadData];
    }
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    [geocoder_ performSelector:@selector(start) withObject:nil afterDelay:0.3f];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate
- (void)actionCancel {
    [searchCtr_.searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)hsearchBar {
    hsearchBar.showsCancelButton = YES;
}

- (void)filterContentForSearchText:(NSString *)searchString {
	if (searchString.length == 0) {
		[self.addressSearchArray removeAllObjects]; 
	} else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(startSearchAddress:) withObject:searchString afterDelay:0.8f];
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
	[self filterContentForSearchText:searchString];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	NSString *searchText = [self.searchDisplayController.searchBar text];
	[self filterContentForSearchText:searchText];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end
