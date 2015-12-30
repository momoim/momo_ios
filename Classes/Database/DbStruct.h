//
//  DbStruch.h
//  Momo
//
//  Created by zdh on 5/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>
#import <MapKit/MapKit.h>
#import "DefineEnum.h"


//评论消息结构
@interface MMCommentInfo : NSObject {
	NSUInteger ownerId;
	NSString*	commentId;
	NSString*	statusId;
	NSUInteger	uid;
	NSString	*text;
	uint64_t	createDate;
	NSString	*sourceName;
	NSString	*realName;
	NSString	*avatarImageUrl;
    NSString    *srcText;
    BOOL        ignoreTimeLine;
	
	//for upload use
	UploadStatus uploadStatus;
	NSUInteger	draftId;
}
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic, copy) NSString* commentId;
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) uint64_t createDate;
@property (nonatomic, copy) NSString	*sourceName;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;
@property (nonatomic, copy) NSString *srcText;
@property (nonatomic) BOOL ignoreTimeLine;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic) NSUInteger draftId;

- (NSString*)plainText;

@end

//动态消息结构
@interface MMMessageInfo : NSObject {
	NSString* statusId;
	NSUInteger ownerId;
	NSUInteger	uid;
	NSString	*text;
	NSUInteger	createDate;
	uint64_t	modifiedDate;
	BOOL		liked;
	NSUInteger	likeCount;
	NSString	*likeList;
	BOOL		storaged;
	NSString	*sourceName;
	NSUInteger	commentCount;
	NSString*	recentCommentId;
	NSUInteger	groupType;
	NSUInteger	groupId;
	NSString	*groupName;
	NSString	*summary;
	NSArray		*attachImageURLs;
	NSArray		*voteOptions;
	BOOL		ignoreDateLine;
	NSString	*realName;
	NSString	*avatarImageUrl;
	
	MMMessageType	typeId;	//动态类型:活动.日志等
	BOOL		allowRetweet;
	BOOL		allowComment;
	BOOL		allowPraise;
	BOOL		allowDel;
	BOOL		allowHide;
	NSString	*retweetStatusId;
	uint64_t	applicationId;
	NSString	*applicationTitle;
	NSString	*applicationUrl;
	
	//后面加的类型都存储到json中
	NSArray		*accessoryArray;	//存储 MMMessageAccessoryInfo 数组
	
	BOOL		syncToWeibo;	//是否同步到微薄
    NSArray     *syncToWeiboInfos; //同步到微薄信息数组, 包含微薄名称和是否同步成功
    
    //地理信息
    double      longitude;
    double      latitude;
    NSString*   address;
    BOOL        isCorrect;
    
    //长文本
    BOOL        isLongText;
    NSString*   longTextUrl;
    NSString    *longText;
	////////////////////////////////////
    //for cache
	MMCommentInfo *recentComment;
	
    //for upload use
	UploadStatus uploadStatus;
    
    CGPoint     contentOffset;
}
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSUInteger createDate;
@property (nonatomic) uint64_t modifiedDate;
@property (nonatomic) BOOL liked;
@property (nonatomic) NSUInteger likeCount;
@property (nonatomic, copy) NSString *likeList;
@property (nonatomic) BOOL storaged;
@property (nonatomic, copy) NSString	*sourceName;
@property (nonatomic) NSUInteger commentCount;
@property (nonatomic, copy) NSString*  recentCommentId;
@property (nonatomic) NSUInteger groupType;
@property (nonatomic) NSUInteger groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, retain) NSArray *attachImageURLs;
@property (nonatomic, retain) NSArray *voteOptions;
@property (nonatomic) BOOL		ignoreDateLine;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;
@property (nonatomic) MMMessageType typeId;
@property (nonatomic) BOOL	allowRetweet;
@property (nonatomic) BOOL	allowComment;
@property (nonatomic) BOOL	allowPraise;
@property (nonatomic) BOOL	allowDel;
@property (nonatomic) BOOL	allowHide;
@property (nonatomic, copy) NSString *retweetStatusId;
@property (nonatomic) uint64_t applicationId;
@property (nonatomic, copy) NSString *applicationTitle;
@property (nonatomic, copy) NSString *applicationUrl;
@property (nonatomic, retain) NSArray *accessoryArray;
@property (nonatomic) BOOL	syncToSinaWeibo;
@property (nonatomic) BOOL	syncToSinaWeiboSuccess;

@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) BOOL isCorrect;
@property (nonatomic, copy) NSString*  address;
@property (nonatomic) BOOL  isLongText;
@property (nonatomic, copy) NSString*  longTextUrl;
@property (nonatomic, copy) NSString*  longText;
@property (nonatomic) CGPoint contentOffset;

//not in db
@property (nonatomic, retain) MMCommentInfo *recentComment;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic) NSUInteger draftId;

- (MMMessageType)messageTypeFromString:(NSString*)type;

- (NSString*)plainText;

@end



@interface MMMomoUserInfo : NSObject <NSCopying>
{
	NSUInteger uid;
	NSString* realName;
	NSString* avatarImageUrl;
    
    NSUInteger contactId;	
	NSString *registerNumber;
}
@property (nonatomic) NSUInteger uid;
@property (nonatomic, copy) NSString* realName;
@property (nonatomic, copy) NSString* avatarImageUrl;

@property (nonatomic) NSUInteger contactId;
@property (nonatomic, copy) NSString *registerNumber;

@property (nonatomic) BOOL isSelected;  //用于选择联系人页面的选择状态
@property (nonatomic, copy) NSString *namePhonetic;

- (id)initWithUserId:(NSUInteger)userId 
			realName:(NSString*)name
	  avatarImageUrl:(NSString*)url;

- (id)initWithDictionary:(NSDictionary*)dic;

@end

//about me消息结构
@interface MMAboutMeInfo : NSObject {
	NSUInteger ownerId;
	NSString	*aboutMeId;
	NSString	*textReply;
	NSString	*text;
	NSUInteger	uid;
	NSString	*realName;
	NSString	*avatarImageUrl;
	
	NSString	*statusId;
	NSUInteger  statusUid;
	
	NSUInteger	groupType;
	NSUInteger	groupId;
	NSString	*groupName;
	BOOL		reply;
	NSArray		*commentIds;
	NSUInteger	createdAt;
	BOOL		isNew;
}
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic, copy) NSString	*aboutMeId;
@property (nonatomic, copy) NSString *textReply;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSUInteger	uid;
@property (nonatomic, copy) NSString *realName;
@property (nonatomic, copy) NSString *avatarImageUrl;

@property (nonatomic, copy) NSString *statusId;
@property (nonatomic) NSUInteger	statusUid;
@property (nonatomic) NSUInteger	groupType;
@property (nonatomic) NSUInteger	groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic) BOOL		reply;
@property (nonatomic, retain) NSArray		*commentIds;
@property (nonatomic) NSUInteger	createdAt;
@property (nonatomic) BOOL		isNew;
@end

@interface MMDraftInfo : NSObject {
	NSUInteger	ownerId;
	NSUInteger draftId;
	NSString* text;
	DraftType draftType;
	NSUInteger	createDate;
	
    //message use
	NSArray* attachImagePaths;	//已上传或未上传的图片路径
	NSUInteger groupId;
	MMAppType  appType;		//应用类型, 群组或活动
	NSString*  groupName;
	BOOL	   syncToWeibo;	//同步到微薄
	
    //retweet use
	NSString* retweetStatusId;	//转发的动态ID
	
    //comment use
	NSString*	replyStatusId;
	NSString*	replyCommentId;
    
    NSMutableDictionary* extendInfo; //
	
	/////////////////////////////////////
	//not in db
	NSArray* attachImages;
	
	//for upload use
	UploadStatus uploadStatus;
    NSString*    uploadErrorString;
}
@property (nonatomic) NSUInteger createDate;
@property (nonatomic) NSUInteger ownerId;
@property (nonatomic) NSUInteger	draftId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) DraftType	draftType;
@property (nonatomic, retain) NSArray* attachImagePaths;
@property (nonatomic) NSUInteger	groupId;
@property (nonatomic) MMAppType  appType;
@property (nonatomic) BOOL syncToWeibo;
@property (nonatomic, copy) NSString*  groupName;
@property (nonatomic, copy) NSString*	retweetStatusId;
@property (nonatomic, copy) NSString*	replyStatusId;
@property (nonatomic, copy) NSString* 	replyCommentId;
@property (nonatomic, retain) NSMutableDictionary* extendInfo;

@property (nonatomic, retain) NSArray* attachImages;

//for upload use
@property (nonatomic) UploadStatus uploadStatus;
@property (nonatomic, copy) NSString*   uploadErrorString;

- (NSString*)textWithoutUid;  //将@用户后面的ID去除
- (NSString*)textToUpload;     //将@格式转为上传需要的格式

@end

//同步记录
@interface MMSyncHistoryInfo : NSObject {
	NSInteger	syncId;
	NSInteger	beginTime;
	NSInteger	endTime;
	NSInteger	syncType;
	NSInteger	errorcode;
	NSString	*detailInfo;	
}
@property (nonatomic) NSInteger syncId;
@property (nonatomic) NSInteger beginTime;
@property (nonatomic) NSInteger endTime;
@property (nonatomic) NSInteger syncType;
@property (nonatomic) NSInteger	errorcode;
@property (copy, nonatomic) NSString *detailInfo;
@end


@interface MMAboutMeMessage : NSObject {
	NSString* id;
	NSInteger kind;
	NSString *statusId;
	NSUInteger	ownerId;
	NSString *ownerName;
	
	int64_t dateLine;
	BOOL isRead;
	
	NSString *commentId;
	NSString *comment;
	NSString *sourceComment;
}
@property (nonatomic, copy) NSString* id;
@property (nonatomic) NSInteger kind;
@property (nonatomic, copy)NSString *statusId;
@property (nonatomic) int64_t dateLine;
@property (nonatomic) NSUInteger	ownerId;
@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic) BOOL isRead;

@property (nonatomic, copy)NSString *commentId;
@property (nonatomic, copy)NSString *comment;
@property (nonatomic, copy)NSString *sourceComment;

-(id)initWithMessage:(MMAboutMeMessage*)msg;
-(id)initWithDictionary:(NSDictionary*)dic;
@end


//动态中的附件结构
@interface MMAccessoryInfo : NSObject
{
	MMAccessoryType	accessoryType;
    
    NSString* type;
    uint64_t accessoryId;
	NSString* title;
	NSString* url;
}
@property (nonatomic) MMAccessoryType accessoryType;
@property (nonatomic, copy) NSString* type;
@property (nonatomic) uint64_t accessoryId;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* url;

+ (MMAccessoryInfo*)accessoryInfoFromDict:(NSDictionary*)accessoryDict;
+ (MMAccessoryType)typeFromString:(NSString*)typeString;

- (void)loadFromDict:(NSDictionary*)accessoryDict;
- (NSMutableDictionary*)toDict;

@end

@interface MMFileAccessoryInfo : MMAccessoryInfo
{
    uint64_t size;
    NSString* mime;
}
@property (nonatomic) uint64_t size;
@property (nonatomic, copy) NSString* mime;

@end

//图片附件结构
@interface MMImageAccessoryInfo : MMAccessoryInfo
{
    NSString* statusId;
	NSUInteger width;
	NSUInteger height;
}
@property (nonatomic, copy) NSString* statusId;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;

@end

@interface MMCountryInfo : NSObject {
    NSString* enCountryName;  //国家英文名称
    NSString* cnCountryName; //国家中文名称
    NSString* isoCountryCode; //国家缩写
    NSString* telCode;  //电话区号
    
    //for validation
    NSArray*  validPhoneLen; //合法的手机号长度
    NSArray*  validPhonePrefix; //合法的手机号前缀
}
@property (nonatomic, copy) NSString* enCountryName;
@property (nonatomic, copy) NSString* cnCountryName;
@property (nonatomic, copy) NSString* isoCountryCode;
@property (nonatomic, copy) NSString* telCode;
@property (nonatomic, retain) NSArray*  validPhoneLen;
@property (nonatomic, retain) NSArray*  validPhonePrefix;

+ (id)countryInfoFromDictionary:(NSDictionary*)dictionary;

@end


@interface MMMyMoInfo : MMAboutMeMessage {
    BOOL sms_;
}
@property (nonatomic) BOOL sms;
@end


@interface MMGroupInfo : NSObject {
    NSInteger groupId_;
    NSString* groupName_;
    NSString* notice_;
    NSString* introduction_;
    NSInteger groupOpenType_; //1 公开群 2 私密群
    NSInteger createTime_;
    NSInteger modifyTime_;
    MMMomoUserInfo* creator_;
    MMMomoUserInfo* master_;
    NSArray* managers_;
    
    NSInteger memberCount_;
    BOOL isHide_;
}
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString* groupName;
@property (nonatomic) NSInteger groupOpenType;
@property (nonatomic, copy) NSString* notice;
@property (nonatomic, copy) NSString* introduction;
@property (nonatomic) NSInteger createTime;
@property (nonatomic) NSInteger modifyTime;
@property (nonatomic, retain) MMMomoUserInfo* creator;
@property (nonatomic, retain) MMMomoUserInfo* master;
@property (nonatomic, retain) NSArray* managers;
@property (nonatomic) NSInteger memberCount;
@property (nonatomic) BOOL isHide;

+ (MMGroupInfo*)groupInfoFromDict:(NSDictionary*)dict;

@end

@interface MMGroupMemberInfo : MMMomoUserInfo {
    MMGroupMemberGrade grade_;
}
@property (nonatomic) MMGroupMemberGrade grade;

+ (MMGroupMemberInfo*)groupMemberInfoFromDict:(NSDictionary*)dict;

- (NSString*)namePinyin;

@end