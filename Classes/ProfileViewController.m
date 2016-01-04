//
//  ProfileViewController.m
//  Message
//
//  Created by 杨朋亮 on 14-9-13.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "ProfileViewController.h"
#import "MMWebImageView.h"
#import "MBProgressHUD.h"
#import "UIImage+Resize.h"
#import "MMCommonAPI.h"
#import "MMLoginService.h"
#import "MMThemeMgr.h"
#define kTakePicActionSheetTag  101


#define UPLOAD_AVATAR_SIZE 130

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView    *headView;
@property (weak, nonatomic) IBOutlet UIScrollView   *scrollView;

@property (retain, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"个人资讯"];
    
    [self.headView setUserInteractionEnabled: YES];
    CALayer *imageLayer = [self.headView layer];   //获取ImageView的层
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:6];
    MMWebImageView *avatarView = (MMWebImageView*)self.headView;

   	avatarView.placeholderImage = [MMThemeMgr imageNamed:@"card_avatar.png"];
    //头像
    if ([MMLoginService shareInstance].avatarImageURL.length > 0) {
        NSString *avatarUrl = [MMLoginService shareInstance].avatarImageURL;
        avatarView.imageURL = [MMCommonAPI avatarUrlBySmallAvatarUrl:avatarUrl desireSize:130];
        [avatarView startLoading];
    } else {
        [avatarView resetImageURL:nil];
    }
    
    self.nameLabel.text = [MMLoginService shareInstance].userName;
    
    [self.scrollView setContentSize:CGSizeMake(0, self.view.frame.size.height)];
    [self.scrollView setClipsToBounds:YES];
    self.scrollView.delegate = self;
    
}

- (void) viewWillAppear:(BOOL)animated{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) editorHeadAction:(id)sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"摄像头拍照", @"从相册选取",nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.tag = kTakePicActionSheetTag;
    [actionSheet showInView:self.view];
    
}

- (void) setting {
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField:NO];
}


- (void)animateTextField:(BOOL)up
{
    const int movementDistance = 80;
    const float movementDuration = 0.3f;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    
    [UIView setAnimationBeginsFromCurrentState: YES];
    
    [UIView setAnimationDuration: movementDuration];
    
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    
    [UIView commitAnimations];
    
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag==kTakePicActionSheetTag) {
        if (buttonIndex == 0) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate  = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:picker animated:YES completion:NULL];
        }else if(buttonIndex == 1){
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate  = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:picker animated:YES completion:NULL];
        }
    }
}


- (void)uploadNewAvatar:(NSData*)avatarData origin:(NSData*)origin {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [[MMLoginService shareInstance] increaseActiveCount];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

        NSInteger statusCode = 0;
        NSString* newAvatarURL = [[MMLoginService shareInstance] changedMyAvatar:avatarData
                                                                      originImage:origin
                                                                       statusCode:&statusCode];

        [[MMLoginService shareInstance] decreaseActiveCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:NO];
            if (statusCode != 200) {
                [MMCommonAPI alert:@"更新头像失败"];
            } else {
                MMWebImageView *avatarView = (MMWebImageView*)self.headView;
                [avatarView resetImageURL:newAvatarURL];
                [avatarView startLoading];
                [MMLoginService shareInstance].avatarImageURL = newAvatarURL;
            }
        });
    });
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage* cropImage = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage* originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (!cropImage) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        return;
    }
    
    cropImage = [cropImage resizedImage:UPLOAD_AVATAR_SIZE];
    NSData *avatarData = UIImageJPEGRepresentation(cropImage, CONSTRAINT_UPLOAD_IMAGE_QUALITY);
    
    NSData *avatarOrigin = nil;
    if (originImage) {
        originImage = [originImage resizedImage:CONSTRAINT_UPLOAD_IMAGE_SIZE];
        avatarOrigin = UIImageJPEGRepresentation(originImage, CONSTRAINT_UPLOAD_IMAGE_QUALITY);
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self uploadNewAvatar:avatarData origin:avatarOrigin];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)dealloc {

}
@end
