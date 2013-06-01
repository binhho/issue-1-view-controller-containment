//
//  RGViewController.m
//  RGContainmentViewController
//
//  Created by Ricki Gregersen on 5/22/13.
//  Copyright (c) 2013 Ricki Gregersen. All rights reserved.
//

#import "RGContainerViewController.h"
#import "RGMapViewController.h"
#import "RGGeoInfoViewController.h"

#import "CLLocation+Utilities.h"
#import "UIView+FLKAutoLayout.h"

#import <QuartzCore/QuartzCore.h>

@interface RGContainerViewController () {
    
//    NSLayoutConstraint *topMapYConstrain, *bottomMapYConstrain;
    RGMapStateModel *locationMapModel, *targetMapModel;
    BOOL isDisplayingMapView;
    UIView *topContainer;
    UIView *bottomContainer;
    UIButton *infoButton;
}

@property RGMapViewController *startMapViewController;
@property RGMapViewController *targetMapViewController;

@property RGGeoInfoViewController *startGeoViewController;
@property RGGeoInfoViewController *targetGeoViewController;

@end

@implementation RGContainerViewController

- (void) loadView
{
    UIView *view = [UIView new];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.backgroundColor = [UIColor darkGrayColor];
    
    topContainer = [UIView new];
    [topContainer setTranslatesAutoresizingMaskIntoConstraints:NO];    
    [view addSubview:topContainer];
    
    [topContainer constrainWidthToView:view predicate:nil];
    [topContainer constrainHeightToView:view predicate:@"*.4"];
    [topContainer alignTopEdgeWithView:view predicate:nil];
    [topContainer alignCenterXWithView:view predicate:nil];
    
    bottomContainer = [UIView new];
    [bottomContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [view addSubview:bottomContainer];
    
    [bottomContainer constrainWidthToView:view predicate:nil];
    [bottomContainer constrainHeightToView:view predicate:@"*.4"];
    [bottomContainer alignBottomEdgeWithView:view predicate:nil];
    [bottomContainer alignCenterXWithView:view predicate:nil];    

    infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [infoButton setBackgroundImage:[UIImage imageNamed:@"radar"] forState:UIControlStateNormal];
    [view addSubview:infoButton];
    
    [infoButton alignCenterXWithView:view predicate:nil];
    [infoButton alignCenterYWithView:view predicate:nil];
    
    [infoButton addTarget:self action:@selector(infoButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _startMapViewController = [RGMapViewController new];
    [_startMapViewController setAnnotationImagePath:@"man"];
    [self addChildViewController:_startMapViewController];
    [topContainer addSubview:_startMapViewController.view];
    [_startMapViewController didMoveToParentViewController:self];
    [_startMapViewController addObserver:self forKeyPath:@"currentLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    _startGeoViewController = [RGGeoInfoViewController new];
    
    
    _targetMapViewController = [RGMapViewController new];
    [_targetMapViewController setAnnotationImagePath:@"hole"];
    [self addChildViewController:_targetMapViewController];
    [bottomContainer addSubview:_targetMapViewController.view];
    [_targetMapViewController didMoveToParentViewController:self];
    [_targetMapViewController addObserver:self forKeyPath:@"currentLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    _targetGeoViewController = [RGGeoInfoViewController new];
    
    
    topContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    topContainer.layer.shadowRadius = 4.0f;
    topContainer.layer.shadowOpacity = 0.5f;
    topContainer.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    
    bottomContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    bottomContainer.layer.shadowRadius = 4.0f;
    bottomContainer.layer.shadowOpacity = 0.5f;
    bottomContainer.layer.shadowOffset = CGSizeMake(0.0f, -2.0f);
    
    isDisplayingMapView = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:56.55 longitude:8.316667];
    [_startMapViewController updateAnnotationLocation:initialLocation];
    [_targetMapViewController updateAnnotationLocation:[initialLocation antipode]];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)infoButtonHandler:(id)sender
{
    [infoButton setEnabled:NO];
    
    double delay = 0.2;
    UIViewAnimationOptions direction = UIViewAnimationOptionTransitionFlipFromTop;
    if (_startMapViewController.parentViewController == self) {
        
        [_startGeoViewController updateLocation:_startMapViewController.currentLocation];
        [_targetGeoViewController updateLocation:_targetMapViewController.currentLocation];
        
        [self flipFromViewController:_startMapViewController toViewController:_startGeoViewController usingContainer:topContainer withDirection:direction andDelay:0.0];
        [self flipFromViewController:_targetMapViewController toViewController:_targetGeoViewController usingContainer:bottomContainer withDirection:direction andDelay:delay];
        
    } else {
        
        direction = UIViewAnimationOptionTransitionFlipFromBottom;
        
        [self flipFromViewController:_startGeoViewController toViewController:_startMapViewController usingContainer:topContainer withDirection:direction andDelay:0.0];
        
        [self flipFromViewController:_targetGeoViewController toViewController:_targetMapViewController usingContainer:bottomContainer withDirection:direction andDelay:delay];
    }
}

- (void) flipFromViewController:(UIViewController*) fromController toViewController:(UIViewController*) toController usingContainer:(UIView*) container withDirection:(UIViewAnimationOptions) direction andDelay:(double) delay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);

    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        toController.view.frame = fromController.view.bounds;
        [toController.view layoutIfNeeded];
        
        [self addChildViewController:toController];
        [fromController willMoveToParentViewController:nil];
        
        [self transitionFromViewController:fromController
                          toViewController:toController
                                  duration:0.2
                                   options:direction | UIViewAnimationOptionCurveEaseIn
                                animations:nil
                                completion:^(BOOL finished) {
                                    
                                    [toController didMoveToParentViewController:self];
                                    [fromController removeFromParentViewController];
                                    [infoButton setEnabled:YES];
                                }];
    });
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentLocation"]) {
        
        RGMapViewController *oppositeController = nil;
        
        if ([object isEqual:_startMapViewController])
            oppositeController = _targetMapViewController;
        else
            oppositeController = _startMapViewController;
        
        CLLocation *newLocation = [change objectForKey:@"new"];
        [oppositeController updateAnnotationLocation:[newLocation antipode]];   
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
