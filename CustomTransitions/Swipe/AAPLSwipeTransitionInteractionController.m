/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The interaction controller for the Swipe demo.  Tracks a UIScreenEdgePanGestureRecognizer
  from a specified screen edge and derives the completion percentage for the
  transition.
 */

#import "AAPLSwipeTransitionInteractionController.h"

@interface AAPLSwipeTransitionInteractionController ()
{
    CGFloat containViewWidth;
}
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, strong, readonly) UIScreenEdgePanGestureRecognizer *gestureRecognizer;
@property (nonatomic, readonly) UIRectEdge edge;
@end


@implementation AAPLSwipeTransitionInteractionController

//| ----------------------------------------------------------------------------
- (instancetype)initWithGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer edgeForDragging:(UIRectEdge)edge
{
    NSAssert(edge == UIRectEdgeTop || edge == UIRectEdgeBottom ||
             edge == UIRectEdgeLeft || edge == UIRectEdgeRight,
             @"edgeForDragging must be one of UIRectEdgeTop, UIRectEdgeBottom, UIRectEdgeLeft, or UIRectEdgeRight.");
    
    self = [super init];
    if (self)
    {
        _gestureRecognizer = gestureRecognizer;
        _edge = edge;
        
        // Add self as an observer of the gesture recognizer so that this
        // object receives updates as the user moves their finger.
        [_gestureRecognizer addTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Use -initWithGestureRecognizer:edgeForDragging:" userInfo:nil];
}


//| ----------------------------------------------------------------------------
- (void)dealloc
{
    [self.gestureRecognizer removeTarget:self action:@selector(gestureRecognizeDidUpdate:)];
}


//| ----------------------------------------------------------------------------
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Save the transitionContext for later.
    self.transitionContext = transitionContext;
    containViewWidth = CGRectGetWidth(self.transitionContext.containerView.frame);
    [super startInteractiveTransition:transitionContext];
}


//| ----------------------------------------------------------------------------
//! Returns the offset of the pan gesture recognizer from the edge of the
//! screen as a percentage of the transition container view's width or height.
//! This is the percent completed for the interactive transition.
//
- (CGFloat)percentForGesture:(UIScreenEdgePanGestureRecognizer *)gesture isLast:(BOOL)lastFlag
{
    // Because view controllers will be sliding on and off screen as part
    // of the animation, we want to base our calculations in the coordinate
    // space of the view that will not be moving: the containerView of the
    // transition context.
    UIView *transitionContainerView = self.transitionContext.containerView;
    
    CGPoint locationInSourceView = [gesture locationInView:transitionContainerView];
    [gesture setTranslation:CGPointZero inView:transitionContainerView];
    
    // Figure out what percentage we've gone.

    CGFloat width = CGRectGetWidth(transitionContainerView.bounds);
    CGFloat height = CGRectGetHeight(transitionContainerView.bounds);
    
    // Return an appropriate percentage based on which edge we're dragging
    // from.
    CGFloat scale;
    CGFloat labelScale;
    if (self.edge == UIRectEdgeRight){
        scale = (width - locationInSourceView.x) / width;
        labelScale = scale;
    }else if (self.edge == UIRectEdgeLeft){
        scale = locationInSourceView.x / width;
        labelScale = (1 - scale);
    }else if (self.edge == UIRectEdgeBottom)
        scale = (height - locationInSourceView.y) / height;
    else if (self.edge == UIRectEdgeTop)
        scale = locationInSourceView.y / height;
    else
        scale = 0.f;
    
    BOOL flag = lastFlag ? ((scale >= 0.5f) ? YES : NO ) : NO;
    [self labelPresentWithScale:labelScale animator:flag];
    return scale;
}

#define duration 2
#define delayTime 0.1
#define damping 0.7
#define velocity 10
//将present中toView的子控件为Label的居中,或者dismiss中fromView的子控件为Labl的居中
- (void)labelPresentWithScale:(CGFloat)scale animator:(BOOL)animator{
    UIView *fromView, *toView;
    UIViewController *fromViewController, *toViewController;
    fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if ([self.transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [self.transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [self.transitionContext viewForKey:UITransitionContextToViewKey];
    }else{
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    BOOL isPresenting = (toViewController.presentingViewController == fromViewController);
    UIView *containView = isPresenting ? toView : fromView;
    for (UIView *view in containView.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)view;
            CGFloat x = scale * containViewWidth / 2;
            if (x <= CGRectGetWidth(lab.bounds) / 2) {
                x = CGRectGetWidth(lab.bounds) / 2;
            }else if ( x >= containViewWidth - CGRectGetWidth(lab.bounds) / 2) {
                x = containViewWidth - CGRectGetWidth(lab.bounds) / 2;
            }
            lab.center = CGPointMake(x, lab.center.y);
            if (animator) {
#if 0
                [UIView animateWithDuration:duration delay:delayTime usingSpringWithDamping:damping initialSpringVelocity:velocity options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
                    lab.center = CGPointMake(lab.center.x, lab.center.y + 10);
                } completion:NULL];
#else
                [self addShakeAnimationWithView:lab];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [lab.superview updateConstraintsIfNeeded];
                });
#endif
            }
        }
    }
}

- (void)addShakeAnimationWithView:(UIView *)view
{
    CGPoint viewPosition = view.layer.position;
    CABasicAnimation *shakeAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    [shakeAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    [shakeAnimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(viewPosition.x - 10, viewPosition.y)]];
    [shakeAnimation setToValue:[NSValue valueWithCGPoint:CGPointMake(viewPosition.x + 10, viewPosition.y)]];
    [shakeAnimation setAutoreverses:YES];
    [shakeAnimation setRepeatCount:3];
    [shakeAnimation setDuration:0.05];
    [view.layer addAnimation:shakeAnimation forKey:nil];
}

//| ----------------------------------------------------------------------------
//! Action method for the gestureRecognizer.
//
- (IBAction)gestureRecognizeDidUpdate:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            // The Began state is handled by the view controllers.  In response
            // to the gesture recognizer transitioning to this state, they
            // will trigger the presentation or dismissal.
            break;
        case UIGestureRecognizerStateChanged:
            // We have been dragging! Update the transition context accordingly.
            [self updateInteractiveTransition:[self percentForGesture:gestureRecognizer isLast:NO]];
            break;
        case UIGestureRecognizerStateEnded:
            // Dragging has finished.
            // Complete or cancel, depending on how far we've dragged.
            if ([self percentForGesture:gestureRecognizer isLast:YES] >= 0.5f)
                [self finishInteractiveTransition];
            else
                [self cancelInteractiveTransition];
            break;
        default:
            // Something happened. cancel the transition.
            [self cancelInteractiveTransition];
            break;
    }
}

@end
