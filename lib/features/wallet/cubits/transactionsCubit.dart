import 'dart:convert';

import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/wallet/models/paymentRequest.dart';
import 'package:flutterquiz/features/wallet/walletRepository.dart';

abstract class TransactionsState {}

class TransactionsFetchInitial extends TransactionsState {}

class TransactionsFetchInProgress extends TransactionsState {}

class TransactionsFetchSuccess extends TransactionsState {
  final List<PaymentRequest> paymentRequests;
  final int totalTransactionsCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  TransactionsFetchSuccess({
    required this.paymentRequests,
    required this.totalTransactionsCount,
    required this.hasMoreFetchError,
    required this.hasMore,
  });
}

class TransactionsFetchFailure extends TransactionsState {
  final String errorMessage;

  TransactionsFetchFailure(this.errorMessage);
}

class TransactionsCubit extends Cubit<TransactionsState> {
  final WalletRepository _walletRepository;

  TransactionsCubit(this._walletRepository) : super(TransactionsFetchInitial());

  final int limit = 15;

  void getTransactions({required String userId}) async {
    try {
      final result = await _walletRepository.getTransactions(
        userId: userId,
        limit: limit.toString(),
        offset: "0",
      );

      if (isClosed) return;

      dev.log(name: 'Payout Transactions', jsonEncode(result));

      emit(TransactionsFetchSuccess(
        paymentRequests: result['transactions'],
        totalTransactionsCount: int.parse(result['total']),
        hasMoreFetchError: false,
        hasMore: (result['transactions'] as List<PaymentRequest>).length <
            int.parse(result['total']),
      ));
    } catch (e) {
      if (isClosed) return;

      emit(TransactionsFetchFailure(e.toString()));
    }
  }

  bool hasMoreTransactions() => (state is TransactionsFetchSuccess)
      ? (state as TransactionsFetchSuccess).hasMore
      : false;

  void getMoreTransactions({required String userId}) async {
    if (state is TransactionsFetchSuccess) {
      try {
        //
        final result = await _walletRepository.getTransactions(
            userId: userId,
            limit: limit.toString(),
            offset: (state as TransactionsFetchSuccess)
                .paymentRequests
                .length
                .toString());
        List<PaymentRequest> updatedResults =
            (state as TransactionsFetchSuccess).paymentRequests;
        updatedResults.addAll(result['transactions'] as List<PaymentRequest>);
        emit(TransactionsFetchSuccess(
          paymentRequests: updatedResults,
          totalTransactionsCount: int.parse(result['total']),
          hasMoreFetchError: false,
          hasMore: updatedResults.length < int.parse(result['total']),
        ));
        //
      } catch (e) {
        //in case of any error
        emit(TransactionsFetchSuccess(
          paymentRequests: (state as TransactionsFetchSuccess).paymentRequests,
          hasMoreFetchError: true,
          totalTransactionsCount:
              (state as TransactionsFetchSuccess).totalTransactionsCount,
          hasMore: (state as TransactionsFetchSuccess).hasMore,
        ));
      }
    }
  }

  double calculateTotalEarnings() {
    if (state is TransactionsFetchSuccess) {
      final successfulRequests = (state as TransactionsFetchSuccess)
          .paymentRequests
          .where((element) => element.status == "1");
      double totalEarnings = 0;

      for (var element in successfulRequests) {
        totalEarnings = totalEarnings + double.parse(element.paymentAmount);
      }
      return totalEarnings;
    }
    return 0;
  }
}
