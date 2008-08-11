class Avatar < Sequel::Model
  IMAGE = {
    # specifies belongs_to, will create relation and foreign key
    :owner     => :User,

    # Remove original and thumbnails on #destroy
    :cleanup   => true,

    # Algorithm to use in ImageScience
    #
    # * resize(width, height)
    #     Resizes the image to +width+ and +height+ using a cubic-bspline
    #     filter.
    #
    # * cropped_resize(width, height)
    #     The magic one, basically cropped_thumbnail but takes +width+ and
    #     +height+.
    #
    # * thumbnail(size)
    #     Creates a proportional thumbnail of the image scaled so its longest
    #     edge is resized to +size+.
    #
    # * cropped_thumbnail(size)
    #     Creates a square thumbnail of the image cropping the longest edge to
    #     match the shortest edge, resizes to +size+.
    :algorithm => :thumbnail,

    # Key specifies the filename and accessors, value are arguments to the
    # algorithm
    :sizes => {
      :small  => 150, #[150, 150],
      :medium => 200, #[200, 200]
    }
  }

  include SequelImage
end
