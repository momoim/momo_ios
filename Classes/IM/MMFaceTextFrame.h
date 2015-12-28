//
//  MMFaceTextFrame.h
//  momo
//
//  Created by houxh on 11-9-20.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCTextFrame.h"

@interface MMFace : NSObject {
	NSMutableArray *arrayFace_;
}
+(MMFace*)shareInstance;
- (NSString*)replaceFaceWithHTML:(NSString*)string;
- (NSArray *)getArrayFace;
- (UIImage*)getImageByFace:(NSString*)strFace;
- (NSString*)getHtmlTextByFace:(NSString*)strFace;
@end

@interface MMFaceTextFrame : BCTextFrame


- (id)initWithHTML:(NSString *)html withFaceSize:(NSInteger)faceSize;
@end
