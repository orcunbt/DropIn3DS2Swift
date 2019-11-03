//
//  ViewController.swift
//  DropIn3DS2Swift
//
//  Created by Orcun on 02/11/2019.
//  Copyright © 2019 Orcun. All rights reserved.
//

import UIKit
import BraintreeDropIn
import Braintree

class ViewController: UIViewController {
    
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var loadSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var activityLabel: UILabel!
    var braintreeClient: BTAPIClient!
    var clientToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        successImage.isHidden = true
        buyButton.isEnabled = false
        // Do any additional setup after loading the view.
        self.activityLabel.text = "Fetching client token from server..."
        
        // Fetch client token from server
        let clientTokenURL = NSURL(string: "https://hwsrv-610555.hostwindsdns.com/BTOrcun/tokenGen.php")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle errors
            
            // 5
            if let error = error {
            print(error.localizedDescription)
            } else if
              let data = data,
              let response = response as? HTTPURLResponse,
              response.statusCode == 200 {
                self.clientToken = String(data: data, encoding: String.Encoding.utf8)!
              
              print(self.clientToken)
              // 6
              DispatchQueue.main.async {
                self.loadSpinner.isHidden = true
                    
                    self.activityLabel.text = "Client token fetched"
                self.buyButton.isEnabled = true
                UIView.animate(withDuration: 2) {
                    self.activityLabel.alpha = 0
                }
              }
            }
                

            
            // Initialize braintreeClient
            self.braintreeClient = BTAPIClient(authorization: self.clientToken)

            }.resume()
        
       
    }

    @IBAction func launchDropin(_ sender: Any) {
        
    showDropIn(clientTokenOrTokenizationKey: clientToken);
    }
    
    func showDropIn(clientTokenOrTokenizationKey: String) {
        self.loadSpinner.isHidden = false
        self.successImage.isHidden = true
        let request = BTDropInRequest()
        request.threeDSecureVerification = true

        let threeDSecureRequest = BTThreeDSecureRequest()
        threeDSecureRequest.amount = 13.99
        threeDSecureRequest.email = "test@email.com"
        threeDSecureRequest.versionRequested = .version2

        let address = BTThreeDSecurePostalAddress()
        address.givenName = "Jill" // ASCII-printable characters required, else will throw a validation error
        address.surname = "Doe" // ASCII-printable characters required, else will throw a validation error
        address.phoneNumber = "5551234567"
        address.streetAddress = "555 Smith St"
        address.extendedAddress = "#2"
        address.locality = "Chicago"
        address.region = "IL"
        address.postalCode = "12345"
        address.countryCodeAlpha2 = "US"
        threeDSecureRequest.billingAddress = address

        // Optional additional information.
        // For best results, provide as many of these elements as possible.
        let info = BTThreeDSecureAdditionalInformation()
        info.shippingAddress = address
        threeDSecureRequest.additionalInformation = info

        let dropInRequest = BTDropInRequest()
        dropInRequest.threeDSecureVerification = true
        dropInRequest.threeDSecureRequest = threeDSecureRequest
        
        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: dropInRequest)
        { (controller, result, error) in
            if (error != nil) {
                print("ERROR")
            } else if (result?.isCancelled == true) {
                print("CANCELLED")
                self.activityLabel.alpha = 10
                   self.activityLabel.text = "User cancelled"
               self.loadSpinner.isHidden = true
                UIView.animate(withDuration: 2) {
                    self.activityLabel.alpha = 0
                }
            } else if let result = result {
                // Use the BTDropInResult properties to update your UI
                // result.paymentOptionType
                // result.paymentMethod
                // result.paymentIcon
                // result.paymentDescription
                self.loadSpinner.isHidden = false
                self.activityLabel.alpha = 10
                self.activityLabel.text = "Payment nonce: \n" + result.paymentMethod!.nonce + "\n\nSending it to server to create a transaction..."
                
                self.postNonceToServer(paymentMethodNonce: result.paymentMethod!.nonce)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    // Function for sending the nonce to server
    func postNonceToServer(paymentMethodNonce : String) {
        self.successImage.isHidden = true
        let paymentURL = NSURL(string: "https://hwsrv-610555.hostwindsdns.com/BTOrcun/iosTransaction.php")!
        let request = NSMutableURLRequest(url: paymentURL as URL)
        request.httpBody = "payment_method_nonce=\(paymentMethodNonce)".data(using: String.Encoding.utf8);
        request.httpMethod = "POST"
        
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle success or failure
            let responseData = String(data: data!, encoding: String.Encoding.utf8)
            
            
            // Log the response in console
            print(responseData!);
            

            
                DispatchQueue.main.async {
                    self.loadSpinner.isHidden = true
                    if responseData!.contains("submitted_for_settlement") {
                        self.successImage.isHidden = false
                    }
                    self.activityLabel.alpha = 10
                    self.activityLabel.text = responseData!
                }
            
            }.resume()
        
    }
    
}

