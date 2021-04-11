//
//  LJHelpablePopoverViewController.m
//  StartRec
//
//  Created by Luca Cipressi on 28/05/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

#import "LJHelpablePopoverViewController.h"

static NSString* const kViewControllerClassName = @"LJHelpablePopoverViewController";

NSString * const kUsingHelpModeKey = @"usingHelpMode";


@interface LJHelpablePopoverViewController () <UIPopoverPresentationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *longdescriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *executeButton;
@property (weak, nonatomic) IBOutlet UIButton *turnOffHelpModeButton;

@property (nonatomic) NSString *titleString;
@property (nonatomic) NSString *descrString;

@property (nonatomic, copy) dispatch_block_t processBlocko;


@end

@implementation LJHelpablePopoverViewController

+(instancetype)singleton {
    static LJHelpablePopoverViewController* _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LJHelpablePopoverViewController alloc] initWithNibName:kViewControllerClassName bundle:nil];
    });
    return _sharedInstance;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller { return UIModalPresentationNone; }

- (IBAction)executeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        LJHelpablePopoverViewController.singleton.usingHelpMode = NO;
        if (self.processBlocko)
            self.processBlocko();
    }];
}
- (IBAction)turnoffHelpModeButtonAction:(id)sender {
    self.processBlocko = nil;
    LJHelpablePopoverViewController.singleton.usingHelpMode = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [self dismissViewControllerAnimated:YES completion:nil];
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.titleLabel.text = self.titleString;
    self.titleLabel.textColor = HELPHIGHLIGHTCOLOR_DARK;
    self.longdescriptionTextView.text = self.descrString;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf) {
            [UIView animateWithDuration:1.0 animations:^{
                weakSelf.executeButton.selected = YES;
            }];
        }
    });
}

- (IBAction)aboutButtonAction:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:^{
//        if (LJHelpablePopoverViewController.singleton.delegate) {
//            [LJHelpablePopoverViewController.singleton.delegate lj_HelpablePopoverAboutButtonAction];
//        }
//    }];
}

-(void)presentHelpPopoverViewControllerWithTitle:(NSString*)title
                              withDescriptiveText:(NSString*)descr
                                 withProcessBlock:(dispatch_block_t)blocko
                   withAnchorViewOrBarButtonItem:(id)anchorView
                                 fromPresenterVC:(UIViewController<UIPopoverPresentationControllerDelegate>*)presenter {

    LJHelpablePopoverViewController*vc = [[LJHelpablePopoverViewController alloc] initWithNibName:kViewControllerClassName bundle:nil];
    vc.processBlocko = blocko;
    vc.titleString = title;
    vc.descrString = descr;
    if (blocko == nil) {
        [vc.executeButton setTitle:@"OK" forState:UIControlStateNormal];
    }
    [vc setModalPresentationStyle:UIModalPresentationPopover];
    vc.preferredContentSize = CGSizeMake(245, 260);
    vc.popoverPresentationController.delegate = presenter;
//    vc.turnOffHelpModeButton.tintColor = SRUIColorManager.singleton.colorForHostMode;
    if ([anchorView isKindOfClass:UIBarButtonItem.class]) {
        vc.popoverPresentationController.barButtonItem = anchorView;
    } else {
        UIView*sourceView = (UIView*)anchorView;
        vc.popoverPresentationController.sourceView = sourceView;
        CGRect bounds = sourceView.bounds;
        vc.popoverPresentationController.sourceRect = bounds;
    }
    [presenter presentViewController:vc animated:YES completion:nil];

}

-(void)dealloc {
    self.processBlocko = nil;
}


@end
