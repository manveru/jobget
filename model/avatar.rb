module JobGet
  class Avatar < Sequel::Model
    IMAGE = {
      :owner     => :User,
      :cleanup   => true,
      :algorithm => :thumbnail,
      :sizes => {
        :small  => 150,
        :medium => 200,
      }
    }

    include SequelImage
  end
end
