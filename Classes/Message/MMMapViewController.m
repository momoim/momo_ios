//
//  MMMapViewController.m
//  momo
//
//  Created by houxh on 11-9-22.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMMapViewController.h"
#import "MMMomoUserMgr.h"
#import "MMAvatarMgr.h"
#import "MMLogger.h"
#import "MMThemeMgr.h"
#import "SBJSON.h"
#import "MMGlobalCategory.h"
#import "MMCommonAPI.h"
#import "MMLoginService.h"
#import "UIActionSheet+MKBlockAdditions.h"

#define PIC_SIZE	32.0f
#define FRIEND_ANNOTATION_TAG 1
#define USER_ANNOTATION_TAG 2

@implementation MMMapAnnotation
@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
@synthesize avatar;
@synthesize tag;

- (id) initWithCoordinate: (CLLocationCoordinate2D) aCoordinate
{
	if (self = [super init]) coordinate = aCoordinate;
	return self;
}

-(void) dealloc
{
	self.title = nil;
	self.subtitle = nil;
    self.avatar = nil;

	[super dealloc];
}
@end


@implementation MMMapViewController
@synthesize friendCoordinate = friendCoordinate_;
@synthesize addressName = addressName_;
@synthesize friendId = friendId_;
@synthesize geocoder = geocoder_;
@synthesize bShowUser = bShowUser_;
@synthesize requestArray = requestArray_;

@synthesize friendLocation = friendLocation_;
@synthesize userLocation = userLocation_;
@synthesize shouldGetFriendGPSOffset = shouldGetFriendGPSOffset_;

- (id)init {
    self = [super init];
    if (self) {
        shouldGetFriendGPSOffset_ = YES;
        shouldGetUserGPSOffset_ = YES;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.requestArray = [NSMutableArray array];
    
    UIImage* image = [MMThemeMgr imageNamed:@"topbar_back.png"];
    UIButton *itemButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34,30)] autorelease];
    [itemButton setImage:image forState:UIControlStateNormal];
    [itemButton setImage:image forState:UIControlStateHighlighted];
    [itemButton setBackgroundImage:[MMThemeMgr imageNamed:@"common_topbar_ic_press.png"] forState:UIControlStateHighlighted];
    [itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];	
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:itemButton] autorelease];
    
    mapView_ = [[[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 320, iPhone5?480-105+88:480-105)] autorelease];
    mapView_.showsUserLocation = YES;
	mapView_.delegate = self;
    
    countryLabel_ = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 24)] autorelease];
    countryLabel_.backgroundColor = [UIColor clearColor];
    countryLabel_.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];    
    countryLabel_.textAlignment = UITextAlignmentCenter;
    countryLabel_.textColor = [UIColor whiteColor];  
    
    detailLabel_  = [[[UILabel alloc] initWithFrame:CGRectMake(0, 22, 180, 20)] autorelease];
    detailLabel_.backgroundColor = [UIColor clearColor];
    detailLabel_.font = [UIFont fontWithName:@"Helvetica" size:13];
    detailLabel_.textAlignment = UITextAlignmentCenter;
    detailLabel_.textColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 44)] autorelease];
    titleLabel.backgroundColor = [UIColor clearColor];
    [titleLabel addSubview:countryLabel_];
    [titleLabel addSubview:detailLabel_];
    self.navigationItem.titleView = titleLabel;
    [self.view addSubview:mapView_];
    
    
    //下部底图
    baseBarImage_ = [[[UIImageView alloc]initWithFrame:CGRectMake(0, iPhone5?371+88:371, 320, 45)] autorelease];
	baseBarImage_.image =  [MMThemeMgr imageNamed:@"chat_basebar_bg.png"];
	baseBarImage_.userInteractionEnabled = YES;
	[self.view addSubview:baseBarImage_];
	
	
	btnDirectionTo_ = [[[UIButton alloc]initWithFrame:CGRectMake(6, 0, 45, 45)] autorelease];
	[btnDirectionTo_ setImage: [MMThemeMgr imageNamed:@"map_to.png"] forState:UIControlStateNormal];
	[btnDirectionTo_ addTarget:self action:@selector(actionDirectionTo:) forControlEvents:UIControlEventTouchUpInside];	
	btnDirectionTo_.backgroundColor = [UIColor clearColor];
	[baseBarImage_ addSubview:btnDirectionTo_];
    
    //map样式
    mapTypeControl_=[[[UISegmentedControl alloc] initWithFrame:CGRectMake(67, 8, 188, 31)] autorelease];
    [mapTypeControl_ insertSegmentWithTitle:@"标准" atIndex:0 animated:YES];
    [mapTypeControl_ insertSegmentWithTitle:@"卫星" atIndex:1 animated:YES];
    [mapTypeControl_ insertSegmentWithTitle:@"混合" atIndex:2 animated:YES];
    mapTypeControl_.segmentedControlStyle = UISegmentedControlStyleBar;
    mapTypeControl_.momentary = NO;
    mapTypeControl_.multipleTouchEnabled=NO;
    mapTypeControl_.backgroundColor = [UIColor clearColor];
    mapTypeControl_.tintColor = [UIColor colorWithRed:0.29 green:0.72 blue:0.87 alpha:1.0];
    mapTypeControl_.selectedSegmentIndex = 0;
    [mapTypeControl_ addTarget:self action:@selector(selectMapType:) forControlEvents:UIControlEventValueChanged];
    [baseBarImage_ addSubview:mapTypeControl_];
    
    btnSetMapCenter_ = [[[UIButton alloc]initWithFrame:CGRectMake(260, 0, 45, 45)] autorelease];
	[btnSetMapCenter_ setImage: [MMThemeMgr imageNamed:@"map_three.png"] forState:UIControlStateNormal];
	[btnSetMapCenter_ addTarget:self action:@selector(actionSetMapCenter:) forControlEvents:UIControlEventTouchUpInside];	
	btnSetMapCenter_.backgroundColor = [UIColor clearColor];
	[baseBarImage_ addSubview:btnSetMapCenter_];
    
    btnDirectionTo_.hidden = YES;
    btnSetMapCenter_.hidden = YES;
}

- (void)actionLeft:(id)sender {
    for (ASIHTTPRequest* request in requestArray_) {
        [request clearDelegatesAndCancel];
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
    self.requestArray = nil;
    self.geocoder = nil;
    self.friendLocation = nil;
    self.userLocation = nil;
    self.addressName = nil;
    
    [super dealloc];
}

- (MMMapAnnotation*)annotationWithTag:(NSInteger)tag {
    for (MMMapAnnotation* annotation in mapView_.annotations) {
        if ([annotation isKindOfClass:[MMMapAnnotation class]] && annotation.tag == tag) {
            return annotation;
        }
    }
    return nil;
}

- (void)checkDirectionBtn {
    if (friendLocation_ && userLocation_) {
        btnDirectionTo_.hidden = NO;
        btnSetMapCenter_.hidden = NO;
    }
}

- (void)afterFiterFriendGPS:(CLLocationCoordinate2D)coorrdinate {
    self.friendLocation = [[[CLLocation alloc] initWithLatitude:coorrdinate.latitude 
                                                      longitude:coorrdinate.longitude] autorelease];
    mapView_.region = MKCoordinateRegionMakeWithDistance(coorrdinate, 500, 500);
	mapView_.zoomEnabled = YES;
    
    [mapView_ removeAnnotations:mapView_.annotations];
    
    MMMapAnnotation* annotation = [[[MMMapAnnotation alloc] initWithCoordinate:friendLocation_.coordinate] autorelease];
    if (friendId_ > 0) {
        annotation.title = [[MMMomoUserMgr shareInstance] realNameByUserId:friendId_];
    }
    annotation.tag = FRIEND_ANNOTATION_TAG;
    
    [mapView_ addAnnotation:annotation];
    
    self.geocoder = [[[MKReverseGeocoder alloc] initWithCoordinate:friendLocation_.coordinate] autorelease];
    geocoder_.delegate = self;
    [geocoder_ start];
    
    [self checkDirectionBtn];
}

- (void)afterFiterUserGPS:(CLLocationCoordinate2D)coorrdinate {
    self.userLocation = [[[CLLocation alloc] initWithLatitude:coorrdinate.latitude 
                                                      longitude:coorrdinate.longitude] autorelease];
    btnDirectionTo_.hidden = NO;
    btnSetMapCenter_.hidden = NO;
    
    if (mapView_.annotations.count == 1) {
        MMMapAnnotation* annotation = [[[MMMapAnnotation alloc] initWithCoordinate:userLocation_.coordinate] autorelease];
        annotation.title = @"当前位置";
        annotation.tag = USER_ANNOTATION_TAG;
        [mapView_ addAnnotation:annotation];
    } else {
        MMMapAnnotation* annotation = [self annotationWithTag:USER_ANNOTATION_TAG];
        if (annotation) {
            [UIView animateWithDuration:0.5f 
                                  delay:0 
                                options:UIViewAnimationOptionCurveEaseInOut 
                             animations:^{
                                 [annotation setCoordinate:userLocation_.coordinate];
                             }completion:nil];
        }
    }
}

- (void) viewDidLoad	
{
    if (!CLLocationCoordinate2DIsValid(friendCoordinate_)) {
        return;
    }
    
//    mapView_.region = MKCoordinateRegionMakeWithDistance(friendCoordinate_, 500, 500);
	mapView_.zoomEnabled = YES;
    
    if (shouldGetFriendGPSOffset_) {
        [self startGetGPSOffset:friendCoordinate_ withTag:0];
    } else {
        [self afterFiterFriendGPS:friendCoordinate_];
    }
}

- (void)viewDidUnload {    
    [super viewDidUnload];
    
    mapView_ = nil;
}

-(void)selectMapType:(int)sender{
    UISegmentedControl *myUISegmentedControl=(UISegmentedControl *)sender;
    switch (myUISegmentedControl.selectedSegmentIndex) {
        case 0:
            mapView_.mapType=MKMapTypeStandard;
            break;
        case 1:
            mapView_.mapType=MKMapTypeSatellite;
            break;
        case 2:
            mapView_.mapType=MKMapTypeHybrid;
            break;
        default:
            break;
    }
}

-(void)actionSetMapCenter:(int)sender{
    CLLocationCoordinate2D locationCenter;
    MKCoordinateSpan locationSpan;  
    MKCoordinateRegion region;
    
    if ( (!CLLocationCoordinate2DIsValid(friendLocation_.coordinate) ) 
        || (!CLLocationCoordinate2DIsValid(userLocation_.coordinate)) ) {
        return;
    }
    
    if (regCenterType_ == RegCenterBoth)
        regCenterType_ = RegCenterFrd;
    else
        regCenterType_ ++;
    
    switch (regCenterType_) {
        case RegCenterFrd:
            region = MKCoordinateRegionMakeWithDistance(friendLocation_.coordinate, 500, 500);
            break;
        case RegCenterUser:
            region = MKCoordinateRegionMakeWithDistance(userLocation_.coordinate, 500, 500);
            break;
        case RegCenterBoth:
            locationCenter.latitude = (friendLocation_.coordinate.latitude + userLocation_.coordinate.latitude) / 2;
            locationCenter.longitude= (friendLocation_.coordinate.longitude + userLocation_.coordinate.longitude) / 2;
            locationSpan.latitudeDelta = MIN(180, fabs(friendLocation_.coordinate.latitude - userLocation_.coordinate.latitude) * 2);
            locationSpan.longitudeDelta = MIN(360, fabs(friendLocation_.coordinate.longitude - userLocation_.coordinate.longitude) * 2);
            
            region = MKCoordinateRegionMake(locationCenter, locationSpan);
            break;
        default:
            break;
    }
    
    [mapView_ setRegion:region animated:YES];
    
    if (regCenterType_ == RegCenterUser) {
        [mapView_ selectAnnotation:mapView_.userLocation animated:YES];
    }
    else{
        MMMapAnnotation *annotation = [self annotationWithTag:FRIEND_ANNOTATION_TAG];
        [mapView_ selectAnnotation:annotation animated:YES];
    }
}

//导航到对应位置
- (void)actionDirectionTo:(int)sender{
    NSMutableArray* otherButtons = [NSMutableArray arrayWithObjects:@"高德地图", @"Google Map", @"查看K码", nil];
    
    [UIActionSheet actionSheetWithTitle:@"选择导航方式"
                                message:@""
                 destructiveButtonTitle:nil 
                                buttons:otherButtons
                             showInView:self.view
                              onDismiss:^(int buttonIndex)
     {
     switch (buttonIndex) { 
         case 0: {
             // 构建高德客户端协议的 URL
             NSString *strUrl = nil;
             if (friendLocation_) {
                 strUrl = [NSString stringWithFormat:@"iosamap://navi?sourceApplication=移动momo&backScheme=momo&lat=%f&lon=%f&dev=0&style=2", friendLocation_.coordinate.latitude, friendLocation_.coordinate.longitude];
                 
             } else {
                 strUrl = [NSString stringWithFormat:@"iosamap://navi?sourceApplication=移动momo&backScheme=momo&lat=%f&lon=%f&dev=1&style=2", friendCoordinate_.latitude, friendCoordinate_.longitude];
             }

             NSURL *url = [NSURL URLWithString:[strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
             
             // 判断当前系统是否有安装高德客户端
             if ([[UIApplication sharedApplication] canOpenURL:url]) {
                 // 如果已经安装高德客户端，就使用客户端打开链接
                 [[UIApplication sharedApplication] openURL:url];
             } else {
                 // 否则跳转到Appstore下载页面
                 url = [NSURL URLWithString: @"http://itunes.apple.com/cn/app//id461703208?mt=8"];
                 [[UIApplication sharedApplication] openURL:url];
             }
             break;
         }
         case 1:{
             NSString* strUrl = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f",
                                 friendLocation_.coordinate.latitude, friendLocation_.coordinate.longitude, 
                                 userLocation_.coordinate.latitude, userLocation_.coordinate.longitude];
             
             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strUrl]];
             NSLog(@"GOOGLE TO");
             break;
         }
         case 2: {
             NSString* offsetKCode = [MMCommonAPI computeKCode:friendLocation_.coordinate.longitude 
                                                      latitude:friendLocation_.coordinate.latitude];
             [MMCommonAPI alert:[NSString stringWithFormat:@"K码: %@", offsetKCode]];
         }
     }
     } onCancel:nil];
}

- (void)showDistance:(id)sender {
    [mapView_ selectAnnotation:[self annotationWithTag:FRIEND_ANNOTATION_TAG] animated:YES];
}

- (void)updateDistance {
    MMMapAnnotation* annotation = [self annotationWithTag:FRIEND_ANNOTATION_TAG];
    if (annotation) {
        annotation.title = [[MMMomoUserMgr shareInstance] realNameByUserId:friendId_];
        
        
        CLLocation *loc = [[[CLLocation alloc] initWithLatitude:friendLocation_.coordinate.latitude
                                                      longitude:friendLocation_.coordinate.longitude] autorelease];
        CLLocation *loc2 = [[[CLLocation alloc] initWithLatitude:userLocation_.coordinate.latitude 
                                                       longitude:userLocation_.coordinate.longitude] autorelease];
        CLLocationDistance dist = [loc distanceFromLocation:loc2];
        int distance = dist;
        annotation.subtitle = [NSString stringWithFormat:@"距离你%d米", distance];
    }
}

#pragma MKMapViewDelegate
- (void)mapView:(MKMapView *)lmapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    self.userLocation = userLocation.location;
    [self updateDistance];
    
    [self checkDirectionBtn];
}

- (void)mapView:(MKMapView *)lmapView didAddAnnotationViews:(NSArray *)views
{
    for (MKPinAnnotationView *mkaview in views) {
        mkaview.canShowCallout=YES;  
    }
    
    [mapView_ selectAnnotation:[self annotationWithTag:FRIEND_ANNOTATION_TAG] animated:YES];
}

#pragma mark MKReverseGeocoderDelegate
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    NSString* locationDescription = [NSString stringWithFormat:@"%@%@%@%@", PARSE_NULL_STR(placemark.locality),
                                     PARSE_NULL_STR(placemark.subLocality),
                                     PARSE_NULL_STR(placemark.thoroughfare),
                                     PARSE_NULL_STR(placemark.subThoroughfare)];
    countryLabel_.text = PARSE_NULL_STR(placemark.country);
    detailLabel_.text = locationDescription;
    
    [countryLabel_ setNeedsDisplay];
    [detailLabel_ setNeedsDisplay];
    NSLog(@"countryLabel_.text=%@,detailLabel_.text=%@",PARSE_NULL_STR(placemark.country),locationDescription);
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    [geocoder_ performSelector:@selector(start) withObject:nil afterDelay:0.3f];
}

#pragma mark ASIHttpRequestDelegate
- (void)startGetGPSOffset:(CLLocationCoordinate2D)srcCoordinate withTag:(NSInteger)tag {
    NSString* url = [NSString stringWithFormat:@"http://search1.mapabc.com/sisserver?&config=BSPS&resType=json&gps=1&glong=%f&glat=%f&a_k=c2b0f58a6f09cafd1503c06ef08ac7aeb7ddb91ad0ffc4b98ff17266d07343e06ce58bd1def90173", srcCoordinate.longitude, srcCoordinate.latitude];
    MMHttpRequest* request = [MMHttpRequest requestWithURL:[NSURL URLWithString:url]];
    request.delegate = self;
    request.tag = tag;
    [requestArray_ addObject:request];
    
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    [requestArray_ removeObject:request];
    BOOL success = NO;
    
    do {
        unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString* responseString = [[[NSString alloc] initWithData:[request responseData] encoding:encode] autorelease];
        if (responseString.length == 0) {
            success = NO;
            break;
        }
        
        SBJSON* sbjson = [[[SBJSON alloc] init] autorelease];
        NSDictionary* retDict = [sbjson objectWithString:responseString error:nil];
        if (!retDict || ![retDict isKindOfClass:[NSDictionary class]]) {
            success = NO;
            break;
        }
        
        if (![retDict objectForKey:@"list"] || ![[retDict objectForKey:@"list"] isKindOfClass:[NSArray class]]) {
            success = NO;
            break;
        }
        NSArray* list = [retDict objectForKey:@"list"];
        if (list.count == 0) {
            success = NO;
            break;
        }
        NSDictionary* dataDict = [list objectAtIndex:0];
        if (!dataDict || ![dataDict isKindOfClass:[NSDictionary class]] || ![dataDict objectForKey:@"cenx"] || ![dataDict objectForKey:@"ceny"]) {
            success = NO;
            break;
        }
        
        success = YES;
        double latitude = [[dataDict objectForKey:@"ceny"] doubleValue];
        double longitude = [[dataDict objectForKey:@"cenx"] doubleValue];
        
        if (latitude == 0 && longitude == 0) {
            if ([(MMHttpRequest*)request tag] == 0) {
                shouldGetFriendGPSOffset_ = NO;
            } else {
                shouldGetUserGPSOffset_ = NO;
            }
        }
        
        if ([(MMHttpRequest*)request tag] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (shouldGetFriendGPSOffset_) {
                    [self afterFiterFriendGPS:CLLocationCoordinate2DMake(latitude, longitude)];
                } else {
                    [self afterFiterFriendGPS:friendCoordinate_];
                }

            });
        }
    } while (0);
    
    if (!success && [(MMHttpRequest*)request tag] == 0 && shouldGetFriendGPSOffset_) {
        [self startGetGPSOffset:friendCoordinate_ withTag:0];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    [requestArray_ removeObject:request];

    if ([(MMHttpRequest*)request tag] == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self afterFiterFriendGPS:friendCoordinate_];
        });
    } 
}

@end
