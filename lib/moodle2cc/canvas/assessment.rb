module Moodle2CC::Canvas
  class Assessment < Moodle2CC::CC::Assessment
    attr_accessor :non_cc_assessments_identifier

    def initialize(mod, position=0)
      super
      @non_cc_assessments_identifier = create_key(@id, 'non_cc_assessments_')
    end

    def create_resource_node(resources_node)
      href = File.join(identifier, ASSESSMENT_META)
      resources_node.resource(
        :href => href,
        :type => LOR,
        :identifier => non_cc_assessments_identifier
      ) do |resource_node|
        resource_node.file(:href => href)
        resource_node.file(:href => File.join(ASSESSMENT_NON_CC_FOLDER, "#{identifier}.xml.qti"))
      end
    end

    def create_files(export_dir)
      create_assessment_meta_xml(export_dir)
      create_non_cc_qti_xml(export_dir)
    end

    def create_assessment_meta_xml(export_dir)
      path = File.join(export_dir, identifier, ASSESSMENT_META)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        node = Builder::XmlMarkup.new(:target => file, :indent => 2)
        node.instruct!
        node.quiz(
          :identifier => identifier,
          'xsi:schemaLocation' => "http://canvas.instructure.com/xsd/cccv1p0 http://canvas.instructure.com/xsd/cccv1p0.xsd",
          'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
          'xmlns' => "http://canvas.instructure.com/xsd/cccv1p0"
        ) do |quiz_node|
          META_ATTRIBUTES.each do |attr|
            quiz_node.tag!(attr, send(attr)) unless send(attr).nil?
          end
        end
      end
    end

    def create_non_cc_qti_xml(export_dir)
      path = File.join(export_dir, ASSESSMENT_NON_CC_FOLDER, "#{identifier}.xml.qti")
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') do |file|
        node = Builder::XmlMarkup.new(:target => file, :indent => 2)
        node.instruct!
        node.questestinterop(
          'xsi:schemaLocation' => "http://www.imsglobal.org/xsd/ims_qtiasiv1p2 http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd",
          'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
          'xmlns' => "http://www.imsglobal.org/xsd/ims_qtiasiv1p2"
        ) do |root_node|
          root_node.assessment(:title => title, :identifier => identifier) do |assessment_node|
            assessment_node.qtimetadata do |qtimetadata_node|
              qtimetadata_node.qtimetadatafield do |qtimetadatafield_node|
                qtimetadatafield_node.fieldlabel "qmd_timelimit"
                qtimetadatafield_node.fieldentry time_limit
              end
              qtimetadata_node.qtimetadatafield do |qtimetadatafield_node|
                qtimetadatafield_node.fieldlabel "cc_maxattempts"
                qtimetadatafield_node.fieldentry allowed_attempts
              end
            end
            assessment_node.section(:ident => 'root_section') do |section_node|
              @mod.question_instances.each do |question_instance|
                question = Question.new question_instance
                question.create_item_xml(section_node)
              end
            end
          end
        end
      end
    end

    def create_module_meta_item_elements(item_node)
      item_node.content_type 'Quiz'
      item_node.identifierref @identifier
    end
  end
end