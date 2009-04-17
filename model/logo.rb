module JobGet
  class Logo < Sequel::Model
    IMAGE = {
      :owner     => :Company,
      :cleanup   => true,
      :algorithm => :thumbnail,
      :sizes => {
        :small  => 150,
        :medium => 300,
        :large  => 600,
      }
    }

    include SequelImage
  end
end
