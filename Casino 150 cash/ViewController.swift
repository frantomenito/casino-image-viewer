//
//  ViewController.swift
//  Casino 150 cash
//
//  Created by Dmytro Maksymyak on 26.07.2021.
//

import UIKit
import CSVImporter
import SwiftCSVExport

class ViewController: UIViewController {
    
    //MARK: Var's
    @IBOutlet weak var badButton: UIButton!
    @IBOutlet weak var gameNameLabel: UILabel!
    @IBOutlet weak var providerNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pippetButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    
    var imageScrollView = UIScrollView()
    var imageView = UIImageView()
    var progressView = UIProgressView()
    
    var games = [Game]()
    var headerValues = [String]()
    
    var semaphore = DispatchSemaphore(value: 1)
    var imageCacheSemaphore = DispatchSemaphore(value: 1)
    var cachedImage = UIImage()
    var editingEnabled = false
    
    var gameIndex = 0
    var wasEdited = false
    
    var panGesture = UIPanGestureRecognizer()
    var tapGesture = UITapGestureRecognizer()
    var previousTouch = CGPoint()
    var path = UIBezierPath()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commomInit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLoadingGames()
        createFolder(named: "Casino")
    }
    
    //MARK: Common init's
    
    func commomInit() {
        imageScrollView.delegate = self
        imageScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.height / 1.5, height: view.frame.height / 1.5)
        
        imageScrollView.alwaysBounceVertical = true
        imageScrollView.alwaysBounceHorizontal = true
        
        imageScrollView.showsVerticalScrollIndicator = false
        imageScrollView.showsHorizontalScrollIndicator = false
        
        imageScrollView.maximumZoomScale = 5
        imageScrollView.minimumZoomScale = 1
        imageScrollView.layer.borderWidth = 2
        imageScrollView.layer.borderColor = UIColor.gray.cgColor
        
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: imageScrollView.frame.width, height: imageScrollView.frame.height)
        imageView.image = UIImage(named: "noImage")!
        
        view.addSubview(imageScrollView)
        imageScrollView.addSubview(imageView)
        
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        imageScrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageScrollView.topAnchor.constraint(equalTo: providerNameLabel.bottomAnchor, constant: 10).isActive = true
        imageScrollView.widthAnchor.constraint(equalToConstant: view.frame.height / 1.5).isActive = true
        imageScrollView.heightAnchor.constraint(equalTo: imageScrollView.widthAnchor).isActive = true
        
        imageView.clipsToBounds = false
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(scrollViewPanned(sender:)))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(scrollViewGetTapped(sender:)))
    }
    
    func startLoadingGames() {
        DispatchQueue.global().async { [self] in
            print(games)
            for game in games {
                self.semaphore.wait()
                self.gameIndex += 1
                                
                if game.isOk == 1 {
                    let thisGameURL = game.gameLink
                    var nextGameURL: URL?
                    
                    if gameIndex != games.count {
                        nextGameURL = games[gameIndex].gameLink
                        print("Last game")
                    }
                    
                    self.downloadImage(imageURL: thisGameURL) { error, image in
                        if error == nil {
                            DispatchQueue.main.async {
                                imageView.image = image
                                imageScrollView.frame.size = imageView.frame.size
                            }
                        }
                    }
                    if let nextGameURL = nextGameURL {
                        cacheImage(imageURL: nextGameURL) { error in
                            if error != nil { print (error!)}
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.gameNameLabel.text = game.title
                        self.providerNameLabel.text = game.gameProvider
                        self.gameNameLabel.setNeedsFocusUpdate()
                    }
                } else {
                    self.semaphore.signal()
                }
            }
        }
    }
    
    //MARK: AlertView functions
    
    func showErrorAlertView(_ error: Error) {
        let alertView = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        present(alertView, animated: true) {
            
            let margin = 8.0
            let rect = CGRect(x: margin, y: 72.0, width: Double(alertView.view.frame.width) - margin * 2, height: 2)
            self.progressView = UIProgressView(frame: rect)
            self.progressView.progress = 0.5
            self.progressView.tintColor = self.view.tintColor
            alertView.view.addSubview(self.progressView)
            
        }
    }
    
    //MARK: Downloading and caching images
    
    func cacheImage(imageURL: URL, completion: @escaping (Error?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: imageURL) { (data, _, error) in
            DispatchQueue.global().async {
                guard let data = data else {
                    completion(error)
                    return
                }
                guard let cachedImage = UIImage(data: data) else {
                    print("Error caching image with URL: \(imageURL)")
                    return
                }
                
                self.cachedImage = cachedImage
                self.cachedImage.accessibilityIdentifier = imageURL.absoluteString
                completion(nil)
            }
        }
        dataTask.resume()
    }
    
    func downloadImage(imageURL: URL, completion: @escaping (Error?, UIImage) -> Void) {
        if cachedImage.accessibilityIdentifier != imageURL.absoluteString {
            DispatchQueue.global().async {
                let dataTask = URLSession.shared.dataTask(with: imageURL) { (data, _, error) in
                    guard let data = data, error == nil else {
                        let image = UIImage(named: "noImage")!
                        completion(error, image)
                        return
                    }
                    do {
                        var image: UIImage!
                        image = try UIImage(data: data)
                        
                        if image != nil {
                            completion(nil, image)
                        } else {
                            completion(error, UIImage(named: "noImage")!)
                        }
                    } catch let parseError {
                        let image = UIImage(named: "noImage")!
                        completion(parseError, image)
                        print("Error parsing")
                    }
                }
                dataTask.resume()
            }
        } else {
            let image = cachedImage
            completion(nil, image)
        }
        
    }
    
    //MARK: Exporting CSV file
    func createCSV(games: [Game], headerValues: [String]) {
        let data = NSMutableArray()
        for game in games {
            data.add(game.getDictionary())
        }
        let writeCSVObj = CSV()
        writeCSVObj.rows = data
        writeCSVObj.delimiter = DividerType.semicolon.rawValue
        writeCSVObj.fields = headerValues as NSArray
        writeCSVObj.name = "Casino games"
        
        let output = CSVExport.export(writeCSVObj);
        if output.result.isSuccess {
            guard let filePath =  output.filePath else {
                print("Export Error: \(String(describing: output.message))")
                return
            }
            
            print("File Path: \(filePath)")
        } else {
            print("Export Error: \(String(describing: output.message))")
        }
    }
    
    //MARK: Cropping image
    
    func croppedImage() -> UIImage {
        wasEdited = true
        let cropSize = imageScrollView.bounds.size
        let widthScale = (imageView.image?.size.width)! / imageView.frame.width
        let heightScale = (imageView.image?.size.height)! / imageView.frame.height
        
        let cropSizeScaled = CGSize(width: cropSize.width * widthScale, height: cropSize.height * widthScale)

        let r = UIGraphicsImageRenderer(size: cropSizeScaled)
        let x = -imageScrollView.contentOffset.x * widthScale
        let y = -imageScrollView.contentOffset.y * heightScale
        return r.image { _ in
            imageView.image!.draw(at: CGPoint(x: x, y: y))
        }
    }
    
    //MARK: Getting real image CGPoint
    
    func getRealImageCGPoint(_ point: CGPoint) -> CGPoint {
        let relativeSides: CGFloat = (imageView.image?.size.width)! / (imageView.image?.size.height)!
        
        let relativeByX = point.x / imageScrollView.frame.size.width
        let relativeByY = point.y / imageScrollView.frame.size.height
        
        let relativeX = (imageView.image?.size.height)! * relativeByX
        let relativeY = (imageView.image?.size.width)! * relativeByY
        
        let realPoint = CGPoint(x: relativeX,
                                y: relativeY)
                
        return realPoint
    }
    
    //MARK: Drawing on an image
    
    var drawingColor = UIColor.black
        
    @objc func scrollViewPanned(sender: UIPanGestureRecognizer) {
        let location = getRealImageCGPoint(sender.location(in: imageView))
        if sender.state == .began{
            previousTouch = location
        } else {
            wasEdited = true
            UIGraphicsBeginImageContext(imageView.image!.size)
            
            path.move(to: previousTouch)
            path.addLine(to: location)
            previousTouch = location

            imageView.image?.draw(at: CGPoint.zero)
            
            let context = UIGraphicsGetCurrentContext()
        
            context?.setStrokeColor(drawingColor.cgColor)
            context?.setLineWidth(5)
            context?.addPath(path.cgPath)
            context?.strokePath()
            
            imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }
    
    @objc func scrollViewGetTapped(sender: UITapGestureRecognizer) {
        let location = sender.location(in: imageView)
        let pipetteColor = imageView.getColor(at: location)
        pippetButton.backgroundColor = pipetteColor
        drawingColor = pipetteColor
    }
    
    func togglePainting() {
        if imageScrollView.isScrollEnabled {
            imageScrollView.addGestureRecognizer(panGesture)
            imageScrollView.removeGestureRecognizer(tapGesture)
            imageScrollView.isScrollEnabled = false
        } else {
            imageScrollView.removeGestureRecognizer(panGesture)
            imageScrollView.removeGestureRecognizer(tapGesture)
            imageScrollView.isScrollEnabled = true
        }
    }
    
    func togglePipette() {
        if imageScrollView.isScrollEnabled {
            imageScrollView.addGestureRecognizer(tapGesture)
            imageScrollView.removeGestureRecognizer(panGesture)
            imageScrollView.isScrollEnabled = false
        } else {
            imageScrollView.removeGestureRecognizer(tapGesture)
            imageScrollView.removeGestureRecognizer(panGesture)
            imageScrollView.isScrollEnabled = true
        }
    }
    
    //MARK: IBActions
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if wasEdited {
            uploadImage(image: imageView.image!, path: "\(gameNameLabel.text!).\(games[gameIndex-1].gameLink.pathExtension)") { [self] (url, errorDescription) in
                if let errorDescription = errorDescription {
                    print(errorDescription)
                    print("ERROROROROOROORORRO")
                } else {
                    print("Uploaded image")
                    games[gameIndex - 1].gameLink = url!
                    nextGame()
                }
            }
        } else {
            print("Next game")
            nextGame()
        }
        if games[gameIndex - 1].isOk == 1 {
            games[gameIndex - 1].isOk = 4
        }

    }
    
    func nextGame() {
        wasEdited = false
        imageScrollView.zoomScale = 1 //Remove zoom
        path.removeAllPoints() //Remove all lines
        
        editButton.setImage(UIImage(named: "edit"), for: .normal)
        
        pippetButton.isHidden = true
        pippetButton.isUserInteractionEnabled = false
        brushButton.isHidden = true
        brushButton.isUserInteractionEnabled = false
        
        imageScrollView.removeGestureRecognizer(panGesture)
        imageScrollView.removeGestureRecognizer(tapGesture)
        imageScrollView.isScrollEnabled = true
        
        imageScrollView.removeGestureRecognizer(tapGesture)
        imageScrollView.removeGestureRecognizer(panGesture)
        
        editButtonMode = true
        
        semaphore.signal() //Next game plz
    }
    
    var editButtonMode = true
    @IBAction func editButtonPressed(_ sender: Any) {
        if editButtonMode {
            pippetButton.isHidden = false
            pippetButton.isUserInteractionEnabled = true
            brushButton.isHidden = false
            brushButton.isUserInteractionEnabled = true
            
            editButton.setImage(UIImage(named: "Crop"), for: .normal)
            editButtonMode = false
        } else {
            imageView.image = croppedImage()
            imageScrollView.zoomScale = 1
            imageScrollView.contentOffset = CGPoint(x: 0, y: 0)
            wasEdited = true
        }
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        path.removeAllPoints() //Remove all lines
        imageScrollView.zoomScale = 0
        wasEdited = false
        downloadImage(imageURL: games[gameIndex - 1].gameLink, completion: { error, image in
            if error == nil {
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        })
            
    }
    @IBAction func pipetteButtonPressed(_ sender: Any) {
        togglePipette()
    }
    @IBAction func brushButtonPressed(_ sender: Any) {
        togglePainting()
    }
    @IBAction func exportButtonPressed(_ sender: Any) {
        createCSV(games: games, headerValues: headerValues)
    }
    @IBAction func notOkButtonPressed(_ sender: Any) {
            games[gameIndex - 1].isOk = 3
    }
}


//MARK: Extension
extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}

extension UIView {
    func getColor(at point: CGPoint) -> UIColor {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.translateBy(x: -point.x, y: -point.y)
        self.layer.render(in: context)
        let color = UIColor(red: CGFloat(pixel[0]) / 255,
                            green: CGFloat(pixel[1]) / 255,
                            blue: CGFloat(pixel[2]) / 255,
                            alpha: CGFloat(pixel[3]) / 255)
        pixel.deallocate()
        return color
    }
}
