//
//  RTHelpableButton.m
//  StartRec
//
//  Created by Luca Cipressi on 19/08/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

#import "LJHelpableButton.h"
#import "LJHelpablePopoverViewController.h"

static void * RecorderHelpModeContext = &RecorderHelpModeContext;

@implementation LJHelpableButton {
    UIViewController<UIPopoverPresentationControllerDelegate>*_vc;
    dispatch_block_t _actionBlock;
}

-(void)configureWithViewController:(UIViewController<UIPopoverPresentationControllerDelegate>*)owner withActionBlock:(dispatch_block_t)actionblock {
    _vc = owner;
    _actionBlock = actionblock;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self setTitleColor:[UIColor darkTextColor] forState:UIControlStateSelected];

    [LJHelpablePopoverViewController.singleton addObserver:self forKeyPath:kUsingHelpModeKey options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:RecorderHelpModeContext];

    [self addTarget:self action:@selector(ownTap:) forControlEvents:UIControlEventTouchUpInside];
    if (_baseTintColor == nil)
        _baseTintColor = self.tintColor;
}

-(void)ownTap:(id)sender {
    if (_vc && LJHelpablePopoverViewController.singleton.usingHelpMode) {
        [LJHelpablePopoverViewController.singleton presentHelpPopoverViewControllerWithTitle:self.helpTitle
                                                           withDescriptiveText:self.helpMessage
                                                              withProcessBlock:_actionBlock
                                                                withAnchorViewOrBarButtonItem:self
                                                               fromPresenterVC:_vc];
        
    } else {
        if (_actionBlock)
            _actionBlock();
    }
    
}

-(void)dealloc {
    [LJHelpablePopoverViewController.singleton removeObserver:self forKeyPath:kUsingHelpModeKey context:RecorderHelpModeContext];

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id newValue = change[NSKeyValueChangeNewKey];
    if (context == RecorderHelpModeContext) {
        if (newValue && newValue != [NSNull null]) {
            assert(NSThread.isMainThread);
            BOOL usingHelpMode = [newValue boolValue];
            UIColor*helpableColor = usingHelpMode?HELPHIGHLIGHTCOLOR_LITE:self.baseTintColor;
            [self setTitleColor:helpableColor forState:UIControlStateNormal];
            self.tintColor = helpableColor;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
