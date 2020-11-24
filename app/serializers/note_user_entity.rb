# frozen_string_literal: true

class NoteUserEntity < UserEntity
  expose :status

  unexpose :web_url
end

NoteUserEntity.prepend_if_ee('EE::NoteUserEntity')
