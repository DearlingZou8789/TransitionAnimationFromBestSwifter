/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The second view controller for the Custom Presentation demo.
 */

#import "AAPLCustomPresentationSecondViewController.h"

//  NOTE: The third view controller is presented with a modalPresentationStyle
//        of UIModalPresentationOverFullScreen, rather than the default
//        UIModalPresentationFullScreen (configured in the storyboard).
//
//        When a fullscreen view controller is presented (the corresponding
//        presentation controller's -shouldRemovePresentersView returns YES),
//        the presentation controller temporarily relocates the
//        presenting view controller's view to the presentation controller's
//        containerView.  When the fullscreen view controller is dismissed,
//        the presentation controller places the presenting view controller's
//        view back in its previous superview.
//
//        The relocation of the presenting view controller's view poses a
//        problem in this example because only the presenting view controller's
//        view is relocated, not the intermediate view hierarchy we setup
//        to apply the rounded corner and shadow effect.  If you modify the
//        modalPresentationStyle of Third View Controller in the storyboard,
//        you may notice that during the presentation and dismissal animation
//        for Third View Controller, the rounded corner and shadow effect is
//        lost.
//
//        The workaround is to use the UIModalPresentationOverFullScreen
//        presentation style.  This presentation style is similar to
//        UIModalPresentationFullScreen but the presentation controller for
//        this presentation style overrides -shouldRemovePresentersView to
//        return NO, avoiding the above problem.

@interface AAPLCustomPresentationSecondViewController ()
{
    //起始状态为水平还是竖直
    BOOL isFirstPortrait;
    //初始化时的Size
    CGSize transitionSize;
    //记录当前UISlider的位置
    NSNumber *currentValue;
}
@property (nonatomic, weak) IBOutlet UISlider *slider;
@end


@implementation AAPLCustomPresentationSecondViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    isFirstPortrait = self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact;
    transitionSize = [UIScreen mainScreen].bounds.size;
    [self updatePreferredContentSizeWithTraitCollection:self.traitCollection];
    
    // NOTE: View controllers presented with custom presentation controllers
    //       do not assume control of the status bar appearance by default
    //       (their -preferredStatusBarStyle and -prefersStatusBarHidden
    //       methods are not called).  You can override this behavior by
    //       setting the value of the presented view controller's
    //       modalPresentationCapturesStatusBarAppearance property to YES.
    /* self.modalPresentationCapturesStatusBarAppearance = YES; */
}


//| ----------------------------------------------------------------------------在iOS8.0中,当界面放置方向发生变化时,主要是iPhone或者iPod下会调用willTransitionToTraitCollection:withTransitionCoordinator:方法,并且会有转场动画;如果是iPad就不会调用该方法,iPAD的UITraitCollection.verticalSizeClass和horizontalSizeClass水平和竖直均是一样的,不会调用
/**
 在 UITraitEnvironment 这个接口中另一个非常有用的是 -traitCollectionDidChange:。在 traitCollection 发生变化时，这个方法将被调用。在实际操作时，我们往往会在 ViewController 中重写 -traitCollectionDidChange: 或者 -willTransitionToTraitCollection:withTransitionCoordinator: 方法 (对于 ViewController 来说的话，后者也许是更好的选择，因为提供了转场上下文方便进行动画；但是对于普通的 View 来说就只有前面一个方法了)，然后在其中对当前的 traitCollection 进行判断，并进行重新布局以及动画。
 **/
//UIViewControllerTransitionCoordinator转场上下文
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSLog(@"traitCollection change");
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    //设置全屏时隐藏状态条的标志
    self.modalPresentationCapturesStatusBarAppearance = YES;
    // When the current trait collection changes (e.g. the device rotates),
    // update the preferredContentSize.
    [self updatePreferredContentSizeWithTraitCollection:newCollection];
}

//视图控制器的尺寸有变化时会调用该方法,可以在这里对iPAD旋转进行判断分析
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    
    NSLog(@"size change");
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        //设置全屏时隐藏状态条的标志
        self.modalPresentationCapturesStatusBarAppearance = YES;
        transitionSize = CGSizeMake(transitionSize.height, transitionSize.width);
        NSLog(@"size change ==>  %@", NSStringFromCGSize(transitionSize));
        //改变尺寸
        [self changelSliderValueWithSize:transitionSize];
    }
}


//| ----------------------------------------------------------------------------
//! Updates the receiver's preferredContentSize based on the verticalSizeClass
//! of the provided \a traitCollection.
//
- (void)updatePreferredContentSizeWithTraitCollection:(UITraitCollection *)traitCollection
{
    //traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 270 : 420
    //这里判断是否为iPhone横屏放置,是就是设置为270,否则为420
//    self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 270 : 420);
    
    //现在改成当前UITraitCollection的高度的0.7,现在已经调整成功,
    //需要注意的是,初始化视图控制器时的size以及放置方向需要记录下来,以后要进行size变换
    //竖直放置时:需要判断verticalSizeClass是否等于Compact,因为此时为水平放置,需要将transitionSize宽高进行调换
    //水平放置时:需要判断verticalSizeClass是否不等于Compact,此时为水平状态,不需要进行调换,其他状态才需要调换.
    CGSize size = transitionSize;
    NSLog(@"first:%@", NSStringFromCGSize(size));
    size = isFirstPortrait ? (traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? CGSizeMake(size.height, size.width) : size) : (traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact ? CGSizeMake(size.height, size.width) : size);
    NSLog(@"second:%@", NSStringFromCGSize(size));
 
    [self changelSliderValueWithSize:size];
}

- (void)changelSliderValueWithSize:(CGSize)size {
    // To demonstrate how a presentation controller can dynamically respond
    // to changes to its presented view controller's preferredContentSize,
    // this view controller exposes a slider.  Dragging this slider updates
    // the preferredContentSize of this view controller in real time.
    //
    // Update the slider with appropriate min/max values and reset the
    // current value to reflect the changed preferredContentSize.
    //    self.slider.maximumValue = self.preferredContentSize.height;
    //    self.slider.minimumValue = 220.f;
    self.slider.maximumValue = size.height * 0.7;
    self.slider.minimumValue = size.height * 0.45;
    //设置保存好的位置,不要在发生设备方向变化时又重置,并且需要重新设置preferredContentSize的高度
    self.slider.value = currentValue ? self.slider.maximumValue * currentValue.floatValue : self.slider.maximumValue;
    self.preferredContentSize = CGSizeMake(size.width, self.slider.value);
    NSLog(@"third:%@", NSStringFromCGSize(self.preferredContentSize));
}

//| ----------------------------------------------------------------------------
- (IBAction)sliderValueChange:(UISlider*)sender
{
    self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, sender.value);
    currentValue = @(sender.value / sender.maximumValue);
}

#pragma mark -
#pragma mark Unwind Actions

//| ----------------------------------------------------------------------------
//! Action for unwinding from the presented view controller (C).
//
- (IBAction)unwindToCustomPresentationSecondViewController:(UIStoryboardSegue *)sender
{ }

@end
