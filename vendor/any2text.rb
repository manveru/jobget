require 'open3'
require 'nkf'

# Any2Text provides a simple API to obtain and store plain text from other
# document formats by utilizing common utilities like antiword, html2text,
# odt2txt or pdftotext.
#
# It is easily extendable for other formats and does some sanity checking on
# the process, like making sure the output of the utility does not produce
# binary garbage and also can do automatic conversion by iterating all
# possibilities (passing it a mime-type to start out can provide faster
# results)
#
# TODO: make sure this works on windows, I have the feeling that Kernel#exec
# and Kernel#fork don't work without some prior setup

class Any2Text

  # Left hand side specifies the MIME type, the right hand is used for the
  # resulting file extension and the ID_CONVERT key.
  # Note that multiple mime types can point to the same value, but one mime
  # type can only have one value. I believe this is a reasonable restriction.

  MIME_ID = {
    'text/html' => :html,
    'text/plain' => :txt,
    'application/pdf' => :pdf,
    'application/msword' => :doc,
    'application/octet-stream' => :doc, # oh well...
    'application/vnd.oasis.opendocument.text' => :odt,
  }

  # This points to the algorithm or external program to use in order to convert
  # a given file to plain text.
  # The return value of the lambda is used as final result of the conversion,
  # it provides a simple way to use open3 (popen) as this will use proper
  # escaping of the path (popen uses exec) and parameters, yet control over
  # stdout/stdin/stderr

  ID_CONVERT = {
    :doc  => lambda{|path| popen('antiword', path) },
    :pdf  => lambda{|path| popen('pdftotext', path, '-') },
    :odt  => lambda{|path| popen('odt2txt', path) },
    :txt  => lambda{|path| File.read(path) },
    :html => lambda{|path| popen("html2text", "-nobs", "-ascii", path) },
  }

  # Useful for automatic checks on usability
  DEPENDENCIES = %w[
    antiword pdftotext odt2txt html2text
  ]

  class Error   < StandardError; end
  class PopenError      < Error; end
  class CannotConvert   < Error; end
  class ConversionError < Error; end

  attr_accessor :path, :mime

  # Path to your input file, for example '/some/path/bar.odt' or
  # '~/pdfs/foo.pdf', we use File.expand_path on the argument, so ~ will be
  # expanded to your $HOME and relative paths are changed into absolute ones.

  def initialize(path, mime = mime_for(path))
    @path, @mime = File.expand_path(path), mime
  end

  # Returns the converted text as String or raises ConversionError.
  #
  # The actual work is being done in the #conv method.
  #
  def convert(mime = mime)
    if id = MIME_ID[mime]
      conv(path, &ID_CONVERT[id])
    else
      raise(ConversionError, "Cannot convert from (%p => %p)" % [mime, path])
    end
  end

  # Returns the converted text as String or raises CannotConvert.
  #
  # Try to convert no matter what, starting with @mime and then iterating
  # through MIME_ID hash, in search for a mime that will trigger the correct
  # result.
  #
  # Note that we will invert the hash before iteration, making sure that every
  # id is only tried once and there is no order in the hash anyway, which would
  # produce randomly delayed results as the same id is tried multiple times
  # just using a different mime.

  def try_convert(given_mime = self.mime)
    if MIME_ID.has_key? given_mime
      if converted = convert_as(given_mime)
        return converted
      end
    end

    MIME_ID.invert.each do |id, mime|
      next if mime == given_mime # skip what we already tried

      if converted = convert_as(mime)
        return converted
      end
    end

    raise CannotConvert
  end

  # Tries to convert using the given mime, this is used by try_convert
  # Returns nil on fail and the resulting string on success.
  # If it succeeds, @mime will be set to the argument you passed to the method,
  # otherwise reset to nil.

  def convert_as(mime)
    self.mime = mime
    convert
  rescue ConversionError
    self.mime = nil
  end

  # Usage:
  #   a2t = Any2Text.new('foo.pdf')
  #   a2t.save_both('result')
  #   # => ['result.txt', 'result.pdf']
  #   # Saved result.txt and result.pdf
  #
  # Hand it a path to a place where you want both files to be stored, but do
  # not include the final extensions in the path.
  #
  # Example of doing it wrong:
  #   a2t.save_both('result.pdf')
  #   # => ['result.pdf.txt', 'result.pdf.pdf']
  #
  # --
  # Convert before modifying the file to write to, this gives us the chance to
  # fail without serious side-effects
  # ++
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

  private # their API may change

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

  def mime_for(path)
    self.class.popen('file', '-bi', path).strip.split.first
  end

  # Provide a simple wrapper around Open::popen3, it checks that no errors
  # arise during conversion and we actually get some useful output.
  # Returns the results of stdout.

  def self.popen(*args)
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
