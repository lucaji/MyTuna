/*
 * WMGaugeView.h
 *
 * Copyright (C) 2014 William Markezana <william.markezana@me.com>
 *
 */

#import <UIKit/UIKit.h>
#import "WMGaugeViewStyle.h"
#import "WMGaugeViewStyleFlatThin.h"
#import "WMGaugeViewStyle3D.h"


/**
 * Styling enumerations
 */
typedef enum
{
    WMGaugeViewSubdivisionsAlignmentTop,
    WMGaugeViewSubdivisionsAlignmentCenter,
    WMGaugeViewSubdivisionsAlignmentBottom
}
WMGaugeViewSubdivisionsAlignment;

/**
 * WMGaugeView class
 */
@interface WMGaugeView : UIView <CAAnimationDelegate>


//@property (nonatomic) UILabel*centerPitchLabel;
/**
 * WMGaugeView properties
 */
@property (nonatomic, readwrite, assign) IBInspectable BOOL showInnerBackground;
@property (nonatomic, readwrite, assign) IBInspectable BOOL showInnerRim;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat innerRimWidth;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat innerRimBorderWidth;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scalePosition;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleStartAngle;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleEndAngle;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleDivisions;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleSubdivisions;
@property (nonatomic, readwrite, assign) IBInspectable BOOL showScaleShadow;
@property (nonatomic, readwrite, assign) IBInspectable BOOL showScale;
@property (nonatomic, readwrite, assign) IBInspectable WMGaugeViewSubdivisionsAlignment scalesubdivisionsAligment;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleDivisionsLength;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleDivisionsWidth;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleSubdivisionsLength;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat scaleSubdivisionsWidth;
@property (nonatomic, readwrite, strong) IBInspectable UIColor *scaleDivisionColor;
@property (nonatomic, readwrite, strong) IBInspectable UIColor *scaleSubDivisionColor;
@property (nonatomic, readwrite, strong) IBInspectable UIFont *scaleFont;
@property (nonatomic, readwrite, assign) IBInspectable float value;
@property (nonatomic, readwrite, assign) IBInspectable float minValue;
@property (nonatomic, readwrite, assign) IBInspectable float maxValue;
@property (nonatomic, readwrite, assign) IBInspectable BOOL showRangeLabels;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat rangeLabelsWidth;
@property (nonatomic, readwrite, strong) IBInspectable UIFont *rangeLabelsFont;
@property (nonatomic, readwrite, strong) IBInspectable UIColor *rangeLabelsFontColor;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat rangeLabelsFontKerning;
@property (nonatomic, readwrite, strong) IBInspectable NSArray *rangeValues;
@property (nonatomic, readwrite, strong) IBInspectable NSArray *rangeColors;
@property (nonatomic, readwrite, strong) IBInspectable NSArray *rangeLabels;
@property (nonatomic, readwrite, strong) IBInspectable UIColor *unitOfMeasurementColor;
@property (nonatomic, readwrite, assign) IBInspectable CGFloat unitOfMeasurementVerticalOffset;
@property (nonatomic, readwrite, strong) IBInspectable UIFont *unitOfMeasurementFont;
@property (nonatomic, readwrite, strong) IBInspectable NSString *unitOfMeasurement;
@property (nonatomic, readwrite, assign) IBInspectable BOOL showUnitOfMeasurement;
@property (nonatomic, readwrite, strong) id<WMGaugeViewStyle> style;

/**
 * WMGaugeView public functions
 */
- (void)setValue:(float)value animated:(BOOL)animated;
- (void)setValue:(float)value animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration;
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;

- (void)invalidateNeedle;

@end
