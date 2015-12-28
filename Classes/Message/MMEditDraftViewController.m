//
//  MMEditDraftViewController.m
//  momo
//
//  Created by jackie on 11-3-8.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MMEditDraftViewController.h"
#import "MMDraftMgr.h"
#import "MMCommonAPI.h"
#import "MMThemeMgr.h"
#import "RegexKitLite.h"
#import "MMLoginService.h"
#import "MMSelectImageCollection.h"

@implementation MMEditDraftViewController
@synthesize messageDraft, selectImageBackup;

- (id)initWithDraft:(MMDraftInfo*)draftInfo {
	if (self = [super init]) {
        self.navigationItem.title = @"编辑草稿";
        
		self.messageDraft = draftInfo;
		syncToWeibo = draftInfo.syncToWeibo;

		
		self.selectedImages = [NSMutableArray array];
		self.selectImageBackup = [NSMutableArray array];
		
		if (messageDraft.attachImagePaths) {
			for (NSString* imagePath in messageDraft.attachImagePaths) {
				if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
					NSData* imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
					UIImage* image = [[UIImage alloc] initWithData:imageData];
					
					MMSelectImageInfo* imageInfo = [[[MMSelectImageInfo alloc] init] autorelease];
                    imageInfo.url = imagePath;
                    imageInfo.tmpSelectImagePath = imagePath;
					imageInfo.draftImagePath = imagePath;
					imageInfo.imageSize = imageData.length;
                    imageInfo.originImage = image;
					imageInfo.thumbImage = [MMCommonAPI imageWithImage:image scaledToSize:CGSizeMake(SELECT_THUMB_IMAGE_SIZE, SELECT_THUMB_IMAGE_SIZE)];
					
					[selectedImages addObject:imageInfo];
                    [selectImageBackup addObject:imageInfo];
					
					[imageData release];
					[image release];
				}
			}
		}
		attachImagesChanged = NO;
        
        if (messageDraft.groupId > 0) {
            MMGroupInfo* groupInfo = [[[MMGroupInfo alloc] init] autorelease];
            groupInfo.groupId = messageDraft.groupId;
            groupInfo.groupName = messageDraft.groupName;
            self.groupInfo = groupInfo;
        }
	}
	return self;
}

- (void)loadView {
	[super loadView];
	
    if (messageDraft.draftType == draftRetweet) {
        [toolBar setItems:[NSArray arrayWithObjects:atItem, flexItem, faceItem, flexItem, weiboItem, nil]];
    }
    
    //解析@好友
    NSArray* splitArray = [messageDraft.text componentsSeparatedByRegex:@"(@[^հ]*?հ[\\d]*?հ)" 
                                                                  options:(RKLCaseless | RKLDotAll) 
                                                                    range:NSMakeRange(0, messageDraft.text.length) 
                                                                    error:nil];
    for (int i = 0; i < splitArray.count; i++) {
        NSString* splitString = [splitArray objectAtIndex:i];
        if (!splitString || splitString.length == 0) {
            continue;
        }
        
        if (i % 2 == 0) {
            [messageTextView appendText:splitString];
            continue;
        }
        
        //解析@链接
        NSArray* atSplit = [splitString componentsSeparatedByString:@"հ"];
        if (atSplit.count != 3) {
            [messageTextView appendText:splitString];
            continue;
        }
        
        NSString* visibleString = [atSplit objectAtIndex:0];
        NSString* hideString = [NSString stringWithFormat:@"հ%@հ", [atSplit objectAtIndex:1]];
        MMHidePortionText* hidePortionText = [MMHidePortionText hidePortionTextWithString:visibleString hideString:hideString];
        hidePortionText.extraText = @"";
        [messageTextView appendHidePortionText:hidePortionText];
    }
//	messageTextView.text = messageDraft.text;
	
	if (messageDraft.syncToWeibo) {
		[weiboButton setImage:[MMThemeMgr imageNamed:@"ic_sina_have.png"] forState:UIControlStateNormal];
	}
	
	[super updateImageAndAddressButton];
	[super verifyUploadButton];
}

- (void)applyAttachImagesChange {
	NSMutableArray* removeImages = [NSMutableArray arrayWithArray:selectImageBackup];
	
	for (NSUInteger i = 0; i < selectImageBackup.count; i++) {
		MMSelectImageInfo* backupImageInfo = [selectImageBackup objectAtIndex:i];
		for (MMSelectImageInfo* imageInfo in selectedImages) {
			if (backupImageInfo == imageInfo) {
				[removeImages removeObject:backupImageInfo];
				break;
			}
		}
	}
	
	// delete removed image
	for (MMSelectImageInfo* imageInfo in removeImages) {
		if (imageInfo.draftImagePath) {
			[[NSFileManager defaultManager] removeItemAtPath:imageInfo.draftImagePath error:nil];
		}
	}
	
	messageDraft.attachImagePaths = [self applyImageSelection];
}

- (BOOL)checkNeedSave {
	NSString* content = messageTextView.text;
	if ([content compare:[messageDraft textWithoutUid]] != NSOrderedSame 
		|| attachImagesChanged || (groupInfo_ && messageDraft.groupId != groupInfo_.groupId)) {
		return YES;
	}
	
	return NO;
}

- (void)actionLeft:(id)sender {
	if (isSending) {
		return;
	}

	if ([self checkNeedSave]) {
		UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"内容被修改，是否保存？" 
																 delegate:self 
														cancelButtonTitle:@"取消" 
												   destructiveButtonTitle:nil 
														otherButtonTitles:@"保存", @"不保存", nil];
		actionSheet.tag = 201;
		[actionSheet showInView:self.view];
		[actionSheet release];
	} else {
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (void)actionRight:(id)sender {
	if (isSending) {
		return;
	}
	
    CHECK_NETWORK;
	
	isSending = YES;
	
	MMDraftInfo* draftInfo = [self createDraftInfo];
	
	[[MMDraftMgr shareInstance] updateDraftInfo:draftInfo];
	[[MMDraftMgr shareInstance] uploadDraftWillStart:draftInfo];
	
    [MMAlbumPickerController removeAllImage];
	[self.navigationController popViewControllerAnimated:YES];
}

- (MMDraftInfo*)createDraftInfo {
	NSString* content = [messageTextView textWithHiddenPortion];
	if ((content == nil || content.length == 0) && selectedImages.count > 0) {
		content = @"分享照片";
	}
	messageDraft.text = content;
	messageDraft.syncToWeibo = syncToWeibo;
    if (groupInfo_) {
        messageDraft.groupId = groupInfo_.groupId;
        messageDraft.groupName = groupInfo_.groupName;
    }
	
	if (attachImagesChanged) {
		[self applyAttachImagesChange];
	}
	
	return messageDraft;
}

//判断草稿中图片是否有改变
- (BOOL) checkAttachImagesChanged {
    if ([selectedImages count] != [selectImageBackup count]) {
        return YES;
    }
    
    NSMutableArray* urlArray = [[[NSMutableArray alloc] init] autorelease];
    for (MMSelectImageInfo* imageInfo in selectedImages) {
        [urlArray addObject:imageInfo.url]; 
    }
    
    for (MMSelectImageInfo* imageInfo in selectImageBackup) {
        if (![urlArray containsObject:imageInfo.url]) {
            return YES;
        }
    }
    
    return NO;
}
#pragma mark MMAlbumPickerControllerDelegate
- (void)didFinishPickingAlbum: (NSMutableArray*) selectAsset{
    [super didFinishPickingAlbum:selectAsset];
    attachImagesChanged = [self checkAttachImagesChanged];
}

- (void)didCancelPickingAlbum{
    [super didCancelPickingAlbum];
    
    [self updateImageAndAddressButton];
    [self verifyUploadButton];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[super imagePickerController:picker didFinishPickingMediaWithInfo:info];
	
	attachImagesChanged = YES;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == 201) {
		switch (buttonIndex) {
			case 0:
			{
				//save and return
				MMDraftInfo* draftInfo = [self createDraftInfo];
				[[MMDraftMgr shareInstance] updateDraftInfo:draftInfo];
				[self.navigationController popViewControllerAnimated:YES];
                [MMAlbumPickerController removeAllImage];
			}
				break;
			case 1:
			{
				[self.navigationController popViewControllerAnimated:YES];
                [MMAlbumPickerController removeAllImage];
			}
				break;
			default:
				break;
		}
	} else {
        [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    }
}

- (void)dealloc {
	self.selectImageBackup = nil;
	[messageDraft release];
	[super dealloc];
}

@end
