#--
# CiteProc-Ruby
# Copyright (C) 2009-2011 Sylvester Keil <sylvester.keil.or.at>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.
#++

module CSL
  
  module Formatting
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def format
      @format || CSL::Format::Default
    end

    def format=(formatter)
      @format = CSL::Format.const_get(formatter.to_s.split(/[\s_-]+/).map(&:capitalize).join)
    rescue Exception => e
      CiteProc.log.warn "failed to set format to #{formatter}: #{e.message}."
    end
    
    def apply_format(input)
      return input if input.to_s.empty?
      
      formatter = format.new
      formatter.input = input

      Node.formatting_attributes.each do |attribute|
        method_id = ['set', attribute.gsub(/-/, '_')].join('_')

        if attributes.has_key?(attribute) && formatter.respond_to?(method_id)
          formatter.send(method_id, attributes[attribute])
        end
      end
      
      formatter.finalize
    end

    module ClassMethods
          
      # Chains the format method to the given methods
      def format_on(*args)
        args = args.shift if args.first.is_a?(Array)
        args.each do |method_id|
          
          # Set up Around Alias Chain
          original_method = [method_id, 'without_formatting'].join('_')
          alias_method original_method, method_id
          
          define_method method_id do |*args, &block|
            apply_format(send(original_method, *args, &block))            
          end
        end
      end
      
    end    
  end
  
  module Format
    
    class Default

      attr_accessor :input
      
      def finalize
        @input
      end
      
      def set_prefix(prefix)
        @input = [prefix, @input].join
      end

      def set_suffix(suffix)
        @input = [@input, suffix].join
      end
      
      # @param display 'block', 'left-margin', 'right-inline', 'inline'
      def set_display(display)
      end
      
      def set_strip_periods(strip)
        @input = strip && strip != 'false' ? @input.gsub(/\./, '') : @input
      end
            
      # @param style 'normal', 'italic', 'oblique' 
      def set_font_style(style='normal')
      end
      
      # @param variant 'normal', 'small-caps'
      def set_font_variant(variant='normal')
        @input = variant == 'small-caps' ? @input.upcase : @input
      end
   
      # @param weight 'normal', 'bold', 'light' 
      def set_font_weight(weight='normal')
      end

      # @param decoration 'none', 'underline'
      def set_text_decoration(decoration='none')
      end

      # @param align 'baseline', 'sub', 'sup' 
      def set_vertical_align(align='baseline')
      end

      # @param case 'lowercase', 'uppercase', 'capitalize-first', 'capitalize-all', 'title', 'sentence'
      def set_text_case(text_case)
        case text_case
        when 'lowercase'
          @input = @input.downcase
          
        when 'uppercase'
          @input = @input.upcase
          
        when 'capitalize-first'
          @input = @input.capitalize
          
        when 'capitalize-all'
          @input = @input.split(/(\s+)/).map(&:capitalize).join
          
        # TODO 'title' must be localized
        when 'title'
          @input = @input.capitalize.split(/(\s+)/).map { |word| word.match(/^(and|of|in|is|a|an|the)$/) ? word : word.capitalize }.join

        # TODO
        when 'sentence'
          @input = @input.capitalize
        else
          # nothing
        end
      end

    end
    
  end
end