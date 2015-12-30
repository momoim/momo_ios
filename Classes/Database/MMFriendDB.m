//
//  MMFriendDB.m
//  momo
//
//  Created by houxh on 15/12/31.
//
//

#import "MMFriendDB.h"
#import "MMGlobalData.h"
@implementation MMFriendDB
+ (MMFriendDB*)instance {
    static MMFriendDB *_instance = nil;
    @synchronized(self) {
        if(_instance == nil)
            _instance = [[self class] new];
    }
    return _instance;
}


-(int)updateTimestamp {
    return [[MMGlobalData getPreferenceforKey:@"friends_update_timestamp"] intValue];
}

-(void)setUpdateTimestamp:(int)updateTimestamp {
    [MMGlobalData setPreference:[NSNumber numberWithInt:updateTimestamp] forKey:@"friends_update_timestamp"];
    [MMGlobalData savePreference];
}

- (void)setFriends:(NSArray*)friends {
    [MMGlobalData setPreference:friends forKey:@"friends"];
    [MMGlobalData savePreference];
}

- (NSArray*)getFriends {
    return [MMGlobalData getPreferenceforKey:@"friends"];
}

@end
