import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/errors/exceptions.dart';
import 'package:queuewise/features/organisations/domain/repositories/organisation_repository.dart';
import 'package:queuewise/shared/models/organisation_model.dart';
import 'package:queuewise/shared/models/service_model.dart';

/// Organisation repository implementation
class OrganisationRepositoryImpl implements OrganisationRepository {
  final FirebaseFirestore firestore;

  OrganisationRepositoryImpl({required this.firestore});

  @override
  Future<List<OrganisationModel>> getOrganisations() async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .where('active', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => OrganisationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting organisations: $e');
      throw DatabaseException('Failed to load organisations');
    }
  }

  @override
  Future<OrganisationModel?> getOrganisation(String id) async {
    try {
      final doc = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(id)
          .get();

      if (!doc.exists) return null;
      return OrganisationModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting organisation: $e');
      throw DatabaseException('Failed to load organisation');
    }
  }

  @override
  Future<List<ServiceModel>> getServices(String organisationId) async {
    try {
      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.servicesCollection)
          .where('active', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting services: $e');
      throw DatabaseException('Failed to load services');
    }
  }

  @override
  Future<ServiceModel?> getService(String organisationId, String serviceId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.organisationsCollection)
          .doc(organisationId)
          .collection(AppConstants.servicesCollection)
          .doc(serviceId)
          .get();

      if (!doc.exists) return null;
      return ServiceModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting service: $e');
      throw DatabaseException('Failed to load service');
    }
  }

  @override
  Future<List<OrganisationModel>> searchOrganisations(String query) async {
    try {
      if (query.isEmpty) {
        return getOrganisations();
      }

      final snapshot = await firestore
          .collection(AppConstants.organisationsCollection)
          .where('active', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => OrganisationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching organisations: $e');
      throw DatabaseException('Failed to search organisations');
    }
  }
}
