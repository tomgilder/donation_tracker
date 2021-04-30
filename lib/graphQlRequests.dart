const String getDonation = """
  subscription {
    temp_money_donations(order_by: {donation_date: desc}) {
      donator
      id
      value
      donation_date
    }
  }

""";
const String getDonationLoggedIn = """
  subscription{ 
    temp_money_donations(order_by: {donation_date: desc}) {
      created_at
      donator
      id
      updated_at
      value
      donation_date
      donator_hidden
    }
  }

""";

const String insertDonation = r"""
mutation ($donator: String, $donator_hidden: String, $value: Int!, $donation_date: timestamp!) {
  insert_temp_money_donations(objects: {donation_date: $donation_date, donator: $donator, donator_hidden: $donator_hidden, value: $value}) {
    returning {
      id
    }
  }
}

""";

const String getUsage = """
  subscription {
    temp_money_used_for(order_by: {usage_date: desc, created_at:asc}) {
      created_at
      id
      storage_image_name
      updated_at
      usage
      value
      usage_date
      receivers_name 
      storage_image_name_person
    }
  }
""";
