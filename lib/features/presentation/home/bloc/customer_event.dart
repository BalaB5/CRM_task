part of 'customer_bloc.dart';

abstract class CustomerEvent {}

class LoadCustomers extends CustomerEvent {}

class AddCustomer extends CustomerEvent {
  final String email;
  final String username;
  final String fullName;
  final String phoneNumber;
  final String password;
  AddCustomer({
    required this.email,
    required this.username,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
  });
}

class UpdateCustomer extends CustomerEvent {
  final String id;
  final String fullName;
  final String phoneNumber;
  final bool isActive;
  UpdateCustomer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
  });
}

class DeleteCustomer extends CustomerEvent {
  final String customerId;
  final String email;

  DeleteCustomer({required this.customerId, required this.email});
}

class SearchCustomer extends CustomerEvent {
  final String query;
  SearchCustomer(this.query);
}
