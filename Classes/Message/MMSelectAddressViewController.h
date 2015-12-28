//
//  MMSelectAddressViewController.h
//  momo
//
//  Created by linsz on 11-9-22.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ASIHTTPRequest.h"

@interface MMAddressInfo : NSObject {
    CLLocationCoordinate2D corrdinate_;
    NSString* addressName_;
    BOOL isCorrect_;
}
@property (nonatomic, copy) NSString* addressName;
@property (nonatomic) BOOL isCorrect;
@property (nonatomic) CLLocationCoordinate2D corrdinate;
@end

@protocol MMSelectAddressViewDelegate <NSObject>
@optional
- (void)didFinishSelectAddress:(MMAddressInfo*) addressInfo; 
- (void)didCancelSelectAddress;
@end

@interface MMSelectAddressViewController : UIViewController <MKMapViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource, ASIHTTPRequestDelegate, MKReverseGeocoderDelegate> {
    UITableView* addressTable_;
   	MKMapView *mapView_;
    UISearchDisplayController *searchCtr_;
                
    MKReverseGeocoder *geocoder_;
    CLLocationCoordinate2D userCoordinate_; //自己坐标
    NSMutableArray* addressArray_;
    NSMutableArray* addressSearchArray_;
                
    ASIHTTPRequest* currentSearchRequest_;
    ASIHTTPRequest* nearSearchRequest_;
    
    id<MMSelectAddressViewDelegate> selectAddressdelegate_;
}

@property (nonatomic, assign) id<MMSelectAddressViewDelegate> selectAddressdelegate; 
@property (nonatomic, retain) NSMutableArray* addressArray;
@property (nonatomic, retain) NSMutableArray* addressSearchArray;
@property (nonatomic, retain)  ASIHTTPRequest* currentSearchRequest;
@property (nonatomic, retain) ASIHTTPRequest* nearSearchRequest;
@property (nonatomic, retain)  MKReverseGeocoder *geocoder;

- (void)startGetNearAddress:(CLLocationCoordinate2D)coordinate;
@end
