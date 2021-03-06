//
//  ViewController.swift
//  WhatFlower-iOS13
//
//  Created by Alex 6.1 on 9/13/20.
//  Copyright © 2020 aglegaspi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import Lottie

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet private var animationView: AnimationView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startAnimation()
        setupImagePicker()
    }
    
    func startAnimation() {
        
        
        let flowerAnimation = Animation.named("21405-flower")
        animationView.animation = flowerAnimation
        animationView.loopMode = .loop
        animationView.play()
        
        
        
        
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
        animationView.isHidden = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            //imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else { fatalError("Could not convert to CIIMage") }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        // A container for a Core ML model used with Vision requests.
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Could not load the Flower Classifier Model")
        }
        
        // An image analysis request that uses a Core ML model to process images.
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed To Process Image")
            }
            
            if let firstResult = results.first {
                self.requestWiki(flowerName: firstResult.identifier)
                self.navigationItem.title = firstResult.identifier.capitalized
            } else {
                self.navigationItem.title = "Could Not Identify"
            }
            
        }
        
        // An object that processes one or more image analysis requests pertaining to a single image.
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("Could Not Perform Vision Request -- \(error)")
        }
    }
    
    func requestWiki(flowerName: String) {
        let wikipediaURL = "https://en.wikipedia.org/w/api.php"
        
        let parameters : [String : String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.data != nil {
                let result: JSON = JSON(response.value!)
                print(result)
                let pageid = result["query"]["pageids"][0].stringValue
                
                let flowerDescription = result["query"]["pages"][pageid]["extract"].stringValue
                self.descriptionLabel.text = flowerDescription
                
                let flowerImageURL = result["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL), completed: nil)
                
            }
        }
    }
}

