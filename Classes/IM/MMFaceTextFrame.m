//
//  MMFaceTextFrame.m
//  momo
//
//  Created by houxh on 11-9-20.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "MMFaceTextFrame.h"
#import "MMGlobalData.h"
#import "MMCommonAPI.h"
#import "MMThemeMgr.h"
#import "RegexKitLite.h"

const NSString *kEmoIMKissing	= @"[KISS]";			//		;w		KISS
const NSString *kEmoIMPoor	= @"[可怜]";				//		:.(		可怜
const NSString *kEmoIMAngry	= @"[生气]";				//		)B(		生气
const NSString *kEmoIMSweat	= @"[汗]";				//		=.=		汗
const NSString *kEmoIMOrz	= @"[囧]";				//		<O		囧
const NSString *kEmoIMRuttish	= @"[好色的]";			//		;D		好色的
const NSString *kEmoIMScared	= @"[惊恐的]";			//		:B(		惊恐的		
const NSString *kEmoIMLaughing	= @"[大笑]";			//		:D		大笑
const NSString *kEmoIMUnhappy	= @"[伤心]";			//		:((		伤心
const NSString *kEmoIMDespise	= @"[鄙视]";			//		):<		鄙视
const NSString *kEmoIMCrying	= @"[大哭]";			//		:=(		大哭
const NSString *kEmoIMSad	= @"[难过]";				//		:(		难过
const NSString *kEmoIMGoingcrazy	= @"[抓狂]";		//		>.<		抓狂
const NSString *kEmoIMRunnynose	= @"[流鼻涕]";			//		>(=		流鼻涕
const NSString *kEmoIMShy	= @"[害羞]";				//		:.)		害羞
const NSString *kEmoIMTitter	= @"[偷笑]";			//		(:Q		偷笑
const NSString *kEmoIMDizzy	= @"[头晕]";				//		@.@		头晕
const NSString *kEmoIMUnlucky	= @"[衰]";			//		>;		衰
const NSString *kEmoIMEmbarrassed	= @"[尴尬]";		//		;<		尴尬			
const NSString *kEmoIMHappy	= @"[微笑]";				//		:)		微笑


#define FACE_COUNT 20
NSString *allFace[FACE_COUNT][3] = {
{@"大笑", @"big smile", @"big_smile.png"},
{@"泪奔", @"cry", @"cry.png"},
{@"鄙视", @"misdoubt", @"misdoubt.png"},	
{@"惊讶", @"surprised", @"surprise.png"},	
{@"怒了", @"angry", @"beyond_endurance.png"}, 
{@"坏笑", @"bad smile", @"bad_smile.png"},
{@"没办法", @"i have no idea", @"i_have_no_idea.png"},
{@"恶魔", @"devil", @"the_devil.png"},
{@"尴尬", @"embarrassed", @"embarrassed.png"},
{@"花心", @"greedy", @"greeding.png"},
{@"汗", @"just out", @"just_out.png"},
{@"可爱", @"lovely", @"pretty_smile.png"},
{@"摇滚", @"rock", @"rockn_roll.png"},
{@"害羞", @"shamefaced", @"shame.png"},
{@"失落", @"sigh", @"sigh.png"},
{@"微笑", @"smile", @"smile.png"},
{@"无语", @"unbelievable", @"unbelievable.png"},
{@"郁闷", @"unhappy", @"unhappy.png"},
{@"困惑", @"what", @"what.png"},
{@"生气", @"wicked", @"wicked.png"},
};

@interface MMFace()
- (NSString*)getHtmlTextByFace:(NSString*)strFace withFaceSize:(NSInteger)faceSize;
- (NSString*)replaceFaceWithHTML:(NSString*)string withFaceSize:(NSInteger)faceSize;
@end

@implementation MMFace
-(id)init {
    self = [super init];
    if (self) {
        arrayFace_ = [[NSMutableArray alloc]initWithObjects:
                      kEmoIMKissing,		
                      kEmoIMPoor,			  
                      kEmoIMAngry,		  
                      kEmoIMSweat,			
                      kEmoIMOrz,				
                      kEmoIMRuttish,		
                      kEmoIMScared,			
                      kEmoIMLaughing,		
                      kEmoIMUnhappy,		
                      kEmoIMDespise,		
                      kEmoIMCrying,			
                      kEmoIMSad,				
                      kEmoIMGoingcrazy,	
                      kEmoIMRunnynose,	
                      kEmoIMShy,				
                      kEmoIMTitter,			
                      kEmoIMDizzy,			
                      kEmoIMUnlucky,		
                      kEmoIMEmbarrassed,
                      kEmoIMHappy,	
                      nil
                      ];
    }
    return self;
}
-(void)dealloc {
    [arrayFace_ release];
    [super dealloc];
}
+ (MMFace*)shareInstance {
	static MMFace* instance = nil;
	if(!instance) {
		@synchronized(self) {
			if(!instance) {
				instance = [[MMFace alloc] init];
			}
		}
	}
	return instance;
}


- (NSArray *)getArrayFace {
    NSMutableArray *array = [[[NSMutableArray alloc] initWithCapacity:FACE_COUNT] autorelease];
    for (int i = 0; i < FACE_COUNT; i++) {
        NSString *str = [NSString stringWithFormat:@"[%@]", allFace[i][0]];
        [array addObject:str];
    }
    return array;
}

- (NSString*)getImagePathByFace:(NSString*)strFace {
//    assert([strFace length] > 2);
    NSString *key = [strFace substringWithRange:NSMakeRange(1, [strFace length] - 2)];
    for (int i = 0; i < FACE_COUNT; i++) {
        if (0 == [allFace[i][0] compare:key]) {
            return allFace[i][2];
        }
    }
    return @"";
}

- (NSString*)getHtmlTextByFace:(NSString*)strFace withFaceSize:(NSInteger)faceSize {
    if (0 == [strFace length]) {
		return @"";
	}
	
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString* strTpl = [NSString stringWithFormat:@"<img src=\"file://%@/Image/Default/%%@\" height=\"%d\" width=\"%d\"/>", resourcePath, faceSize, faceSize];
    NSString *imagePath = [self getImagePathByFace:strFace];
    if ([imagePath length] > 0) {
        return [NSString stringWithFormat:strTpl, imagePath];
    }
    return strFace;
}
- (NSString*)replaceFaceWithHTML:(NSString*)string withFaceSize:(NSInteger)faceSize {
    NSArray* matchArray = [string componentsMatchedByRegex:@"\\[[^\\]\\[]*\\]"];
    NSMutableString* result = [NSMutableString stringWithString:string];
    
    for (NSString* faceStr in matchArray) {
        NSString* faceHtml = [self getHtmlTextByFace:faceStr withFaceSize:faceSize];
        if (!faceHtml || [faceHtml isEqualToString:faceStr]) {
            continue;
        }
        
        [result replaceOccurrencesOfString:faceStr 
                                withString:faceHtml 
                                   options:NSCaseInsensitiveSearch 
                                     range:NSMakeRange(0, result.length)];
    }
    return result;
}

- (NSString*)getHtmlTextByFace:(NSString*)strFace {
    return [self getHtmlTextByFace:strFace withFaceSize:32];
}

- (UIImage*)getImageByFace:(NSString*)strFace {
	if (0 == [strFace length]) {
		return nil;
	}
    NSString *imagePath = [self getImagePathByFace:strFace];
    if ([imagePath length] > 0) {
        return [MMThemeMgr imageNamed:imagePath];
    }
    return nil;
}

- (NSString*)replaceFaceWithHTML:(NSString*)string {
    return [self replaceFaceWithHTML:string withFaceSize:32];
}
@end
@implementation MMFaceTextFrame

- (id)initWithHTML:(NSString *)html {
    return [self initWithHTML:html withFaceSize:32];
}
- (id)initWithHTML:(NSString *)html withFaceSize:(NSInteger)faceSize {
    NSString* strDst = [[MMFace shareInstance] replaceFaceWithHTML:html withFaceSize:faceSize];
    return [super initWithHTML:strDst];
}
@end
