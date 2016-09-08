//
//  SSWAnimator.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SSWAnimator.h"

UIViewAnimationOptions const SSWNavigationTransitionCurve = 7 << 16;


@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 4.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowOpacity = 0.2f;

    // fade shadow during transition
    CGFloat toValue = 0.0f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = @(self.layer.shadowOpacity);
    animation.toValue = @(toValue);
    [self.layer addAnimation:animation forKey:nil];
    self.layer.shadowOpacity = toValue;
}
@end


@interface SSWAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@end

@implementation SSWAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Approximated lengths of the default animations.
    return [transitionContext isInteractive] ? 0.35f : 0.25f;
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];

    // add a shadow on the left side of the frontmost view controller
    [fromViewController.view addLeftSideShadowWithFading];
    BOOL previousClipsToBounds = fromViewController.view.clipsToBounds;
    fromViewController.view.clipsToBounds = NO;

    // fix hidesBottomBarWhenPushed not animated properly
    UITabBarController *tabBarController = toViewController.tabBarController;
    UINavigationController *navController = toViewController.navigationController;
    UITabBar *tabBar = tabBarController.tabBar;
    BOOL shouldAddTabBarBackToTabBarController = NO;

    BOOL tabBarControllerContainsToViewController = [tabBarController.viewControllers containsObject:toViewController];
    BOOL tabBarControllerContainsNavController = [tabBarController.viewControllers containsObject:navController];
    BOOL isToViewControllerFirstInNavController = [navController.viewControllers firstObject] == toViewController;
    if (tabBar && (tabBarControllerContainsToViewController || (isToViewControllerFirstInNavController && tabBarControllerContainsNavController))) {
        [tabBar.layer removeAllAnimations];
        
        CGRect tabBarRect = tabBar.frame;
        tabBarRect.origin.x = toViewController.view.bounds.origin.x;
        tabBar.frame = tabBarRect;
        
        [[transitionContext containerView] insertSubview:tabBar aboveSubview:toViewController.view];
        shouldAddTabBarBackToTabBarController = YES;
    }

    // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
    UIViewAnimationOptions curveOption = UIViewAnimationOptionCurveEaseOut;
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:curveOption animations:^{
        fromViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0);

    } completion:^(BOOL finished) {
        if (shouldAddTabBarBackToTabBarController) {
            [tabBarController.view addSubview:tabBar];
            
            CGRect tabBarRect = tabBar.frame;
            tabBarRect.origin.x = tabBarController.view.bounds.origin.x;
            tabBar.frame = tabBarRect;
        }

        fromViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.clipsToBounds = previousClipsToBounds;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];

    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        self.toViewController.view.transform = CGAffineTransformIdentity;
    }
}

@end
