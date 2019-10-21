//
//  CLTokenView.m
//  CLTokenInputView
//
//  Created by Rizwan Sattar on 2/24/14.
//  Copyright (c) 2014 Cluster Labs, Inc. All rights reserved.
//

#import "CLTokenView.h"

#import <QuartzCore/QuartzCore.h>

static CGFloat const PADDING_X = 4.0;
static CGFloat const PADDING_Y = 2.0;

static NSString *const UNSELECTED_LABEL_FORMAT = @"%@,";
static NSString *const UNSELECTED_LABEL_NO_COMMA_FORMAT = @"%@";


@interface CLTokenView ()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UILabel *label;

@property (strong, nonatomic) UIView *selectedBackgroundView;
@property (strong, nonatomic) UILabel *selectedLabel;

@property (copy, nonatomic) NSString *displayText;

@end

@implementation CLTokenView

- (id)initWithToken:(CLToken *)token font:(nullable UIFont *)font
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        UIColor *tintColor = [UIColor colorWithRed:0.0823 green:0.4941 blue:0.9843 alpha:1.0];
        if ([self respondsToSelector:@selector(tintColor)]) {
            tintColor = self.tintColor;
        }
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(PADDING_X, PADDING_Y, 0, 0)];
        if (font) {
            self.label.font = font;
        }
        self.label.textColor = tintColor;
        self.label.backgroundColor = [UIColor clearColor];
        [self addSubview:self.label];

        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        self.selectedBackgroundView.backgroundColor = tintColor;
        self.selectedBackgroundView.layer.cornerRadius = 3.0;
        [self addSubview:self.selectedBackgroundView];
        self.selectedBackgroundView.hidden = YES;

        self.selectedLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING_X, PADDING_Y, 0, 0)];
        self.selectedLabel.font = self.label.font;
        self.selectedLabel.textColor = [UIColor whiteColor];
        self.selectedLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.selectedLabel];
        self.selectedLabel.hidden = YES;

        self.displayText = token.displayText;

        self.hideUnselectedComma = NO;

        [self updateLabelAttributedText];
        self.selectedLabel.text = token.displayText;

        // Listen for taps
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
        [self addGestureRecognizer:tapRecognizer];

        [self setNeedsLayout];

    }
    return self;
}

#pragma mark - Size Measurements

- (CGSize)intrinsicContentSize
{
    CGSize labelIntrinsicSize = self.selectedLabel.intrinsicContentSize;
    return CGSizeMake(labelIntrinsicSize.width+(2.0*PADDING_X), labelIntrinsicSize.height+(2.0*PADDING_Y));
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize fittingSize = CGSizeMake(size.width-(2.0*PADDING_X), size.height-(2.0*PADDING_Y));
    CGSize labelSize = [self.selectedLabel sizeThatFits:fittingSize];
    return CGSizeMake(labelSize.width+(2.0*PADDING_X), labelSize.height+(2.0*PADDING_Y));
}


#pragma mark - Tinting


- (void)setTintColor:(UIColor *)tintColor
{
    if ([UIView instancesRespondToSelector:@selector(setTintColor:)]) {
        super.tintColor = tintColor;
    }
    self.label.textColor = tintColor;
    self.selectedBackgroundView.backgroundColor = tintColor;
    [self updateLabelAttributedText];
}


#pragma mark - Hide Unselected Comma


- (void)setHideUnselectedComma:(BOOL)hideUnselectedComma
{
    if (_hideUnselectedComma == hideUnselectedComma) {
        return;
    }
    _hideUnselectedComma = hideUnselectedComma;
    [self updateLabelAttributedText];
}


#pragma mark - Taps

-(void)handleTapGestureRecognizer:(id)sender
{
    [self.delegate tokenViewDidRequestSelection:self];
}


#pragma mark - Selection

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (_selected == selected) {
        return;
    }
    _selected = selected;

    if (selected && !self.isFirstResponder) {
        [self becomeFirstResponder];
    } else if (!selected && self.isFirstResponder) {
        [self resignFirstResponder];
    }
    CGFloat selectedAlpha = (_selected ? 1.0 : 0.0);
    if (animated) {
        if (_selected) {
            self.selectedBackgroundView.alpha = 0.0;
            self.selectedBackgroundView.hidden = NO;
            self.selectedLabel.alpha = 0.0;
            self.selectedLabel.hidden = NO;
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.selectedBackgroundView.alpha = selectedAlpha;
            self.selectedLabel.alpha = selectedAlpha;
        } completion:^(BOOL finished) {
            if (!_selected) {
                self.selectedBackgroundView.hidden = YES;
                self.selectedLabel.hidden = YES;
            }
        }];
    } else {
        self.selectedBackgroundView.hidden = !_selected;
        self.selectedLabel.hidden = !_selected;
    }
}


#pragma mark - Attributed Text


- (void)updateLabelAttributedText
{
    // Configure for the token, unselected shows "[displayText]," and selected is "[displayText]"
    NSString *format = UNSELECTED_LABEL_FORMAT;
    if (self.hideUnselectedComma) {
        format = UNSELECTED_LABEL_NO_COMMA_FORMAT;
    }
    NSString *labelString = [NSString stringWithFormat:format, self.displayText];
    NSMutableAttributedString *attrString =
    [[NSMutableAttributedString alloc] initWithString:labelString
                                           attributes:@{NSFontAttributeName : self.label.font,
                                                        NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    NSRange tintRange = [labelString rangeOfString:self.displayText];
    // Make the name part the system tint color
    UIColor *tintColor = self.selectedBackgroundView.backgroundColor;
    if ([UIView instancesRespondToSelector:@selector(tintColor)]) {
        tintColor = self.tintColor;
    }
    [attrString setAttributes:@{NSForegroundColorAttributeName : tintColor}
                        range:tintRange];
    self.label.attributedText = attrString;
}


#pragma mark - Laying out

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    self.backgroundView.frame = bounds;
    self.selectedBackgroundView.frame = bounds;

    CGRect labelFrame = CGRectInset(bounds, PADDING_X, PADDING_Y);
    self.selectedLabel.frame = labelFrame;
    labelFrame.size.width += PADDING_X*2.0;
    self.label.frame = labelFrame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma mark - UIKeyInput protocol

- (BOOL)hasText
{
    return YES;
}

- (void)insertText:(NSString *)text
{
    [self.delegate tokenViewDidRequestDelete:self replaceWithText:text];
}

- (void)deleteBackward
{
    NSLog(@"deleteBackward");
    [self.delegate tokenViewDidRequestDelete:self replaceWithText:nil];
}


#pragma mark - UITextInputTraits protocol (inherited from UIKeyInput protocol)

// Since a token isn't really meant to be "corrected" once created, disable autocorrect on it
// See: https://github.com/clusterinc/CLTokenInputView/issues/2
- (UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeNo;
}

#pragma mark - UITextInput protocol
@synthesize beginningOfDocument;

@synthesize endOfDocument;

@synthesize inputDelegate;

@synthesize markedTextRange;

@synthesize markedTextStyle;

@synthesize selectedTextRange;

@synthesize tokenizer;

- (UITextWritingDirection)baseWritingDirectionForPosition:(nonnull UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    return UITextWritingDirectionLeftToRight;
}

- (CGRect)caretRectForPosition:(nonnull UITextPosition *)position {
    return CGRectMake(0, 0, 10, 30);
}

- (nullable UITextRange *)characterRangeAtPoint:(CGPoint)point {
    return nil;
}

- (nullable UITextRange *)characterRangeByExtendingPosition:(nonnull UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
    return nil;
}

- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point {
    return nil;
}

- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(nonnull UITextRange *)range {
    return nil;
}

- (NSComparisonResult)comparePosition:(nonnull UITextPosition *)position toPosition:(nonnull UITextPosition *)other {

    return NSOrderedSame;
}

- (CGRect)firstRectForRange:(nonnull UITextRange *)range {
    return [self bounds];
}

- (NSInteger)offsetFromPosition:(nonnull UITextPosition *)from toPosition:(nonnull UITextPosition *)toPosition {
    return NSIntegerMax;
}

- (nullable UITextPosition *)positionFromPosition:(nonnull UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    return nil;
}

- (nullable UITextPosition *)positionFromPosition:(nonnull UITextPosition *)position offset:(NSInteger)offset {
    return nil;
}

- (nullable UITextPosition *)positionWithinRange:(nonnull UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    return nil;
}

- (void)replaceRange:(nonnull UITextRange *)range withText:(nonnull NSString *)text {
    //NSLog(@"replaceRange %@",text);
}

- (nonnull NSArray<UITextSelectionRect *> *)selectionRectsForRange:(nonnull UITextRange *)range {
    NSArray *arr = NULL;
    arr = @[];
    return arr;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(nonnull UITextRange *)range {
     //self.textStore = markedText;
}

- (void)setMarkedText:(nullable NSString *)markedText selectedRange:(NSRange)selectedRange {
    //NSLog(@"setMarkedText %@",markedText);
}

- (nullable NSString *)textInRange:(nonnull UITextRange *)range {
    //NSLog(@"textInRange ");
    return nil;
}

- (nullable UITextRange *)textRangeFromPosition:(nonnull UITextPosition *)fromPosition toPosition:(nonnull UITextPosition *)toPosition {
    return nil;
}


- (void)unmarkText {
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {

}

+ (nonnull instancetype)appearance {
    return nil;
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait {
    return nil;
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait whenContainedIn:(nullable Class<UIAppearanceContainer>)ContainerClass, ... {
    return nil;
}

+ (nonnull instancetype)appearanceForTraitCollection:(nonnull UITraitCollection *)trait whenContainedInInstancesOfClasses:(nonnull NSArray<Class<UIAppearanceContainer>> *)containerTypes {
    return nil;
}

+ (nonnull instancetype)appearanceWhenContainedIn:(nullable Class<UIAppearanceContainer>)ContainerClass, ... {
    return nil;
}

+ (nonnull instancetype)appearanceWhenContainedInInstancesOfClasses:(nonnull NSArray<Class<UIAppearanceContainer>> *)containerTypes {
    return nil;
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {

}

- (CGPoint)convertPoint:(CGPoint)point fromCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    return CGPointMake(0, 0);
}

- (CGPoint)convertPoint:(CGPoint)point toCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    return CGPointMake(0, 0);
}

- (CGRect)convertRect:(CGRect)rect fromCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    return CGRectMake(0, 0,1,1);
}

- (CGRect)convertRect:(CGRect)rect toCoordinateSpace:(nonnull id<UICoordinateSpace>)coordinateSpace {
    return CGRectMake(0, 0,1,1);
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {

}

- (void)setNeedsFocusUpdate {

}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return YES;
}

- (void)updateFocusIfNeeded {

}

- (nonnull NSArray<id<UIFocusItem>> *)focusItemsInRect:(CGRect)rect {
    NSArray *arr = NULL;
    arr = @[];
    return arr;
}
#pragma mark - First Responder (needed to capture keyboard)

-(BOOL)canBecomeFirstResponder
{
    return YES;
}


-(BOOL)resignFirstResponder
{
    BOOL didResignFirstResponder = [super resignFirstResponder];
    [self setSelected:NO animated:NO];
    return didResignFirstResponder;
}

-(BOOL)becomeFirstResponder
{
    BOOL didBecomeFirstResponder = [super becomeFirstResponder];
    [self setSelected:YES animated:NO];
    return didBecomeFirstResponder;
}


@end
