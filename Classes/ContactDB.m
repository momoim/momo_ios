//
//  ContactDB.m
//  Message
//
//  Created by daozhu on 14-7-5.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "ContactDB.h"
#import <AddressBook/AddressBook.h>

@implementation ABContact


@end

@interface ContactDB()

@property()NSArray *contacts;
@property(nonatomic)NSMutableArray *observers;

-(ABRecordRef)recordRefWithRecordID:(ABRecordID)recordID;

@end

static void ABChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    ABAddressBookRevert([ContactDB instance].addressBook);
    [[ContactDB instance] loadContacts];
    for (id<ContactDBObserver> ob in [ContactDB instance].observers) {
        [ob onExternalChange];
    }
}

@implementation ContactDB

+(ContactDB*)instance {
    static ContactDB *db;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!db) {
            db = [[ContactDB alloc] init];
        }
    });
    return db;
}

-(id)init {
    self = [super init];
    if (self) {
        self.contacts = [NSMutableArray array];
        self.observers = [NSMutableArray array];
        CFErrorRef err = nil;
        self.addressBook = ABAddressBookCreateWithOptions(NULL, &err);
        if (err) {
            NSString *s = (__bridge NSString*)CFErrorCopyDescription(err);
            NSLog(@"address book error:%@", s);
            return nil;
        }
    }
    return self;
}

-(void)addObserver:(id<ContactDBObserver>)ob {
    if ([self.observers containsObject:ob]) {
        return;
    }
    [self.observers addObject:ob];
}

-(void)removeObserver:(id<ContactDBObserver>)ob {
    [self.observers removeObject:ob];
}

-(void)registerAddressCallback {
     ABAddressBookRegisterExternalChangeCallback(self.addressBook, ABChangeCallback, nil);
}

-(void)loadContacts {
    NSLog(@"load contacts");
    NSArray *thePeople = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(self.addressBook);
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:thePeople.count];
    for (id person in thePeople) {
        ABContact *contact = [[ABContact alloc] init];
        [self copyRecord:(ABRecordRef)person to:contact];
		[array addObject:contact];
    }
	self.contacts = array;
}

-(NSString*)parseNumber:(NSString*)phone {
    char tmp[64] = {0};
    char *dst = tmp;
    const char *src = [phone UTF8String];
    
    while (*src) {
        if (isnumber(*src)){
            *dst++ = *src;
        }
        src++;
    }
    
    return [NSString stringWithUTF8String:tmp];
}


-(NSArray*)loadAllMobile {
    NSMutableArray *array = [NSMutableArray array];
    for (ABContact *c in self.contacts) {
        for (NSDictionary *dict in c.phoneDictionaries) {
            NSString *mobile = [dict objectForKey:@"value"];
            if (mobile.length > 0) {
                NSString *t = [self parseNumber:mobile];
                [array addObject:t];
            }
        }
    }
    return array;
}

-(ABRecordRef)recordRefWithRecordID:(ABRecordID) recordID {
	ABRecordRef contactrec = ABAddressBookGetPersonWithRecordID(self.addressBook, recordID);
    return contactrec;
}



-(NSString *)getRecordString:(ABPropertyID)anID record:(ABRecordRef)record {
	return (__bridge NSString *) ABRecordCopyValue(record, anID);
}
#pragma mark Getting MultiValue Elements
- (NSArray *) arrayForProperty: (ABPropertyID) anID record:(ABRecordRef)record
{
	CFTypeRef theProperty = ABRecordCopyValue(record, anID);
	NSArray *items = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(theProperty);
	CFRelease(theProperty);
	return items;
}


- (NSArray *) labelsForProperty:(ABPropertyID)anID record:(ABRecordRef)record{
	CFTypeRef theProperty = ABRecordCopyValue(record, anID);
	NSMutableArray *labels = [NSMutableArray array];
	for (int i = 0; i < ABMultiValueGetCount(theProperty); i++)
	{
		NSString *label = (__bridge NSString *)ABMultiValueCopyLabelAtIndex(theProperty, i);
        if (label == nil) {
            [labels addObject:@""];
        } else {
            [labels addObject:label];
        }
	}
	CFRelease(theProperty);
	return labels;
}



- (NSArray *) dictionaryArrayForProperty:(ABPropertyID)aProperty record:(ABRecordRef)record
{
	NSArray *valueArray = [self arrayForProperty:aProperty record:record];
	NSArray *labelArray = [self labelsForProperty:aProperty record:record];
	
	int num = MIN(valueArray.count, labelArray.count);
	NSMutableArray *items = [NSMutableArray array];
	for (int i = 0; i < num; i++)
	{
		NSMutableDictionary *md = [NSMutableDictionary dictionary];
        [md setObject:[valueArray objectAtIndex:i] forKey:@"value"];
        NSDictionary *dictChn = @{
                                  @"_$!<Home>!$_" : @"住宅",
                                  @"_$!<Mobile>!$_" : @"移动",
                                  @"_$!<Work>!$_" : @"工作",
                                  @"_$!<WorkFAX>!$_" : @"工作传真",
                                  @"_$!<Main>!$_" : @"主要",
                                  @"_$!<HomeFAX>!$_" : @"住宅传真",
                                  @"_$!<Pager>!$_" : @"传呼",
                                  @"_$!<Other>!$_" : @"其他",
                               };
        
        NSString *originLabel = [labelArray objectAtIndex:i];
        NSString *label = [dictChn objectForKey:originLabel];
        if (!label) {
            label = @"其他";
        }
		[md setObject:label forKey:@"label"];
		[items addObject:md];
	}
	return items;
}


-(void)copyRecord:(ABRecordRef)record to:(ABContact*)contact{
    contact.recordID = ABRecordGetRecordID(record);
    contact.recordType = ABRecordGetRecordType(record);
    contact.firstname = [self getRecordString:kABPersonFirstNameProperty record:record];
    contact.lastname = [self getRecordString:kABPersonLastNameProperty record:record];
    contact.middlename = [self getRecordString:kABPersonMiddleNameProperty record:record];
    contact.prefix = [self getRecordString:kABPersonPrefixProperty record:record];
    contact.suffix = [self getRecordString:kABPersonSuffixProperty record:record];
    contact.nickname = [self getRecordString:kABPersonNicknameProperty record:record];
    
    contact.emailDictionaries = [self dictionaryArrayForProperty:kABPersonEmailProperty record:record];
    contact.phoneDictionaries = [self dictionaryArrayForProperty:kABPersonPhoneProperty record:record];
    contact.relatedNameDictionaries = [self dictionaryArrayForProperty:kABPersonRelatedNamesProperty record:record];
    contact.urlDictionaries =  [self dictionaryArrayForProperty:kABPersonURLProperty record:record];
    contact.dateDictionaries = [self dictionaryArrayForProperty:kABPersonDateProperty record:record];
    contact.addressDictionaries = [self dictionaryArrayForProperty:kABPersonAddressProperty record:record];
    contact.smsDictionaries = [self dictionaryArrayForProperty:kABPersonInstantMessageProperty record:record];
}

@end
