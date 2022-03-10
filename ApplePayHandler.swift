//
//  ApplePayHandler.swift
//  applePayDemo
//
//  Created by ChengYang on 2022/3/9.
//

class ApplePayHandler: NSObject {

	typealias ReportResultCompletion = ((PKPaymentAuthorizationResult) -> Void)
	typealias DidAuthorizePaymentCompletion = (PKPayment, @escaping ReportResultCompletion) -> Void
	typealias PaymentAuthorizationControllerDidFinishCompletion = (_ didAuthorizePayment: Bool) -> Void

	fileprivate var paymentAuthorizationControllerDidFinishCompletion: PaymentAuthorizationControllerDidFinishCompletion?
	fileprivate (set) var didAuthorizePayment: Bool = false
	fileprivate var didAuthorizePaymentCompletion: DidAuthorizePaymentCompletion?
	fileprivate var paymentSummaryItems = [PKPaymentSummaryItem]()
	fileprivate var retainSelf: ApplePayHandler?

	fileprivate class var supportedNetworks: [PKPaymentNetwork] {
		return [
			.masterCard,
			.visa,
			.JCB,
		]
	}

	class var hasAddedCardForApplePay: Bool {
		return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks)
	}

	class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
		return (PKPaymentAuthorizationController.canMakePayments(),
				PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
	}

	init(paymentSummaryItems: [PKPaymentSummaryItem] = []) {
		self.paymentSummaryItems = paymentSummaryItems
	}

	static func makePaymentSummaryItem(label: String = "Apple Inc.", amount: Int) -> PKPaymentSummaryItem {
		return PKPaymentSummaryItem(
			label: label,
			amount: NSDecimalNumber(value: amount),
			type: .final
		)
	}

	func startPayment(
		didAuthorizePaymentCompletion: @escaping DidAuthorizePaymentCompletion,
		controllerDidFinishCompletion: PaymentAuthorizationControllerDidFinishCompletion? = nil
	) {

		self.didAuthorizePaymentCompletion = didAuthorizePaymentCompletion
		self.paymentAuthorizationControllerDidFinishCompletion = controllerDidFinishCompletion

		let paymentRequest = PKPaymentRequest()
		paymentRequest.paymentSummaryItems = paymentSummaryItems
		paymentRequest.merchantIdentifier = Environment.current.appleMerchantID
		paymentRequest.merchantCapabilities = .capability3DS
		paymentRequest.countryCode = "TW"
		paymentRequest.currencyCode = "TWD"
		paymentRequest.supportedNetworks = ApplePayHandler.supportedNetworks

		let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
		paymentController.delegate = self
		paymentController.present()
		retainSelf = self
	}

}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {

	func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
		didAuthorizePayment = true
		didAuthorizePaymentCompletion?(payment, completion)
	}

	func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
		paymentAuthorizationControllerDidFinishCompletion?(didAuthorizePayment)
		retainSelf = nil
		controller.dismiss(completion: nil)
	}

}
