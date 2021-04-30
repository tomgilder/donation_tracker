import 'package:deep_pick/deep_pick.dart';
import 'package:donation_tracker/constants.dart';
import 'package:donation_tracker/graphQlRequests.dart';
import 'package:donation_tracker/models/donation.dart';
import 'package:donation_tracker/models/usage.dart';
import 'package:graphql/client.dart';
import 'package:nhost_graphql_adapter/nhost_graphql_adapter.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:rxdart/rxdart.dart';

class NhostService {
  bool get hasWriteAccess =>
      nhostClient.auth.authenticationState == AuthenticationState.loggedIn;

  late final GraphQLClient client;

  final nhostClient = NhostClient(baseUrl: nhostBaseUrl);

  late Stream<List<Donation>> donationTableUpdates;
  late Stream<List<Usage>> usageTableUpdates;
  late Stream<OperationException> errorUpdates;

  NhostService() {
    client = createNhostGraphQLClient(graphQlEndPoint, nhostClient);
  }

  Future<bool> loginUser(String userName, String pwd) async {
    try {
      await nhostClient.auth.login(
        email: userName,
        password: pwd,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void startGraphQlSubscriptions() {
    /// unless you are not logged in, not all properties are acessible
    /// That's why we have to use differen't gql requests
    final donationDoc =
        gql(hasWriteAccess ? getDonationLoggedInRequest : getDonationRequest);
    final usageDoc = gql(getUsage);

    final Stream<QueryResult> donationTableUpdateStream = client
        .subscribe(SubscriptionOptions(document: donationDoc))
        .asBroadcastStream();
    donationTableUpdates = donationTableUpdateStream
        .where((event) => (!event.hasException) && (event.data != null))
        .map((event) {
      final itemsAsMap = event.data![tableDonations] as List;
      return itemsAsMap.map((x) => Donation.fromMap(x!)).toList();
    });

    final Stream<QueryResult> usageTableUpdateStream = client
        .subscribe(SubscriptionOptions(document: usageDoc))
        .asBroadcastStream();
    usageTableUpdates = usageTableUpdateStream
        .where((event) => (!event.hasException) && (event.data != null))
        .map((event) {
      final itemsAsMap = event.data![tableUsages] as List;
      return itemsAsMap.map((x) => Usage.fromMap(x!)).toList();
    });

    errorUpdates = usageTableUpdateStream
        .mergeWith([donationTableUpdateStream])
        .where((event) => event.hasException)
        .map((event) => event.exception!);

    errorUpdates.listen((event) {
      print(event.toString());
    });
  }

  Future<int> addDonation(Donation donation) async {
    final options = MutationOptions(
      document: gql(insertDonationRequest),
      variables: {
        'donator': donation.name,
        'value': donation.amount,
        'donation_date': donation.date,
        'donator_hidden': donation.hiddenName
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }
    return pick(
            result.data, 'insert_temp_money_donations', 'returning', 0, 'id')
        .asIntOrThrow();
  }

  Future deleteDonation(int id) async {
    final options = MutationOptions(
      document: gql(deleteDonationRequest),
      variables: {
        'id': id,
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      throw result.exception!;
    }
  }
}
