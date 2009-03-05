class Hash
  def symbolize_keys!
    replace(inject({}) do |hash,(key,value)|
      hash[key.to_sym] = value.is_a?(Hash) ? value.symbolize_keys! : value
      hash
    end)
  end
end
