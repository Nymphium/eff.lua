local ref
do
  local newref = function()
    return setmetatable({
      content = nil,
      get = function(self)
        return self.content
      end
    }, {
      __call = function(self, v)
        self.content = v
        return self
      end,
      __bnot = function(self)
        return self.content
      end})
  end

  ref = function(v) return newref()(v) end
end

return ref
