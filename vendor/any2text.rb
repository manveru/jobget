require 'open3'

class Any2Text
  MIME_ID = {
    'application/pdf' => :pdf,
    'application/msword' => :doc,
    'application/vnd.oasis.opendocument.text' => :odt,
  }

  class Error < StandardError; end
  class PopenError < Error; end
  class ConversionError < Error; end

  attr_accessor :path, :mime

  def initialize(path, mime = mime_for(path))
    @path, @mime = path, mime
  end

  def mime_for(path)
    popen('file', '-bi', path).strip
  end

  def convert(mime = mime)
    if id = MIME_ID[mime]
      method_name = "anti_#{id}"
      send(method_name, path)
    else
      raise(ConversionError, "Cannot convert from (%p => %p)" % [mime, path])
    end
  end

  def try_convert
    MIME_ID.each do |mime, id|
      begin
        self.mime = mime
        return convert
      rescue ConversionError
        self.mime = nil
      end
    end
  end

  # Convert before modifying the file to write to, this gives us the chance to
  # fail without serious side-effects
  def save_both(to)
    text = convert
    FileUtils.mkdir_p(File.dirname(to))

    to_txt = to + '.txt'
    puts "Save to #{to_txt}"
    File.open(to_txt, 'w+'){|io| io.write(text) }

    to_ext = to + ".#{MIME_ID[mime]}"
    puts "Save to #{to_ext}"
    FileUtils.cp(path, to_ext)

    [to_txt, to_ext]
  end

  def popen(*args)
    text = nil

    Open3.popen3(*args) do |stdin, stdout, stderr|
      err = stderr.read
      out = stdout.read

      if err.empty?
        if out.empty?
          raise PopenError, "No output"
        else
          text = out
        end
      else
        raise PopenError, err
      end
    end

    text
  end

  def anti_doc(path)
    popen('antiword', path)
  rescue PopenError => ex
    raise ConversionError, ex
  end

  def anti_pdf(path)
    popen('pdftotext', path, '-')
  rescue PopenError => ex
    raise ConversionError, ex
  end

  def anti_odt(path)
    popen('odt2txt', path)
  rescue PopenError => ex
    raise ConversionError, ex
  end
end
