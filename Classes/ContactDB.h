//
//  ContactDB.h
//  Message
//
//  Created by daozhu on 14-7-5.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>



@interface ABContact : NSObject
{
    
}

@property (nonatomic, assign) ABRecordID recordID;
@property (nonatomic, assign) ABRecordType recordType;
@property (nonatomic, readonly) BOOL isPerson;

#pragma mark SINGLE VALUE STRING
@property (nonatomic, copy) NSString *firstname;
@property (nonatomic, copy) NSString *lastname;
@property (nonatomic, copy) NSString *middlename;
@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *suffix;
@property (nonatomic, copy) NSString *nickname;

@property (nonatomic, readonly) NSString *contactName;

@property (nonatomic) NSArray *emailDictionaries;
@property (nonatomic) NSArray *phoneDictionaries;
@property (nonatomic) NSArray *relatedNameDictionaries;
@property (nonatomic) NSArray *urlDictionaries;
@property (nonatomic) NSArray *dateDictionaries;
@property (nonatomic) NSArray *addressDictionaries;
@property (nonatomic) NSArray *smsDictionaries;


+(id)contactWithRecord: (ABRecordRef) record;
-(id)initWithRecord: (ABRecordRef)aRecord;

@end

@protocol ContactDBObserver<NSObject>
-(void)onExternalChange;
@end


@interface ContactDB : NSObject {
    
}

+(ContactDB*)instance;

@property(nonatomic, assign)ABAddressBookRef addressBook;

-(void)addObserver:(id<ContactDBObserver>)ob;
-(void)removeObserver:(id<ContactDBObserver>)ob;

-(void)loadContacts;
-(void)registerAddressCallback;

-(NSArray*)loadAllMobile;


@end
