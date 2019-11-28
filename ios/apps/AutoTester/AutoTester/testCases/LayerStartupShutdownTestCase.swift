//
//  LayerStartupShutdownTestCase.swift
//  AutoTester
//
//  Created by Steve Gifford on 10/30/19.
//  Copyright © 2019 mousebird consulting. All rights reserved.
//

import UIKit

class LayerStartupShutdownTestCase: MaplyTestCase {

    override init() {
        super.init()

        self.name = "Repeated Layer Startup/Shutdown"
        self.captureDelay = 4
        self.implementations = testCase.implementations
    }
    
//    var testCase = StamenWatercolorRemote()
//    var testCase = GeographyClassTestCase()
    var testCase = VectorMBTilesTestCase()

    func startGlobeLayer() {
        self.testCase.setUpWithGlobe(self.globeViewController!)

        // Shut it down in a bit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.stopGlobeLayer()
        }
    }
    
    func stopGlobeLayer() {
        self.testCase.tearDown(withGlobe: self.globeViewController!)

        // Start it back up again in a bit
        // Note: Check to see if we're still valid here
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startGlobeLayer()
        }
    }
    
    func startMapLayer() {
        self.testCase.setUpWithMap(self.mapViewController!)

        // Shut it down in a bit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.stopMapLayer()
        }
    }
    
    func stopMapLayer() {
        self.testCase.tearDown(withMap: self.mapViewController!)
        
        // Start it back up again in a bit
        // Note: Check to see if we're still valid here
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startMapLayer()
        }
    }

    // We need to create the globe controller ourselves so we can shut it down
    override func runGlobeTest(withLock lock: DispatchGroup) {
        globeViewController = WhirlyGlobeViewController()
        baseViewController = globeViewController
        testView?.addSubview(globeViewController!.view)
        globeViewController!.view.frame = testView!.bounds
        globeViewController!.delegate = self
        // Note: Should also be adding as a child of the view controller

        startGlobeLayer()
    }
    
    // Likewise for the map
    override func runMapTest(withLock lock: DispatchGroup) {
        mapViewController = MaplyViewController()
        baseViewController = mapViewController
        testView?.addSubview(mapViewController!.view)
        mapViewController!.view.frame = testView!.bounds
        mapViewController!.delegate = self
        // Note: Should also be adding as a child of the view controller
        
        startMapLayer()
    }

}
