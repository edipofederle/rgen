require 'rgen/transformer'
require 'rgen/ecore/ecore'

module RGen
  
module ECore
  
# This transformer creates an ECore model from Ruby classes built
# by RGen::MetamodelBuilder.
# 
class ECoreTransformer < Transformer
  
  transform Class, :to => EClass, :if => :convert? do
    { :name => name.gsub(/.*::(\w+)$/,'\1'),
      :abstract => false,
      :interface => false,
      :eStructuralFeatures => trans(_metamodel_description),
      :ePackage =>  trans(name =~ /(.*)::\w+$/ ? eval($1) : nil),
      :eSuperTypes => trans(superclasses),
      :instanceClassName => name,
      :eAnnotations => trans(_annotations)
    }
  end
  
  method :superclasses do
    if superclass.respond_to?(:multiple_superclasses) && superclass.multiple_superclasses
      superclass.multiple_superclasses
    else
      [ superclass ]
    end
  end
  
  transform Module, :to => EPackage, :if => :convert?  do
    { :name => name.gsub(/.*::(\w+)$/,'\1'),
      :eClassifiers => trans(constants.collect{|c| const_get(c)}.select{|c| c.is_a?(Class)}),
      :eSuperPackage => trans(name =~ /(.*)::\w+$/ ? eval($1) : nil),
      :eSubpackages => trans(constants.collect{|c| const_get(c)}.select{|c| c.is_a?(Module) && !c.is_a?(Class)}),
      :eAnnotations => trans(_annotations)
    }
  end
  
  method :convert? do
    @current_object.respond_to?(:ecore) && @current_object != RGen::MetamodelBuilder::MMBase
  end
  
  transform MetamodelBuilder::AttributeDescription, :to => EAttribute do
    Hash[*MetamodelBuilder::AttributeDescription.propertySet.collect{|p| [p, value(p)]}.flatten].merge({
      :eType => (etype == :EEnumerable ? trans(impl_type) : RGen::ECore.const_get(etype)),
      :eAnnotations => trans(annotations)
    })
  end
  
  transform MetamodelBuilder::ReferenceDescription, :to => EReference do
    Hash[*MetamodelBuilder::ReferenceDescription.propertySet.collect{|p| [p, value(p)]}.flatten].merge({
      :eType => trans(impl_type),
      :eOpposite => trans(opposite),
      :eAnnotations => trans(annotations)
    })
  end
  
  transform MetamodelBuilder::Intermediate::Annotation, :to => EAnnotation do
    { :source => source,
      :details => details.keys.collect do |k|
        e = EStringToStringMapEntry.new
        e.key = k
        e.value = details[k]
        e
      end
    }
  end
  
  transform MetamodelBuilder::DataTypes::Enum, :to => EEnum do
    { :name => name, 
      :eLiterals => literals.collect do |l|
        lit = EEnumLiteral.new
        lit.name = l.to_s
        lit
      end }
  end
  
end
  
end
  
end