/*
 *  MaplyDoubleTapDragDelegate.h
 *
 *
 *  Created by Steve Gifford on 2/7/14.
 *  Copyright 2011-2017 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <Foundation/Foundation.h>
#import "MapView_iOS.h"
#import "MaplyZoomGestureDelegate.h"

// Sent out when the double tap delegate takes control
#define kMaplyDoubleTapDragDidStart @"WKMaplyDoubleTapDragStarted"
// Sent out when the double tap delegate finished (but hands off to momentum)
#define kMaplyDoubleTapDragDidEnd @"WKMaplyDoubleTapDragEnded"

@interface MaplyDoubleTapDragDelegate : MaplyZoomGestureDelegate

/// Create a 2 finger tap gesture and a delegate and wire them up to the given UIView
+ (MaplyDoubleTapDragDelegate *)doubleTapDragDelegateForView:(UIView *)view mapView:(Maply::MapView_iOS *)mapView;

@end
