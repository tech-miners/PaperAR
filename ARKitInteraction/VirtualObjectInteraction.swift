/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates movement and gesture interactions with virtual objects.
*/

import UIKit
import ARKit

/// - Tag: VirtualObjectInteraction
class VirtualObjectInteraction: NSObject, UIGestureRecognizerDelegate {
    /// Developer setting to translate assuming the detected plane extends infinitely.
    let translateAssumingInfinitePlane = true
    
    /// The scene view to hit test against when moving virtual content.
    let sceneView: VirtualObjectARView
    
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    var selectedObject: VirtualObject?
    
    var target : VirtualObject!
    
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: VirtualObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
            //print("Tracking variable:" + String(describing: selectedObject))
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?

    init(sceneView: VirtualObjectARView) {
        self.sceneView = sceneView
        super.init()
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        // Add gestures to the `sceneView`.
        print("Setting VirtualObject interactions")
        sceneView.addGestureRecognizer(panGesture)
        //sceneView.addGestureRecognizer(rotationGesture)
        //sceneView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Actions
    
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for interaction with a new object.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                if (object.modelName == "target")
                {
                    break;
                }
                trackedObject = object
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)
            
            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            
            // The `currentTrackingPosition` is used to update the `selectedObject` in `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)

            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
            break
            
        default:
            // Clear the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }

    /**
     If a drag gesture is in progress, update the tracked object's position by
     converting the 2D touch location on screen (`currentTrackingPosition`) to
     3D world space.
     This method is called per frame (via `SCNSceneRendererDelegate` callbacks),
     allowing drag gestures to move virtual objects regardless of whether one
     drags a finger across the screen or moves the device through space.
     - Tag: updateObjectToCurrentTrackingPosition
     */
    var paths = [VirtualObject: LinkedList]()
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else { return }
        
        if let path = paths[object] {
            path.append(value:position)
        } else {
            let newList = LinkedList()
            newList.append(value:position)
            paths[object] = newList
        }
        
        for (object, path) in paths {
            let nextPos = path.first?.value
            
            if let pos = nextPos {
                translate(object, basedOn: pos, infinitePlane: translateAssumingInfinitePlane)
            }
            
            
        }
        //translate(object, basedOn: position, infinitePlane: translateAssumingInfinitePlane)
        //print("Hiding drag")
    }
    
    func movePlane(plane: VirtualObject) {
        //var targPos : SCNVector3 = SCNVector3(0.01,0.01,0.01)
        var targPos : SCNVector3 = SCNVector3(target.position.x, target.position.y,target.position.z)
        //var targPosFloat3 : float3
        if let path = paths[plane] {
            //targPos = translate(path.first)
            //targPosFloat3 = float3(x:0.01, y:0.01, z:0.01)
        } else {
            //targPosFloat3 = float3(x:target.position.x+0.01, y:target.position.y+0.01, z:target.position.z+0.01)
            //targPos = target.position
            targPos = SCNVector3(target.position.x, target.position.y,target.position.z)
        }
        let direction : SCNVector3 = getDirection(source: plane.position, target: target.position)
        plane.position.x = plane.position.x + direction.x
        plane.position.y = plane.position.y + direction.y
        plane.position.z = plane.position.z + direction.z
        //plane.setPosition(targPosFloat3, relativeTo: relTo, smoothMovement: true);
        //let nPos = float3(x:targPos.x ,y:targPos.y ,z:targPos.z);
        //let nPos = targPos
        //let tmpF = float4(0,0,0,0);
        //let relTo = matrix_float4x4(tmpF,tmpF,tmpF,tmpF);
//        plane.setPosition(targPosFloat3, relativeTo: relTo, smoothMovement: true);
        print("Plane x position" + plane.position.x.debugDescription)
        print("Plane y position" + plane.position.y.debugDescription)
        print("Plane z position" + String(plane.position.z))
        print("target x position" + target.position.x.debugDescription)
        print("target y position" + target.position.y.debugDescription)
        print("target z position" + target.position.z.debugDescription)
        
    }
    
    func getDirection(source : SCNVector3, target : SCNVector3) -> SCNVector3 {
        let velocity = 0.001
        var tmp = target.x - source.x
        let x = (tmp) >= 0 ? tmp : -tmp
        tmp = target.y - source.y
        let y = (tmp) >= 0 ? tmp : -tmp
        tmp = target.z - source.z
        let z = (tmp) >= 0 ? tmp : -tmp
        /*var x = (tmp) >= 0 ? velocity : -velocity
        if tmp == 0{
            x = 0
        }
        tmp = target.y - source.y
        var y = (tmp) >= 0 ? velocity : -velocity
        if tmp == 0{
            y = 0
        }
        tmp = target.z - source.z
        var z = (tmp) >= 0 ? velocity : -velocity
        if tmp == 0{
            z = 0
        }*/
        //print("X IS " + x.debugDescription)
        let divis = normalize(float3(x, y, z)) / (Float(velocity))
        //let divis = (Double) pow(x, 2) + pow(y, 2) + pow(z, 2)
        let tmp2 = abs(divis)
        //print("divis is: " + divis.debugDescription)
        let vel = vector3 (x, y, z) / tmp2
        print("vel: " + vel.debugDescription)
        //let vel = SCNVector3(x/tmp2, y/tmp2, z/tmp2)
        //print("Plane moving to: " + vel.debugDescription)
        
        return SCNVector3(-vel.x, -vel.y, -vel.z)
        //return SCNVector3(x, y, z)
    }

    /// - Tag: didRotate
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        /*
         - Note:
          For looking down on the object (99% of all use cases), we need to subtract the angle.
          To make rotation also work correctly when looking from below the object one would have to
          flip the sign of the angle depending on whether the object is above or below the camera...
         */
        trackedObject?.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        if let tappedObject = sceneView.virtualObject(at: touchLocation) {
            // Select a new object.
            selectedObject = tappedObject
        } else if let object = selectedObject {
            // Teleport the object to whereever the user touched the screen.
            translate(object, basedOn: touchLocation, infinitePlane: false)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> VirtualObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.virtualObject(at: touchLocation) {
                return object
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        return sceneView.virtualObject(at: gesture.center(in: view))
    }
    
    // MARK: - Update object position

    /// - Tag: DragVirtualObject
    private func translate(_ object: VirtualObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        
        /*
         Plane hit test results are generally smooth. If we did *not* hit a plane,
         smooth the movement to prevent large jumps.
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
}

/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}
