import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:stripe_app/models/payment_intent_response.dart';
import 'package:stripe_app/models/stripe_custom_response.dart';
import 'package:stripe_payment/stripe_payment.dart';

class StripeService {
  //Singleton
  StripeService._privateConstructor();
  static final StripeService _instance = StripeService._privateConstructor();
  factory StripeService() => _instance;

  String _paymentApiUrl = 'https://api.stripe.com/v1/payment_intents';
  static String _secretKey =
      'sk_test_51J8s7PGVQVIvsbeUtIHhIsI53pDXZ25QETcC6WzYOPIKAOwICEhp6RO5WydeZyxN3dK52XQHXwDEbEEFOq7A6f4C00LquonQNw';
  String _apiKey =
      'pk_test_51J8s7PGVQVIvsbeUnXYfojc0wr9KNLMm6mhgsdlmSXUah0ReZufwY5kPvyflHTdZs9lrKpSuPHSK2OLIOK5GjEJX003KXgpP01';
  final headerOptions = new Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Authorization': 'Bearer ${StripeService._secretKey}'});
  void init() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: this._apiKey,
        androidPayMode: 'test',
        merchantId: 'test'));
  }

  Future<StripeCustomResponse> pagarConTarjetaExiste({
    @required String? amount,
    @required String? currency,
    @required CreditCard? card,
  }) async {
    try {
      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(card: card));

      final resp = await this._realizarPago(
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      return resp;
    } catch (e) {
      return StripeCustomResponse(
        ok: false,
        msg: e.toString(),
      );
    }
  }

  Future<StripeCustomResponse> pagarConNuevaTarjeta(
      {@required String? amount, @required String? currency}) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());

      final resp = await this._realizarPago(
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      return resp;
    } catch (e) {
      return StripeCustomResponse(
        ok: false,
        msg: e.toString(),
      );
    }
  }

  Future<StripeCustomResponse> pagarApplePayGooglePay({
    @required String? amount,
    @required String? currency,
  }) async {
    try {
      final newAmount = double.parse(amount!) / 100;

      final token = await StripePayment.paymentRequestWithNativePay(
        androidPayOptions: AndroidPayPaymentRequest(
          currencyCode: currency,
          totalPrice: amount,
        ),
        applePayOptions: ApplePayPaymentOptions(
          countryCode: 'MXN',
          currencyCode: currency,
          items: [
            ApplePayItem(
              label: 'Producto 1',
              amount: '$newAmount',
            ),
          ],
        ),
      );
      final paymentMethod = await StripePayment.createPaymentMethod(
        PaymentMethodRequest(
          card: CreditCard(
            token: token.tokenId,
          ),
        ),
      );

      final resp = await this._realizarPago(
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      await StripePayment.completeNativePayRequest();

      return resp;
    } catch (e) {
      return StripeCustomResponse(
        ok: false,
        msg: e.toString(),
      );
    }
  }

  Future _crearPaymentIntent(
      {@required String? amount, @required String? currency}) async {
    try {
      final dio = new Dio();
      final data = {'amount': amount, 'currency': currency};

      final resp = await dio.post(
        _paymentApiUrl,
        data: data,
        options: headerOptions,
      );
      return PaymentIntentResponse.fromJson(resp.data);
    } catch (e) {
      print(e.toString());
      return PaymentIntentResponse(status: '400');
    }
  }

  Future<StripeCustomResponse> _realizarPago({
    @required String? amount,
    @required String? currency,
    @required PaymentMethod? paymentMethod,
  }) async {
    try {
      final paymentIntent = await this._crearPaymentIntent(
        amount: amount,
        currency: currency,
      );

      final paymentResult = await StripePayment.confirmPaymentIntent(
        PaymentIntent(
            clientSecret: paymentIntent.clientSecret,
            paymentMethodId: paymentMethod!.id),
      );
      if (paymentResult.status == 'succeeded') {
        return StripeCustomResponse(ok: true);
      } else {
        return StripeCustomResponse(
          ok: false,
          msg: 'Fallo: ${paymentResult.status}',
        );
      }
    } catch (e) {
      return StripeCustomResponse(
        ok: false,
        msg: e.toString(),
      );
    }
    //Crear el Intentent
  }
}
