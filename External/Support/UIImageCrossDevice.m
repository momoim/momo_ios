//
//  UIImageCrossDevice.m
//  momo
//
//  Created by jackie on 11-6-9.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImageCrossDevice.h"


@implementation UIImageCrossDevice

- (id)initWithContentsOfFile:(NSString *)path {
	if ([UIScreen instancesRespondToSelector:@selector(scale)] && 
		[[UIScreen mainScreen] scale] == 2.0) {
		NSString* path2x = [[path stringByDeletingLastPathComponent]
							stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.%@",
															[[path lastPathComponent] stringByDeletingPathExtension],
															[path pathExtension]]];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path2x]) {
			return [super initWithContentsOfFile:path2x];
		}
	}
	return [super initWithContentsOfFile:path];
}

@end
