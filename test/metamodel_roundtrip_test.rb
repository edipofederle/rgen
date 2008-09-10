$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/array_extensions'
require 'rgen/model_comparator'
require 'mmgen/metamodel_generator'
require 'rgen/instantiator/ecore_xml_instantiator'
require 'rgen/serializer/xmi20_serializer'

class MetamodelGeneratorTest < Test::Unit::TestCase
  
  TEST_DIR = File.dirname(__FILE__)+"/metamodel_roundtrip_test"
  
  include MMGen::MetamodelGenerator
  include RGen::ModelComparator
  
  module Regenerated
    Inside = binding
  end
  
  def test_generator
    require TEST_DIR+"/TestModel.rb"
    outfile = TEST_DIR+"/TestModel_Regenerated.rb"		
    generateMetamodel(HouseMetamodel.ecore, outfile)
    
    File.open(outfile) do |f|
      eval(f.read, Regenerated::Inside)
    end
    
    assert modelEqual?(HouseMetamodel.ecore, Regenerated::HouseMetamodel.ecore, ["instanceClassName"])
  end
  
  module UMLRegenerated
    Inside = binding
  end
  
  def test_generate_from_ecore
    outfile = TEST_DIR+"/houseMetamodel_from_ecore.rb"

    env = RGen::Environment.new
    File.open(TEST_DIR+"/houseMetamodel.ecore") { |f|
      ECoreXMLInstantiator.new(env).instantiate(f.read)
    }
    rootpackage = env.find(:class => RGen::ECore::EPackage).first
    rootpackage.name = "HouseMetamodel"
    generateMetamodel(rootpackage, outfile)
    
    File.open(outfile) do |f|
      eval(f.read, UMLRegenerated::Inside, "test_eval", 0)
    end
  end
  
  def test_ecore_serializer
    require TEST_DIR+"/TestModel.rb"
    File.open(TEST_DIR+"/houseMetamodel_Regenerated.ecore","w") do |f|
	  	ser = RGen::Serializer::XMI20Serializer.new(f)
	  	ser.serialize(HouseMetamodel.ecore)
	 	end
  end
  
end