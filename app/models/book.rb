class Book < Valkyrie::Resource
  attribute :alternate_ids, Valkyrie::Types::Array
              .of(Valkyrie::Types::ID)
  attribute :title, Valkyrie::Types::Set
              .of(Valkyrie::Types::String)
              .meta(ordered: true)
  attribute :author, Valkyrie::Types::Set
              .of(Valkyrie::Types::Strict::String)
              .meta(ordered: true)
  attribute :series, Valkyrie::Types::String
  attribute :member_ids, Valkyrie::Types::Array
              .of(Valkyrie::Types::ID)
end
