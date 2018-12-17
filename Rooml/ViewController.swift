//
//  ViewController.swift
//  Rooml
//
//  Created by Christian Aranda on 13/12/2018.
//  Copyright © 2018 We Are Mobile First. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

/*
View controller for selecting images and applying Vision + Core ML processing.
*/

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var correctedImageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!

    lazy var classificationRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: ImageClassifier().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()


    @IBAction func takePicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        present(picker, animated: true)
    }
    @IBAction func chooseImage(_ sender: Any) {
        // The photo library is the default source, editing not allowed
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true)
    }

    var inputImage: CIImage! // The image to be processed.

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        classificationLabel.text = "Analyzing Image…"
        correctedImageView.image = nil

        guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            else { fatalError("no image from image picker") }
        guard let ciImage = CIImage(image: uiImage)
            else { fatalError("can't create CIImage from UIImage") }
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        inputImage = ciImage.oriented(forExifOrientation: (Int32(orientation.rawValue)))

        // Show the image in the UI.
        imageView.image = uiImage

        // Run the ML classifier.
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation:orientation)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print(error)
            }
        }
    }

    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first
            else { fatalError("can't get best result") }

        DispatchQueue.main.async {
            self.classificationLabel.text = "Classification: \"\(best.identifier)\" Confidence: \(best.confidence)"
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
