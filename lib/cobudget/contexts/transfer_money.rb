require 'playhouse/context'
require 'playhouse/loader'
require 'support/identifier'

module Cobudget
  entities :transaction, :account, :user, :budget, :bucket
  roles :transfer_source, :transfer_destination
  composer :money_composer

  class TransferMoney < Playhouse::Context
    class CannotTransferMoney < Exception; end
    class InsufficientFunds < CannotTransferMoney; end
    class InvalidTransferDestination < CannotTransferMoney; end
    class TransferFailed < Exception; end

    actor :source_account, role: TransferSource, repository: Account
    actor :destination_account, role: TransferDestination, repository: Account
    actor :creator, repository: User
    actor :amount
    actor :time, optional: true
    actor :description, optional: true

    def transfer_arguments
      {
          creator_id: creator.id,
          description: description
      }
    end

    def perform
      raise InsufficientFunds unless source_account.can_decrease_money?(amount) || source_account.user.blank?
      raise InvalidTransferDestination unless source_account.budget == destination_account.budget
      begin
        ActiveRecord::Base.transaction do
          amt = amount.to_f
          transaction = Transaction.create!(transfer_arguments)
          destination_account.increase_money!(amt, transaction, Identifier.generate)
          source_account.decrease_money!(amt, transaction, Identifier.generate)
        end
      rescue Exception
        raise TransferFailed, "Transfer from '#{source_account.name}' to '#{destination_account.name}' failed."
      end
    end
  end
end
