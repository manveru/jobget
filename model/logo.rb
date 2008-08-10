class Logo < Sequel::Model
  include Ramaze::Helper::CGI
  include Ramaze::Helper::Link

  PATH = '/logo'
  SIZES = {
    :small  => [150, 150],
    :medium => [300, 300],
    :large  => [800, 600],
  }

  set_schema do
    primary_key :id

    # varchar :caption, :size => 100
    varchar :original
    varchar :mime, :size => 10

    time :created_at
    time :updated_at

    foreign_key :company_id
  end

  belongs_to :company

  hooks.clear

  before_create do
    self.created_at = Time.now
  end

  before_save do
    generate_thumbnail(SIZES)
    self.updated_at = Time.now
  end

  SIZES.each do |name, (height, width)|
    define_method(name){ public_file(name) }
    define_method("#{name}_url"){ file(name) }
  end

  def self.store(file, uid, hash = {})
    logo = new(hash)

    type     = file[:type]
    filename = file[:filename]
    tempfile = file[:tempfile]

    ext         = Ramaze::Tool::MIME.ext_for(type)
    target_name = logo.next_name(uid, ext)
    target_path = File.join(logo.public_root, PATH, target_name)

    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(tempfile.path, target_path)

    logo.original = target_path
    logo.save
  end

  def file(size = nil)
    File.join(PATH, filename(size))
  end

  def public_file(size)
    File.join(public_path, filename(size))
  end

  def public_path
    File.join(public_root, PATH)
  end

  # TODO: fix
  def next_name(uid, ext)
    "#{uid}#{ext}"
  end

  def basename
    File.basename(original, File.extname(original))
  end

  def public_root
    Ramaze::Global.public_root
  end

  def filename(size)
    if size
      "#{basename}_#{size}.png"
    else
      "#{basename}.png"
    end
  end

  def generate_thumbnail(sizes = {})
    require 'image_science'
    require 'vendor/image_science_cropped_resize'

    FileUtils.mkdir_p(public_path)

    ImageScience.with_image(original) do |img|
      Ramaze::Log.debug "Generate Thumbnails for: #{original}"

      sizes.each do |name, (width, height)|
        out = public_file(name)

        img.cropped_resize width, height do |thumb|
          thumb.save(out)
        end
      end
    end
  end
end
