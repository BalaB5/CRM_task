import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_router.dart';
import '../../../../services/service_locator.dart';
import '../../../models/user_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/customer_repository.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;
  final FirebaseFirestore firestore;
  CustomerBloc({required this.customerRepository, required this.firestore})
    : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<SearchCustomer>(_onSearchCustomer);
  }

  Future<void> _onLoadCustomers(LoadCustomers event, Emitter emit) async {
    emit(CustomerLoading());
    try {
      String? currentUserId = getIt<AuthRepository>().currentUser!.email;
      final snapshot = await firestore.collection('users').get();

      final filteredDocs =
          snapshot.docs.where((doc) {
            final email = doc['email'];
            const adminEmail = 'admin@gmail.com';
            return (currentUserId == adminEmail && email != adminEmail) ||
                (currentUserId != adminEmail && email == adminEmail);
          }).toList();
      final customers =
          filteredDocs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();

      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError('Failed to load users'));
    }
  }

  Future<void> _onAddCustomer(AddCustomer event, Emitter emit) async {
    try {
      final navigator = getIt<AppRouter>().navigatorKey.currentState;
      await customerRepository.createuser(
        fullName: event.fullName,
        username: event.username,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );

      add(LoadCustomers());

      navigator!.pop();
    } catch (e) {
      emit(CustomerError('Failed to add customer'));
    }
  }

  Future<void> _onUpdateCustomer(UpdateCustomer event, Emitter emit) async {
    try {
      final navigator = getIt<AppRouter>().navigatorKey.currentState;
      await firestore.collection('users').doc(event.id).update({
        'fullName': event.fullName,
        'phoneNumber': event.phoneNumber,
        'isActive': event.isActive,
      });
      add(LoadCustomers());
      navigator!.pop();
    } catch (e) {
      emit(CustomerError('Failed to update customer'));
    }
  }

  Future<void> updateuser({
    required String email,
    required String username,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {} catch (e) {}
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await firestore.collection('users').doc(event.customerId).delete();

      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError('Failed to delete customer: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCustomer(SearchCustomer event, Emitter emit) async {
    String? currentUserId = getIt<AuthRepository>().currentUser!.email;
    final snapshot = await firestore.collection('users').get();

    final customers =
        snapshot.docs
            .where((doc) {
              return doc['email'] != currentUserId;
            })
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList();
    final filtered =
        customers.where((c) {
          return c.fullName.toLowerCase().contains(event.query.toLowerCase()) ||
              c.email.toLowerCase().contains(event.query.toLowerCase()) ||
              c.phoneNumber.contains(event.query);
        }).toList();
    emit(CustomerLoaded(filtered));
  }
}
