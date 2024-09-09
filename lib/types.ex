defmodule MoovElixirSDK.Types do
  @type address :: %{
          addressLine1: String.t(),
          city: String.t(),
          country: String.t(),
          postalCode: String.t(),
          stateOrProvince: String.t()
        }

  @type phone :: %{
          countryCode: String.t(),
          number: String.t()
        }

  @type industry_codes :: %{
          mcc: String.t(),
          naics: String.t(),
          sic: String.t()
        }

  @type representative :: %{
          address: address(),
          birthDateProvided: boolean(),
          createdOn: String.t(),
          email: String.t(),
          governmentIDProvided: boolean(),
          name: %{
            firstName: String.t(),
            lastName: String.t()
          },
          phone: phone(),
          representativeID: String.t(),
          responsibilities: %{
            isController: boolean(),
            isOwner: boolean(),
            jobTitle: String.t(),
            ownershipPercentage: integer()
          },
          updatedOn: String.t()
        }

  @type business_profile :: %{
          address: address(),
          businessType: String.t(),
          description: String.t(),
          doingBusinessAs: String.t(),
          email: String.t(),
          industryCodes: industry_codes(),
          legalBusinessName: String.t(),
          ownersProvided: boolean(),
          phone: phone(),
          representatives: [representative()],
          taxIDProvided: boolean(),
          website: String.t()
        }

  @type capability :: %{
          capability: String.t(),
          status: String.t()
        }

  @type account_response :: %{
          accountID: String.t(),
          accountType: String.t(),
          capabilities: [capability()],
          createdOn: String.t(),
          displayName: String.t(),
          mode: String.t(),
          profile: %{
            business: business_profile()
          },
          settings: %{
            achPayment: %{
              companyName: String.t()
            },
            cardPayment: %{
              statementDescriptor: String.t()
            }
          },
          termsOfService: %{
            acceptedDate: String.t(),
            acceptedIP: String.t()
          },
          updatedOn: String.t(),
          verification: %{
            status: String.t(),
            verificationStatus: String.t()
          }
        }

  @type create_individual_account :: %{
          foreignID: String.t(),
          email: String.t(),
          name: %{
            firstName: String.t(),
            lastName: String.t()
          }
        }

  @type bank_account_request :: %{
          accountNumber: String.t(),
          bankAccountType: String.t(),
          holderName: String.t(),
          holderType: String.t(),
          routingNumber: String.t()
        }

  @type bank_account_response :: %{
          bankAccountID: String.t(),
          bankAccountType: String.t(),
          bankName: String.t(),
          exceptionDetails: %{
            achReturnCode: String.t(),
            description: String.t(),
            rtpRejectionCode: String.t()
          },
          fingerprint: String.t(),
          holderName: String.t(),
          holderType: String.t(),
          lastFourAccountNumber: String.t(),
          paymentMethods: [payment_method()],
          routingNumber: String.t(),
          status: String.t(),
          statusReason: String.t(),
          updatedOn: String.t()
        }

  @type payment_method :: %{
          paymentMethodID: String.t(),
          paymentMethodType: String.t()
        }

  @type capability_response :: %{
          accountID: String.t(),
          capability: String.t(),
          createdOn: String.t(),
          requirements: %{
            currentlyDue: [String.t()],
            errors: [
              %{
                errorCode: String.t(),
                requirement: String.t()
              }
            ]
          },
          status: String.t(),
          updatedOn: String.t()
        }
end
