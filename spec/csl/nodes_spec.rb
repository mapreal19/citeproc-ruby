
CSL::Tests::NodeFixtures.each do |fixture|
  
  describe fixture['class'] do
    before(:each) do
      @style = CSL::Style.new
      @locale = CSL::Locale.new
    end

    fixture['describe'].keys.each do |part|
      describe part do
        fixture['describe'][part].keys.each do |feature|
          it feature do
            
            item = CSL::Item.new(fixture['describe'][part][feature]['item'])
            
            input = fixture['describe'][part][feature]['input']
            
            expected = fixture['describe'][part][feature]['expected']
            
            result = input.map do |xml|
              node = CSL.const_get(fixture['class'].split(/::/).last).new(Nokogiri::XML(xml).root, @style)
              node.process(item, @locale)
            end
            
            result.should == expected
            
          end
        end
      end
    end
    
  end
  
end

describe CSL::Text do
  
  before(:each) do
    @style = CSL::Style.new
    @locale = CSL::Locale.new
  end
  
  
  it 'can be created' do
    xml = '<text/>'
    text = CSL::Text.new(Nokogiri::XML(xml).root, @style)
    text.should_not be nil
    text.variable?.should be false
    text.macro?.should be false
  end
  
  describe 'attributes' do
    it 'are initialised correctly' do
      xml = [
        '<text term="editorial-director" plural="false" />',
        '<text term="editorial-director" plural="true" />',
        '<text term="section" form="symbol" plural="false" />',
        '<text term="section" form="symbol" plural="true" />']

      expected = [true, 'editorial-director', false, nil, false, 'false',
        true, 'editorial-director', false, nil, true, 'true',
        true, 'section', true, 'symbol', false, 'false',
        true, 'section', true, 'symbol', true, 'true']

      result = xml.map { |t|
        item = CSL::Item.new
        text = CSL::Text.new(Nokogiri::XML(t).root, @style)
        [text.term?, text.term, text.form?, text.form, text.plural?, text.plural]
      }.flatten

      result.should == expected
    end
  end

end

describe CSL::Number do
  
  before(:each) do
    @style = CSL::Style.new
    @locale = CSL::Locale.new
    @item = CSL::Item.new do |item|
      item.issue = 1
      item.volume = 2
      item.edition = 3
      item.number = 23
    end
  end
  
  
  it 'can be created' do
    xml = '<number/>'
    number = CSL::Number.new(Nokogiri::XML(xml).root, @style)
    number.should_not be nil
    number.form?.should be false
    number.variable?.should be false
  end

end