module SequelImage
  def self.included(model)
    args = model::IMAGE
    set_foreign_key = args[:foreign_key] || "#{args[:owner]}_id".downcase.to_sym
    set_belongs_to  = args[:belongs_to]  ||    args[:owner].to_s.downcase.to_sym

    # Define schema
    model.set_schema do
      primary_key :id

      varchar :original # path to the original image
      varchar :mime, :size => 22 # average of /etc/mime.types

      time :created_at
      time :updated_at

      foreign_key set_foreign_key
    end

    # Define Relations
    model.belongs_to set_belongs_to

    # Define Hooks
    model.send(:hooks).clear

    model.before_create do
      generate_thumbnails
      self.created_at = Time.now
    end

    model.before_save do
      self.updated_at = Time.now
    end

    # Define singleton methods
    model.extend(SingletonMethods)

    # Define instance methods
    model.send(:include,
               InstanceMethods,
               Ramaze::Helper::CGI,
               Ramaze::Helper::Link)

    args[:sizes].each do |size, *args|
      model.send(:define_method, size){ public_file(size) }
      model.send(:define_method, "#{size}_url"){ file(size) }
    end
  end

  module SingletonMethods
    def store(file, uid, hash = {})
      image = new(hash)

      type     = file[:type]
      filename = file[:filename]
      tempfile = file[:tempfile]

      ext         = Ramaze::Tool::MIME.ext_for(type)
      image.mime  = type
      target_name = image.next_name(File.basename(filename, File.extname(filename)), ext)
      target_path = File.join(image.public_root, image.path, target_name)

      FileUtils.mkdir_p(File.dirname(target_path))
      FileUtils.cp(tempfile.path, target_path)

      image.original = target_path
      image.save
    end
  end

  module InstanceMethods
    def file(size = nil)
      File.join('/', path, filename(size))
    end

    def public_file(size)
      File.join(public_path, filename(size))
    end

    def public_path
      File.join(public_root, path)
    end

    def path
      conf[:path] || conf[:owner].to_s.downcase
    end

    def next_name(uid, ext)
      uid = uid.to_s.scan(%r![^\\/'".:?&;\s]+!).join('-')
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

    def conf
      self.class::IMAGE
    end

    def generate_thumbnails
      FileUtils.mkdir_p(public_path)

      sizes, algorithm = conf.values_at(:sizes, :algorithm)

      ImageScience.with_image(original) do |img|
        Ramaze::Log.debug "Generate Thumbnails: #{original}"

        sizes.each do |name, args|
          out = public_file(name)
          Ramaze::Log.debug "Generate Thumbnail: #{out}"

          img.send(algorithm, *args) do |thumb|
            thumb.save(out)
          end
        end
      end
    end
  end
end
