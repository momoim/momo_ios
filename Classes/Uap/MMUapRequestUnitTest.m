/*
 *  MMUapRequest.cpp
 *  libSync
 *
 *  Created by aminby on 2010-6-24.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "GHTestCase.h"
#import "MMGlobalData.h"
#import "MMUapRequest.h"
#import "MMLoginService.h"
#import <unistd.h>


//你的朋友类
@interface Friend : NSObject{
    int age;
    NSString *name;
}
@property(assign) int age;
@property(retain) NSString *name;
@end
@implementation Friend
@synthesize age,name;
@end

//人类
@interface Person : NSObject{NSArray *friends;}
@property(retain) NSArray *friends;
@end
@implementation Person
@synthesize friends;
@end

@interface MMTestKVO : GHTestCase {
    NSMutableArray *array;
}

@end

@implementation MMTestKVO
-(id)init {
    self = [super init];
    if (self) {
        array = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc {
    [array release];
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%@", change);
}

-(void)testKVO {
    [self addObserver:self forKeyPath:@"array.@count" options:NSKeyValueObservingOptionNew context:nil];
    [[self mutableArrayValueForKeyPath:@"array"] addObject:@"dd"];
    [[self mutableArrayValueForKeyPath:@"array"] removeAllObjects];
    [[self mutableArrayValueForKeyPath:@"array"] addObject:@"dd"];
    [self removeObserver:self forKeyPath:@"array.@count"];
}
-(void)testKVC {
    //初始化
    NSMutableArray *persons = [[NSMutableArray alloc] init];
    for(int pCount = 0;pCount < 10;pCount++){
        NSMutableArray *friends = [[[NSMutableArray alloc] init] autorelease];
        Person *you = [[Person alloc] init];
        for(int i=0;i<20;i++){
            Friend *friend = [[Friend alloc] init];
            friend.age = random()/100000000;
            friend.name = (friend.age % 2) == 0 ? [NSString stringWithFormat:@"jory %d",pCount ] : nil;
            [friends addObject:friend];
            [friend release];
        }
        you.friends = friends;
        [persons addObject:you];
        [you release];
    }
    
    Person *aPerson = [persons objectAtIndex:0];
    
    //下面是几个统计计算比较有用的方法
    NSLog(@"min age: %@",[aPerson.friends valueForKeyPath:@"@min.age"]);
    NSLog(@"max age: %@",[aPerson.friends valueForKeyPath:@"@max.age"]);
    NSLog(@"avg age: %@",[aPerson valueForKeyPath:@"friends.@avg.age"]);        //注意这里遍历的是所有数组
    NSLog(@"sum age: %@",[aPerson valueForKeyPath:@"friends.@sum.age"]);    
    NSLog(@"count age: %@",[aPerson valueForKeyPath:@"friends.@count.age"]);
    
    // 返回在数组中Friend实例name相同的对象集合（去掉重复），注意：@distinctUnionOfArrays以集合对象为获取数据源
    // @distinctUnionOfSets相似，不一样的地方是数据源一个是Set，另一个是Array
    NSLog(@"@distinctUnionOfArrays users: %@",[persons valueForKeyPath:@"friends.@distinctUnionOfArrays.name"]);
    
    //返回Friend实例name相同的对象集合（去掉重复），注意：@distinctUnionOfObjects以一个对象为数据源
    //与其上有一点点区别的地方是，此值为"nil"时不放在返回的集合对象中，下面的@unionOfObjects同理
    for (Friend *f in aPerson.friends) {
     //   NSLog(@"%@", f.name);
    }
  //  NSLog(@"%@", aPerson.friends);
    NSLog(@"@distinctUnionOfObjects users: %@",[aPerson.friends valueForKeyPath:@"@distinctUnionOfObjects.name"]);
    NSLog(@"@unionOfObjects users: %@",[aPerson.friends valueForKeyPath:@"@unionOfObjects.name"]);
    NSLog(@"@unionOfObjects user age: %@",[aPerson.friends valueForKeyPath:@"@unionOfObjects.age"]);
    NSArray *array1 = [aPerson.friends valueForKeyPath:@"@unionOfObjects.age"];
    NSLog(@"@unionOfObjects.age:%@", array1);
    // 与distinctUnionOfArrays相似，但返回对象不去掉重复
    // @unionOfSets与此相似
    NSLog(@"@unionOfArrays users: %@",[persons valueForKeyPath:@"friends.@unionOfArrays.name"]);
    
    // 与distinctUnionOfArrays相似，但返回对象不去掉重复
    NSLog(@"@unionOfObjects users: %@",[aPerson.friends valueForKeyPath:@"@unionOfObjects.name"]);    
    
    [persons release];
}
@end

@interface MMUapRequestTest : GHTestCase {
	
}
@end

@implementation MMUapRequestTest
- (void)setUp {
	MMLoginService *loginService = [MMLoginService shareInstance];
	
	int result = [loginService doLogin:@"13635273142" password:@"123456" zonecode:@"+86"];
	GHAssertEquals(result, 0, @"登录失败");
}

- (void)tearDown {
	MMLoginService *loginService = [MMLoginService shareInstance];
	[loginService doLogout];
}


-(void)testUpdateSign {
	NSString *request = [NSString stringWithFormat:@"user/update_sign.json"];//, [[MMLoginService shareInstance] getLoginUserId]];
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	[dic setObject:@"ddd" forKey:@"text"];
	[dic setObject:@"2" forKey:@"source"];
	NSDictionary *res = [MMUapRequest postSync:request withObject:dic];
	NSLog(@"%@", res);
}


-(void)testGroup {
	NSArray *groups = nil;
	NSInteger statusCode = [MMUapRequest getSync:@"group.json?type=2" jsonValue:&groups compress:NO];
	GHAssertEquals(statusCode, 200, @"get group fail");
	NSLog(@"%@", groups);
	
	for (NSDictionary *group in groups) {
		NSLog(@"%@, %@", [group objectForKey:@"name"], [group objectForKey:@"id"]);
		NSString *request = [NSString stringWithFormat:@"group_contact/%d.json", [[group objectForKey:@"id"] integerValue]];
		NSArray *members = nil;

		statusCode = [MMUapRequest getSync:request jsonValue:&members compress:YES];
		GHAssertEquals(statusCode, 200, @"get group member fail");
		NSMutableString *ids = [[[NSMutableString alloc] init] autorelease];
		
		for (int i = 0; i < [members count]; i++) {
			NSDictionary *member = [members objectAtIndex:i];
			if(i == [members count])
			   [ids appendFormat:@"%d", [[member objectForKey:@"id"] integerValue]];
			else
			   [ids appendFormat:@"%d,", [[member objectForKey:@"id"] integerValue]];
		}
		request = [NSString stringWithFormat:@"group_contact/show_batch/%d.json", [[group objectForKey:@"id"] integerValue]];
		members = nil;
		statusCode = [MMUapRequest postSync:request withObject:[NSDictionary dictionaryWithObject:ids forKey:@"ids"] jsonValue:&members];
		GHAssertEquals(statusCode, 200, @"get group member info fail");
	}
}

-(void)testAboutMe {
	NSArray *groups = nil;
	NSInteger statusCode = [MMUapRequest getSync:@"statuses/aboutme_alone.json?page=1&new=0" jsonValue:&groups compress:YES];
	GHAssertEquals(statusCode, 200, @"get group fail");
	NSLog(@"%@", groups);
	NSLog(@"%@", [[groups objectAtIndex:0] objectForKey:@"text"]);
}

-(void)testUserInfo {
	NSDictionary *userInfo = nil;
	NSInteger statusCode = [MMUapRequest getSync:@"user/show.json" jsonValue:&userInfo compress:NO];
	GHAssertEquals(statusCode, 200, @"get user info fail");
	NSLog(@"%@", userInfo);

}

@end

