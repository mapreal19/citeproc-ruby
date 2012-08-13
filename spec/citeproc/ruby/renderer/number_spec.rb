require 'spec_helper'

module CiteProc
  module Ruby

    describe "Renderer#render_number" do
      let(:renderer) { Renderer.new }

      let(:node) { CSL::Style::Number.new }

      let(:item) {
        i = CiteProc::CitationItem.new(:id => 'ID-1')
        i.data = CiteProc::Item.new(:id => 'ID-1')
        i
      }

      describe 'given an empty node' do
        it 'returns an empty string for an empty item' do
          renderer.render_number(item, node).should == ''
        end

        it 'returns an empty string for an item with variables' do
          item.data.edition = 'foo'
          renderer.render_number(item, node).should == ''
        end
      end

      describe 'given a node with a variable' do
        before(:each) { node[:variable] = :edition }

        it 'returns an empty string for an empty item' do
          renderer.render_number(item, node).should == ''
        end

        describe 'and an item with a corresponding text value' do
          before(:each) { item.data.edition = 'foo,bar' }

          it 'returns the text value as is' do
            renderer.render_number(item, node).should == 'foo,bar'
          end
        end

        describe 'and an item with a simple number' do
          before(:each) { item.data.edition = '42' }

          it 'returns the number as a string' do
            renderer.render_number(item, node).should == '42'
          end
          
          describe 'when the node is set to roman' do
            before(:each) { node[:form] = :roman }
            
            it 'returns the number romanized' do
              renderer.render_number(item, node).should == 'xlii'
            end
          end
          
          describe 'when the node is set to ordinal' do
            before(:each) { node[:form] = :ordinal }
            
            it 'returns the number ordinalized' do
              renderer.render_number(item, node).should == '42nd'
            end
          end
          
        end

        describe 'and an item with a list of numbers' do
          before(:each) { item.data.edition = '42, 43 , 44 ,45,46   , 47,  48' }

          it 'returns the numbers as a normalized list' do
            renderer.render_number(item, node).should == '42, 43, 44, 45, 46, 47, 48'
          end
          
          describe 'when the node is set to roman' do
            before(:each) { node[:form] = :roman }
            
            it 'returns the romanized list' do
              renderer.render_number(item, node).should == 'xlii, xliii, xliv, xlv, xlvi, xlvii, xlviii'
            end
          end
          
          describe 'when the node is set to ordinal' do
            before(:each) { node[:form] = :ordinal }
            
            it 'returns the ordinalized list' do
              renderer.render_number(item, node).should == '42nd, 43rd, 44th, 45th, 46th, 47th, 48th'
            end
          end
        end

        describe 'and an item with a list of ranges' do
          before(:each) { item.data.edition = '42-44, 46 -51 & 52 - 65& 66- 68' }

          it 'returns the numbers as a normalized list' do
            renderer.render_number(item, node).should == '42-44, 46-51 & 52-65 & 66-68'
          end
        end

        describe 'and an item with complex numeric values' do
          before(:each) { item.data.edition = 'A42 - B44, 46-51 & 52-65ff' }

          it 'returns the numbers as a normalized list' do
            renderer.render_number(item, node).should == 'A42-B44, 46-51 & 52-65ff'
          end
          
          describe 'when the node is set to roman' do
            before(:each) { node[:form] = :roman }
            
            it 'returns the list with only the simple numbers romanized' do
              renderer.render_number(item, node).should == 'A42-B44, xlvi-li & lii-65ff'
            end
          end
        end

      end
    end

  end
end
