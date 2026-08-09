import 'package:queuewise/shared/models/organisation_model.dart';
import 'package:queuewise/shared/models/service_model.dart';

/// Organisation repository interface
abstract class OrganisationRepository {
  /// Get all active organisations
  Future<List<OrganisationModel>> getOrganisations();

  /// Get organisation by ID
  Future<OrganisationModel?> getOrganisation(String id);

  /// Get services for an organisation
  Future<List<ServiceModel>> getServices(String organisationId);

  /// Get service by ID
  Future<ServiceModel?> getService(String organisationId, String serviceId);

  /// Search organisations by name
  Future<List<OrganisationModel>> searchOrganisations(String query);
}
