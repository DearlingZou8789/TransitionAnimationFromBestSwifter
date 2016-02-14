/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A custom storyboard segue that loads its destination view controller from an
 external storyboard (named by the segue's identifier), then presents it 
 modally.
 */

#import "AAPLExternalStoryboardSegue.h"

//  NOTE: iOS 9 introduces storyboard references which allow a segue to
//        target the initial scene in an external storyboard.  If your
//        application targets iOS 9 and above, you should use storyboard
//        references rather than the technique shown here.

@implementation AAPLExternalStoryboardSegue

//|----------------------------------------------------------------------------这里采用多个storyboard分别架构不同转场类型，这对于大型项目来说，比较方便，以后要学会使用storyBoard进行项目架构，方便实用，这里需要注意了，UIStoryBoardSegue是故事板转场对象，先要取得故事版，然后获取到故事版中的初始化视图控制器，然后将视图控制器连成一张链表，就是整个项目的流程

//
- (instancetype)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
{
    // Load the storyboard named by this segue's identifier.
    UIStoryboard *externalStoryboard = [UIStoryboard storyboardWithName:identifier bundle:[NSBundle bundleForClass:self.class]];
    
    // Instantiate the storyboard's initial view controller.
    id initialViewController = [externalStoryboard instantiateInitialViewController];
    
    return [super initWithIdentifier:identifier source:source destination:initialViewController];
}


//| ----------------------------------------------------------------------------
- (void)perform
{
    [self.sourceViewController presentViewController:self.destinationViewController animated:YES completion:NULL];
}

@end
