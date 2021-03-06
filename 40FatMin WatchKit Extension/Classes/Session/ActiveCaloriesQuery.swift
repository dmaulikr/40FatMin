//
//  ActiveCaloriesQuery.swift
//  40FatMin
//
//  Created by Vadym on 1412//16.
//  Copyright © 2016 Vadym Mitin. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit

class ActiveCaloriesQuery{
    
    // MARK: - Public Properties
    
    var updateHandler: ((_ value: Double) -> Void)?
    var errorHandler: ((_ error: Error) -> Void)?
    
    private(set) var totalValue = 0.0
    
    // MARK: - Public Methods
    
    func start(_ sessionStartDate: Date){
        initQuery(sessionStartDate)
    }
    
    func stop(){
        if let query = query{
            healthStore.stop(query)
            self.query = nil
        }
    }
    
    func reset(){
        // do nothing
    }
    
    // MARK: - Private Properties
    
    fileprivate let unit = HKUnit(from: "kcal")
    fileprivate var query: HKAnchoredObjectQuery?
    
    // MARK: - Private Computed Properties
    
    fileprivate var healthStore: HKHealthStore{
        get{
            return ((WKExtension.shared().delegate as? ExtensionDelegate)?.healthStore)!
        }
    }
    
    // MARK: - Private Methods
    
    fileprivate func initQuery(_ sessionStartDate: Date){
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            return
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: sessionStartDate, end: nil, options: .strictEndDate )
        
        self.query = HKAnchoredObjectQuery(type: quantityType,
                                           predicate: datePredicate,
                                           anchor: nil,
                                           limit: HKObjectQueryNoLimit)
        { [unowned self] (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            self.updateActiveCalories(sampleObjects, error)
        }
        
        self.query!.updateHandler = { [unowned self] (query, samples, deleteObjects, newAnchor, error) -> Void in
            self.updateActiveCalories(samples, error)
        }
        
        healthStore.execute(query!)
    }
    
    fileprivate func updateActiveCalories(_ samples: [HKSample]?, _ error: Error?){
        guard error == nil else{
            print("Heart rate update error: \(error!.localizedDescription)")
            
            errorHandler?(error!)
            
            return
        }
        
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        
        guard let sample = heartRateSamples.first else{
            return
        }
        
        self.totalValue += sample.quantity.doubleValue(for: self.unit)
        
        print("Active calories: \(String(format: "%.1f", self.totalValue))")
        
        self.updateHandler?(self.totalValue)
    }
}
