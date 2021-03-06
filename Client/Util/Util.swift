//
//  Styling.swift
//  Client
//
//  Created by Jordan Campbell on 16/01/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit
import SwiftyJSON

var DEBUG = false

// default to [0.0, 1.0]
func randomFloat() -> Float {
    return (Float(arc4random()) / 0xFFFFFFFF)
}

func randomFloat(min: Float, max: Float) -> Float {
    return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
}

func randomPosition() -> SCNVector3 {
    
    let x = randomFloat(min: -2.0, max: 2.0)
    let y = randomFloat(min: -2.0, max: 2.0)
    let z = Float(-1.0) // keep everything on the plane for now
    
    let position = SCNVector3Make(x, y, z)
    
    return position
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIImage {
    class func imageWithLabel(label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
    
    class func imageWithTextView(textView: UITextView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(textView.bounds.size, false, 0.0)
        textView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}

let burntOrange = UIColor(red: 0xF5, green: 0x5D, blue: 0x3E)
let palatinatePurple = UIColor(red: 0x68, green: 0x2D, blue: 0x63)
let tealBlue = UIColor(red: 0x38, green: 0x86, blue: 0x97)
let zeroColor = UIColor(red: 0x00, green: 0x00, blue: 0x00).withAlphaComponent(CGFloat(0.0))

func parseResponseToDict(_ input: Data) -> [String : NSDictionary]? {
    do {
        let output = try JSONSerialization.jsonObject(with: input, options: []) as? [String : NSDictionary]
        return output
    } catch let error {
        print("ERROR: ", error)
    }
    return [:]
}

func parseHREFFromURL(_ url: String) -> String {

    var startIndex = url.index(of: "(") ?? url.endIndex
    startIndex = url.index(after: startIndex)
    startIndex = url.index(after: startIndex)
    
    var endIndex = url.index(of: ")") ?? url.endIndex
    endIndex = url.index(before: endIndex)
    
    let output = url[startIndex..<endIndex]
    return String(output)
}

func distance(_ p1: SCNVector3, _ p2: SCNVector3) -> Double {
    return Double(sqrt( pow((p1.x - p2.x), 2.0) + pow((p1.y - p2.y), 2.0) + pow((p1.z - p2.z), 2.0) ))
}


//extension code starts
// https://stackoverflow.com/a/42941966/7098234
func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
    
}

// https://stackoverflow.com/a/42941966/7098234
extension SCNNode {
    
    func buildLineInTwoPointsWithRotation(from  startPoint: SCNVector3,
                                          to    endPoint: SCNVector3,
                                          radius: CGFloat,
                                          lengthOffset: CGFloat,
                                          color: UIColor) -> SCNNode {
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = startPoint
            return self
            
        }
        
        let cyl = SCNCylinder(radius: radius, height: (l - lengthOffset))
        cyl.firstMaterial?.diffuse.contents = color
        
        self.geometry = cyl
        
        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                            (endPoint.z-startPoint.z)/2.0)
        
        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
        
        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = Float(av_normalized.x) // x' * sin(angle/2)
        let q2 = Float(av_normalized.y) // y' * sin(angle/2)
        let q3 = Float(av_normalized.z) // z' * sin(angle/2)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0
        
        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0
        
        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0
        
        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
        return self
    }
}


func resizeImage(image: UIImage, newSize: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(newSize)
    image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.width) )
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}

func exit() {
    exit(EXIT_SUCCESS)
}


func urlToID(_ input: String) -> String {
    var output = String(input)
    
    var charsToReplace: [String] = ["http", "https", "www", ".", "/", "%", "&", ":"]
    for value in charsToReplace {
        output = output.replacingOccurrences(of: value, with: "")
    }
    
    return output
}




extension String {
    
    func sliceWithin(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func sliceWithLower(from: String, to: String) -> String? {
        return (range(of: from)?.lowerBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
}






extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

func indexFromKey(_ key: String) -> Int {
    
    let startIndex = key.startIndex
    let endIndex = key.index(of: "-") ?? key.endIndex
    
    let index = String( key[startIndex..<endIndex] )
    return Int(index)!
}



func pointOnCircle(_ radius: Float, _ Bx: Float, _ Ax: Float, _ By: Float, _ Ay: Float) -> CGPoint {
    
    let denom: Float = sqrtf((Bx - Ax) * (Bx - Ax)) + ((By - Ay) * (By - Ay))
    
    let x = Ax - (radius * ((Bx - Ax) / denom ))
    let y = Ay - (radius * ((By - Ay) / denom ))
    
    return CGPoint(x: CGFloat(x), y: CGFloat(y))
}


func createNode(withGeometry type: String) -> SCNNode {
    
    var geometry: SCNGeometry
    let nodeSize = 0.01
    
    switch type {
    case "sphere":
        geometry = SCNSphere(radius: CGFloat(nodeSize))
    case "cube":
        geometry = SCNBox(width: CGFloat(nodeSize),
                          height: CGFloat(nodeSize),
                          length: CGFloat(nodeSize),
                          chamferRadius: CGFloat(nodeSize*0.1))
    case "plane":
        geometry = SCNPlane(width: CGFloat(nodeSize),
                            height: CGFloat(nodeSize))
    default:
        geometry = SCNSphere(radius: CGFloat(nodeSize))
    }
    
    geometry.firstMaterial?.diffuse.contents = UIColor.magenta
    geometry.firstMaterial?.transparency = CGFloat(0.5)
    
    let node = SCNNode(geometry: geometry)
    
    return node
    
}


let performance = PerformanceMeasure()

func extractValuesFromCSV(_ _input: String) -> [Float] {
    var input = _input
    
    if input.count == 1 {
        let output = input.replacingOccurrences(of: "[a-z]", with: "",  options: NSString.CompareOptions.regularExpression, range: nil)
        if output != "" {
            return [Float(output)!]
        } else {
            return []
        }
    }
    
    if !input.hasPrefix("(") {
        input = "(" + input
    }
    
    let startIndex = input.index(after:  input.index(of:"(") ?? input.startIndex)
    let endIndex   = input.index(before: input.index(of:")") ?? input.endIndex)
    
    let values = (input[startIndex ... endIndex])
                    .replacingOccurrences(of: ",", with: " ")
                    .replacingOccurrences(of: " .[0-9]", with: "")
                    .replacingOccurrences(of: "[a-z]", with: "",  options: NSString.CompareOptions.regularExpression, range: nil)
                    .split(separator: " ")
                    .map {Float($0)!}
    return values
}

func matches(for regex: String, in text: String) -> [String] {

    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}






// end
