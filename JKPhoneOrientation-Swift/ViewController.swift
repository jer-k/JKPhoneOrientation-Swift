//
//  ViewController.swift
//  JKPhoneOrientation-Swift
//
//  Created by Jeremy Kreutzbender on 7/15/14.
//  Copyright (c) 2014 Jeremy Kreutzbender. All rights reserved.
//

import UIKit
import CoreMotion

enum PhoneOrientation {
    case PhoneOrientationPortrait, PhoneOrientationLandscapeLeft, PhoneOrientationLandscapeRight, PhoneOrientationPortraitUpsideDown, PhoneOrientationUnknown
    
    func simpleDescription() -> String {
        switch self {
        case .PhoneOrientationPortrait:
            return "Portrait"
        case .PhoneOrientationLandscapeLeft:
            return "LandscapeLeft"
        case .PhoneOrientationLandscapeRight:
            return "LandscapeRight"
        case .PhoneOrientationPortraitUpsideDown:
            return "PortraitUpsideDown"
        default:
            return "Unknown"
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet var orientationDescriptionLabel: UILabel
    @IBOutlet var currentOrientationLabel: UILabel
    @IBOutlet var angleDescriptionLabel: UILabel
    @IBOutlet var currentAngleLabel: UILabel
    
    let kfilteringFactor = 0.1
    
    var phoneOrientation = PhoneOrientation.PhoneOrientationUnknown
    
    let motionManager = CMMotionManager()
    let motionQueue = NSOperationQueue()
    
    var accelerationX = 0.0
    var accelerationY = 0.0
    var accelerationZ = 0.0
    var phoneAngle = 0.0
    
    var currentOrientationLabelOriginalRect: CGRect!
    var currentAngleLabelOriginalRect: CGRect!
    var orientationDescriptionLabelOriginalRect: CGRect!
    var angleDescriptionLabelOriginalRect: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Save the rects of the labels so we can return them back to the correct position later
        currentOrientationLabelOriginalRect = currentOrientationLabel.frame
        currentAngleLabelOriginalRect = currentAngleLabel.frame
        orientationDescriptionLabelOriginalRect = orientationDescriptionLabel.frame
        angleDescriptionLabelOriginalRect = angleDescriptionLabel.frame
        
        motionManager.accelerometerUpdateInterval = 0.03
        motionManager.startAccelerometerUpdatesToQueue(motionQueue) { accelerometerData, error in
            self.accelerationX = (accelerometerData.acceleration.x * self.kfilteringFactor + self.accelerationX * (1.0 - self.kfilteringFactor))
            self.accelerationY = (accelerometerData.acceleration.y * self.kfilteringFactor + self.accelerationY * (1.0 - self.kfilteringFactor))
            self.accelerationZ = (accelerometerData.acceleration.y * self.kfilteringFactor + self.accelerationZ * (1.0 - self.kfilteringFactor))
            
            self.phoneAngle = (atan2(self.accelerationY, self.accelerationX)) * 180/M_PI;
            
            dispatch_async(dispatch_get_main_queue()) {
                self.currentAngleLabel.text = "\(self.phoneAngle)"
            }
            if self.accelerationZ <= -0.05 || self.accelerationZ > 0.05 {
                self.rotateForAngle(self.phoneAngle)
            }
        }
    }
    
    func isOrientationLandscapeRight(angle : Double) -> Bool {
        return angle >= -45 && angle <= 45.0
    }
    
    func isOrientationLandscapeLeft(angle : Double) -> Bool {
        return (angle <= -135.1 && angle >= -180.0) || (angle >= 135.1 && angle <= 180.0)
    }
    
    func isOrientationPortrait(angle: Double) -> Bool {
        return angle <= -45.1 && angle >= -135.0
    }
    
    func isOrientationPortraitUpsideDown(angle : Double) -> Bool {
        return angle <= 135.0 && angle >= 45.1
    }
    
    func rotateForAngle(angle : Double) {
        if isOrientationPortrait(angle) {
            
            /* Since this method is being triggered every 0.03 seconds, we want to check to see if the phone is in a consistent orientation
            * There is no reason to perform the work on the elements if no rotation is occuring */
            if phoneOrientation != PhoneOrientation.PhoneOrientationPortrait {
                
                // Set the orientation to avoid re-entrance into the block the next time this method is triggered
                phoneOrientation = PhoneOrientation.PhoneOrientationPortrait
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIView.animateWithDuration(0.2,
                        animations: {
                            // Rotate the description labels; they stay in place
                            self.orientationDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0))
                            self.angleDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0))
                            
                            /* The currentOrientation and currentAngle's rects are saved in portrait mode
                            * so we will rotate them back to portrait and then move the frame back to its original location */
                            self.currentOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0))
                            self.currentOrientationLabel.frame = self.currentOrientationLabelOriginalRect
                            
                            self.currentAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(0 * M_PI/180.0))
                            self.currentAngleLabel.frame = self.currentAngleLabelOriginalRect
                        },
                        completion: { complete in
                            self.currentOrientationLabel.text = self.phoneOrientation.simpleDescription()
                        })
                    }
            }
            
        }
        else if isOrientationLandscapeRight(angle) {
            if phoneOrientation != PhoneOrientation.PhoneOrientationLandscapeRight {
                phoneOrientation = PhoneOrientation.PhoneOrientationLandscapeRight
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIView.animateWithDuration(0.2,
                        animations: {
                            self.orientationDescriptionLabel.transform = CGAffineTransformMakeRotation(CGFloat(-90 * M_PI/180.0))
                            self.angleDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0))
                            
                            /* When currentOrientationLabel and currentAngleLabel are rotated to landscape mode we must move them first and
                            * align them with the location of the description labels using the saved portrait rects
                            * Then we are able to rotate and have correct alignment */
                            self.currentOrientationLabel.frame = CGRectMake(self.orientationDescriptionLabelOriginalRect.origin.x + self.orientationDescriptionLabelOriginalRect.size.height + 10,
                                self.orientationDescriptionLabelOriginalRect.origin.y,
                                self.currentOrientationLabel.frame.size.width,
                                self.currentOrientationLabel.frame.size.height);
                            self.currentOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0))
                            
                            
                            
                            self.currentAngleLabel.frame = CGRectMake(self.angleDescriptionLabelOriginalRect.origin.x + self.angleDescriptionLabelOriginalRect.size.height + 10,
                                self.angleDescriptionLabelOriginalRect.origin.y,
                                self.currentAngleLabel.frame.size.width,
                                self.currentAngleLabel.frame.size.height);
                            self.currentAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(-90 * M_PI/180.0))
                        },
                        completion: { complete in
                            self.currentOrientationLabel.text = self.phoneOrientation.simpleDescription()
                        })
                }
            }
        }
        else if isOrientationPortraitUpsideDown(angle) {
            if phoneOrientation != PhoneOrientation.PhoneOrientationPortraitUpsideDown {
                phoneOrientation = PhoneOrientation.PhoneOrientationPortraitUpsideDown
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIView.animateWithDuration(0.2,
                        animations: {
                            self.orientationDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0))
                            self.angleDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0))
                            
                            self.currentOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0))
                            self.currentOrientationLabel.frame = self.currentOrientationLabelOriginalRect
                            
                            self.currentAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(180 * M_PI/180.0))
                            self.currentAngleLabel.frame = self.currentAngleLabelOriginalRect
                        },
                        completion: { complete in
                            self.currentOrientationLabel.text = self.phoneOrientation.simpleDescription()
                        })
                }
            }
        }
        else if isOrientationLandscapeLeft(angle) {
            if phoneOrientation != PhoneOrientation.PhoneOrientationLandscapeLeft {
                phoneOrientation = PhoneOrientation.PhoneOrientationLandscapeLeft
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIView.animateWithDuration(0.2,
                        animations: {
                            self.orientationDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0))
                            self.angleDescriptionLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0))
                            
                            self.currentOrientationLabel.frame = CGRectMake(self.orientationDescriptionLabelOriginalRect.origin.x - self.orientationDescriptionLabelOriginalRect.size.height - 10,
                                self.orientationDescriptionLabelOriginalRect.origin.y,
                                self.currentOrientationLabel.frame.size.width,
                                self.currentOrientationLabel.frame.size.height)
                            self.currentOrientationLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0))
                            
                            
                            self.currentAngleLabel.frame = CGRectMake(self.angleDescriptionLabelOriginalRect.origin.x - self.angleDescriptionLabelOriginalRect.size.height - 10,
                                self.angleDescriptionLabelOriginalRect.origin.y,
                                self.currentAngleLabel.frame.size.width,
                                self.currentAngleLabel.frame.size.height)
                            self.currentAngleLabel.transform = CGAffineTransformMakeRotation((CGFloat)(90 * M_PI/180.0))
                        },
                        completion: { complete in
                            self.currentOrientationLabel.text = self.phoneOrientation.simpleDescription()
                        })
                }
            }
        }
    }
}
