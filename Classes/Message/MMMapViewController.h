//
//  MMMapViewController.h
//  momo
//
//  Created by houxh on 11-9-22.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ASIHTTPRequest.h"

typedef enum {
    RegCenterFrd = 0,
    RegCenterUser, 
    RegCenterBoth
} RegCenterType;

@interface MMMapAnnotation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D coordinate;
	NSString *title;
	NSString *subtitle;
    UIImage *avatar;
    NSInteger tag;
}
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, retain) UIImage *avatar;
@property (nonatomic) NSInteger tag;
- (id) initWithCoordinate: (CLLocationCoordinate2D) aCoordinate;
@end


@interface MMMapViewController : UIViewController <MKMapViewDelegate, MKReverseGeocoderDelegate, ASIHTTPRequestDelegate> {
   	MKMapView *mapView_;
    MKReverseGeocoder *geocoder_;
    
    CLLocationCoordinate2D friendCoordinate_;
    
    NSInteger friendId_;
    Boolean bShowUser_; //是否需要显示自己坐标
    
    UILabel *countryLabel_;
    UILabel *detailLabel_;
    UIButton*btnDirectionTo_;
    UISegmentedControl *mapTypeControl_;
    UIImageView *baseBarImage_;
    
    UIButton *btnSetMapCenter_;
    RegCenterType regCenterType_;
    
    //纠偏过的坐标
    NSMutableArray* requestArray_;
    BOOL shouldGetFriendGPSOffset_;
    BOOL shouldGetUserGPSOffset_;
    
    CLLocation* friendLocation_;
    CLLocation* userLocation_;
    NSString* addressName_;
}
@property (nonatomic, retain) MKReverseGeocoder *geocoder;
@property (nonatomic) CLLocationCoordinate2D friendCoordinate;
@property (nonatomic) BOOL shouldGetFriendGPSOffset;
@property (nonatomic) NSInteger friendId;
@property (nonatomic) Boolean bShowUser;
@property (nonatomic, retain) NSMutableArray* requestArray;
@property (nonatomic, retain) CLLocation* friendLocation;
@property (nonatomic, retain) CLLocation* userLocation;
@property (nonatomic, retain) NSString* addressName;

- (void) showDistance:(id)sender;

- (void)startGetGPSOffset:(CLLocationCoordinate2D)srcCoordinate withTag:(NSInteger)tag;

@end
