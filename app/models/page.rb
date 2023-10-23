class Page < Valkyrie::Resource
  attribute :number, Valkyrie::Types::Integer
  attribute :file_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
end
