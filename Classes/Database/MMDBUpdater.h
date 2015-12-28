//
//  MMDBUpdater.h
//  momo
//
//  Created by jackie on 11-4-7.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMModel.h"

@interface MMUpdateInfo : NSObject
{
	NSString* version;					//需要升级到的版本
	SEL		  updateSelector;			//从前一个版本升级到当前版本需要调用的selector
	BOOL	  replaceDbFile;			//直接覆盖DB文件
}
@property (nonatomic, copy) NSString* version;
@property (nonatomic) SEL updateSelector;
@property (nonatomic) BOOL	 replaceDbFile;

+ (id)updateInfoWithVersionAndSelector:(NSString*)version 
						updateSelector:(SEL)updateSelector 
						 replaceDbFile:(BOOL)replaceDbFile;

@end


@interface MMDBUpdater : MMModel {
	NSArray* updateInfoList;
}
@property (nonatomic, retain) NSArray* updateInfoList;

+ (id)instance;

- (NSString*)dbVersion;

- (MMErrorType)setDBVersion:(NSString*)version;

- (BOOL)needUpdateDB;

- (BOOL)startUpdateDB:(BOOL*)isDBReplaced;

///////////////////////////////////////////////
//直接替换DB文件
- (BOOL)replaceDbFile;


////////////////////////////////////////////////
- (MMErrorType)emptyTable:(NSString*)tableName;

@end
