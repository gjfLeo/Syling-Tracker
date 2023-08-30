-- ========================================================================= --
--                              SylingTracker                                --
--           https://www.curseforge.com/wow/addons/sylingtracker             --
--                                                                           --
--                               Repository:                                 --
--                   https://github.com/Skamer/SylingTracker                 --
--                                                                           --
-- ========================================================================= --
Syling                "SylingTracker.Core.DataProperties"                    ""
-- ========================================================================= --
import "System.Serialization"


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

class "__DataProperties__" (function(_ENV)
  extend "IApplyAttribute"

  function ApplyAttribute(self, target, targetType, manager, owner, name, stack)
    if not Class.IsSubType(target, IObjectData) then 
      return 
    end

    for _, attributeInfo in ipairs(self) do 
      local propertyName = attributeInfo.name 
      local propertyType = attributeInfo.type 
      local propertyDefault = attributeInfo.default
      local isMap = attributeInfo.isMap
      local isArray = attributeInfo.isArray
      local singularName = attributeInfo.singleName or attributeInfo.singularName or propertyName
      local pluralName = attributeInfo.pluralName or propertyName
      local methodSingularPart = firstToUpper(singularName)
      local methodPluralPart = firstToUpper(pluralName)
      local collectionIndex = "__" .. propertyName

      -- Generate Properties
      Environment.Apply(manager, function(_ENV)
        if isArray or isMap then 
          __Indexer__(Number)
          property(propertyName) {
            type = propertyType,
            get = function(self, idx)
              return self[collectionIndex] and self[collectionIndex][idx]
            end,
            set = function(self, idx, value)
              local collection = self[collectionIndex]

              if value == nil and not collection then 
                return
              end

              if value and not collection then 
                collection = isArray and Array[propertyType]() or {}
                self[collectionIndex] = collection
              end

              local oldValue = collection[idx]
              collection[idx] = value 

              if oldValue ~= value then 
                self.DataChanged = true

                if Class.IsObjectType(oldValue, IObjectData) then
                  oldValue:SetParent(nil)
                end

                if Class.IsObjectType(value, IObjectData) then 
                  value:SetParent(self)
                end
              end

              if recycle and value == nil and oldValue and oldValue.Release then 
                oldValue:Release()
              end
            end
          }
        else
          property(propertyName) { 
            type = propertyType, 
            default = propertyDefault, 
            handler = function(self) self.DataChanged = true end
          }
        end
      end)


      -- Generate methods 
      Environment.Apply(manager, function(_ENV)
        
        target["Acquire"..methodSingularPart] = function(self, key)
          local obj = self[propertyName][key]
          if not obj then 
            obj = propertyType()
            self[propertyName][key] = obj 
          end

          return obj
        end

        target["Set"..methodPluralPart.."Count"] = function(self, count) end

        if isMap or isArray then 
          target["Iterate"..methodPluralPart] = function(self)
            if isMap then 
              return pairs(self[collectionIndex])
            elseif isArray then 
              return self[collectionIndex] and self[collectionIndex]:GetIterator()
            end
          end

          target["Clear"..methodPluralPart] = function(self)
            if not self[collectionIndex] then 
              return 
            end

            local iterator = self.isMap and pairs(self[collectionIndex]) or self[collectionIndex]:GetIterator()

            for k in iterator() do 
              self[propertyName][k] = nil
            end
          end
        end
      end)
    end
  end

  function AttachAttribute(self, target, targetType, owner, name, stack)
    if not Class.IsSubType(target, IObjectData) then 
      return 
    end


    Attribute.IndependentCall(function()
      
      __Serializable__()
      class(target) (function(_ENV)
        extend(ISerializable)

        function Serialize(obj, info)
          for _, attributeInfo in ipairs(self) do
            local propertyName = attributeInfo.name 
            local propertyType = attributeInfo.type 
            local propertyDefault = attributeInfo.default
            local isMap = attributeInfo.isMap
            local isArray = attributeInfo.isArray
            local collectionIndex = "__" .. propertyName

            if isArray then 
              info:SetValue(propertyName, obj[collectionIndex], Array[propertyType])
            elseif isMap then 
              info:SetValue(propertyName, obj[collectionIndex], Table)
            else
              info:SetValue(propertyName, obj[propertyName], propertyType)
            end
          end
        end

        function ResetDataProperties(obj, info)
          for _, attributeInfo in ipairs(self) do 
            local propertyName = attributeInfo.name 
            local propertyType = attributeInfo.type 
            local isMap = attributeInfo.isMap 
            local isArray = attributeInfo.isArray
            local collectionIndex = "__" .. propertyName

            if isMap then 
              for k in pairs(self[collectionIndex]) do 
                self[propertyName][k] = nil 
              end
            elseif isArray and self[collectionIndex] then
              for k in self[collectionIndex]:GetIterator() do 
                  self[propertyName][k] = nil 
              end
            else 
              self[propertyName] = nil 
            end
          end
        end
      end)
    end)
  end

  property "AttributeTarget" { default = AttributeTargets.Class }
end)