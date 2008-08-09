require 'open3'
require 'nkf'

class Any2Text
  MIME_ID = {
    'text/html' => :html,
    'text/plain' => :txt,
    'application/pdf' => :pdf,
    'application/msword' => :doc,
    'application/octet-stream' => :doc, # oh well...
    'application/vnd.oasis.opendocument.text' => :odt,
  }

  ID_CONVERT = {
    :doc  => lambda{|path| popen('antiword', path) },
    :pdf  => lambda{|path| popen('pdftotext', path, '-') },
    :odt  => lambda{|path| popen('odt2txt', path) },
    :txt  => lambda{|path| File.read(path) },
    :html => lambda{|path| popen("html2text", "-nobs", "-ascii", path) },
  end


  class Error   < StandardError; end
  class PopenError      < Error; end
  class CannotConvert   < Error; end
  class ConversionError < Error; end

  attr_accessor :path, :mime

  def initialize(path, mime = mime_for(path))
    @path, @mime = path, mime
  end

  def mime_for(path)
    popen('file', '-bi', path).strip.split.first
  end

  def convert(mime = mime)
    if id = MIME_ID[mime]
      conv(path, &CONV[id])
    else
      raise(ConversionError, "Cannot convert from (%p => %p)" % [mime, path])
    end
  end

  def conv(path)
    string = yield(path)
    fail_on_binary(string)
    fail_on_empty(string)
  rescue PopenError => ex
    raise ConversionError, ex
  end

  def fail_on_binary(string)
    if NKF.guess(string) == NKF::BINARY
      raise ConversionError, "Produced binary output"
    else
      return string
    end
  end

  def fail_on_empty(string)
    if string.strip.empty?
      raise ConversionError, "Produced empty output"
    else
      return string
    end
  end

  def try_convert(mime = mime)
    if MIME_ID[mime]
      if converted = convert_as(mime)
        return converted
      end
    end

    MIME_ID.each do |mime, id|
      if converted = convert_as(mime)
        return converted
      end
    end

    raise CannotConvert
  end

  def convert_as(mime)
    self.mime = mime
    convert
  rescue ConversionError
    self.mime = nil
  end

  # Convert before modifying the file to write to, this gives us the chance to
  # fail without serious side-effects
  def save_both(to)
    text = try_convert unless mime
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
    p :popen => args
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
end
