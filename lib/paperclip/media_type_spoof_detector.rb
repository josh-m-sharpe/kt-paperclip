module Paperclip
  class MediaTypeSpoofDetector
    def self.using(file, name, content_type)
      new(file, name, content_type)
    end

    def initialize(file, name, content_type)
      @file = file
      @name = name
      @content_type = content_type || ""
    end

    def spoofed?
      if has_name? && media_type_mismatch? && mapping_override_mismatch?
        Paperclip.log("Content Type Spoof: Filename #{File.basename(@name)} (#{supplied_content_type} from Headers, #{content_types_from_name.map(&:to_s)} from Extension), content type discovered from file command: #{calculated_content_type}. See documentation to allow this combination.")
        true
      else
        false
      end
    end

    private

    def has_name?
      @name.present?
    end

    def has_extension?
      File.extname(@name).present?
    end

    def media_type_mismatch?
      extension_type_mismatch? || calculated_type_mismatch?
    end

    def extension_type_mismatch?
      supplied_media_type.present? &&
        has_extension? &&
        !media_types_from_name.include?(supplied_media_type)
    end

    def calculated_type_mismatch?
      supplied_media_type.present? &&
        !calculated_content_type.include?(supplied_media_type)
    end

    def mapping_override_mismatch?
      !Array(mapped_content_type).include?(calculated_content_type)
    end

    def supplied_content_type
      @content_type
    end

    def supplied_media_type
      @content_type.split("/").first
    end

    def content_types_from_name
      @content_types_from_name ||= MIME::Types.type_for(@name)
    end

    def media_types_from_name
      @media_types_from_name ||= content_types_from_name.collect(&:media_type)
    end

    def calculated_content_type
      @calculated_content_type ||= type_from_file_command.chomp
    end

    def calculated_media_type
      @calculated_media_type ||= calculated_content_type.split("/").first
    end

    def type_from_file_command
      Paperclip.run("file", "-b --mime :file", file: @file.path).
        split(/[:;\s]+/).first
    rescue Terrapin::CommandLineError
      Paperclip.log("Problem getting type from `file` command.  Possible that `file` doesn't exist on this system.  Content Type validations don't work without this.  Possibly other stuff. YMMV.  Yay!")
      ""
    end

    def mapped_content_type
      Paperclip.options[:content_type_mappings][filename_extension]
    end

    def filename_extension
      File.extname(@name.to_s.downcase).sub(/^\./, "").to_sym
    end
  end
end
