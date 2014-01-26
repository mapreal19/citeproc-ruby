module CiteProc
  module Ruby

    class Renderer

      # @param item [CiteProc::CitationItem]
      # @param node [CSL::Style::Names]
      # @return [String]
      def render_names(item, node)
        return '' unless node.has_variable?

        names = node.variable.split(/\s+/).map do |role|
          [role.to_sym, item.data[role]]
        end

        names.reject! { |n| n[1].nil? || n[1].empty? }

        # Filter out suppressed names only now, because
        # we are not interested in suppressed variables
        # which are empty anyway!
        suppressed = names.reject! { |n| item.suppressed? n }

        if names.empty?
          # We also return when the list is empty because
          # of a suppression, because we do not want to
          # substitute suppressed items!
          return '' unless suppressed.nil? && node.has_substitute?

          render_substitute item, node.substitute

        else

          resolve_editor_translator_exception! names

          # Pick the names node that will be used for
          # formatting; if we are currently in substiution
          # mode, the node that is being substituted for
          # will take precedence if the current node is
          # a descendant of it.
          #
          # This makes sure that nodes in macros do not
          # use the original names node.
          #
          # When the current node has children the names
          # will not be substituted either.
          if substitution_mode? && !node.has_children? &&
            node.ancestors.include?(state.substitute)

            names_node = state.substitute

          else
            names_node = node
          end

          if names_node.has_name?
            # Make a copy of the name node and inherit
            # options from root and citation/bibliography
            # depending on current rendering mode.
            #
            # Subtle: we need to pass in the current rendering
            # node, because the node can be part of macro!
            name = names_node.name.deep_copy
            name.reverse_merge! names_node.name.inherited_name_options(state.node)
            name.et_al = names_node.et_al if names_node.has_et_al?

          else
            name = CSL::Style::Name.new
          end

          if sort_mode?
            name.merge! state.node.name_options
          end

          return count_names(names, name) if name.count?

          join names.map { |role, ns|
            if names_node.has_label?
              label = render_label(item, names_node.label[0], role)
              render_name(ns, name) << format(label, names_node.label[0])
            else
              render_name ns, name
            end

          }, names_node.delimiter(state.node)
        end
      end

      def count_names(names, node)
        names.reduce(0) do |count, (_, ns)|
          count + node.truncate?(names) ?
            node.truncate(names).length : names.length
        end
      end

      # Formats one or more names according to the
      # configuration of the passed-in node.
      # Returns the formatted name(s) as a string.
      #
      # @param names [CiteProc::Names]
      # @param node [CSL::Style::Name]
      # @return [String]
      def render_name(names, node)

        # TODO handle subsequent citation rules

        delimiter = node.delimiter

        connector = node.connector
        connector = translate('and') if connector == 'text'

        # Add spaces around connector
        connector = " #{connector} " unless connector.nil?

        rendition = case
          when node.truncate?(names)
            truncated = node.truncate(names)

            if node.delimiter_precedes_last?(truncated)
              connector = join [delimiter, connector].compact
            end

            if node.ellipsis? && names.length - truncated.length > 1
              join [
                join(truncated.map.with_index { |name, idx|
                  render_individual_name name, node, idx + 1
                }, delimiter),

                render_individual_name(names[-1], node, truncated.length + 1)

              ], node.ellipsis

            else
              others = node.et_al ?
                format(translate(node.et_al[:term]), node.et_al) :
                translate('et-al')

              connector = node.delimiter_precedes_et_al?(truncated) ?
                delimiter : ' '

              join [
                join(truncated.map.with_index { |name, idx|
                  render_individual_name name, node, idx + 1
                }, delimiter),

                others

              ], connector

            end

          when names.length < 3
            if node.delimiter_precedes_last?(names)
              connector = [delimiter, connector].compact.join('').squeeze(' ')
            end

            join names.map.with_index { |name, idx|
              render_individual_name name, node, idx + 1
            }, connector || delimiter

          else
            if node.delimiter_precedes_last?(names)
              connector = [delimiter, connector].compact.join('').squeeze(' ')
            end

            join [
              join(names[0...-1].map.with_index { |name, idx|
                render_individual_name name, node, idx + 1
              }, delimiter),

              render_individual_name(names[-1], node, names.length)

            ], connector || delimiter
          end

        format rendition, node
      end

      # @param names [CiteProc::Name]
      # @param node [CSL::Style::Name]
      # @param position [Fixnum]
      # @return [String]
      def render_individual_name(name, node, position = 1)
        if name.personal?
          name = name.dup

          # TODO move parts of the formatting logic here
          # because name parts may include particles etc.


          name.options.merge! node.name_options
          name.sort_order! node.name_as_sort_order_at?(position)

          name.initialize_without_hyphen! if node.initialize_without_hyphen?

          node.name_part.each do |part|
            case part[:name]
            when 'family'
              name.family = format(name.family, part)
            when 'given'
              name.given = format(name.initials, part)
            end
          end
        end

        format name.format, node
      end

      # @param item [CiteProc::CitationItem]
      # @param node [CSL::Style::Substitute]
      # @return [String]
      def render_substitute(item, node)
        return '' unless node.has_children?

        if substitution_mode?
          saved_substitute = state.substitute
        end

        state.substitute! node.parent
        observer = ItemObserver.new(item.data)

        node.each_child do |child|
          observer.start

          begin
            string = render(item, child)

            unless string.empty?
              # Variables rendered as substitutes
              # must be suppressed during the remainder
              # of the rendering process!
              item.suppress! *observer.accessed

              return string # break out of each loop!
            end

          ensure
            observer.stop
            observer.clear!
          end

        end

        '' # no substitute was rendered
      ensure
        state.clear_substitute! saved_substitute
      end


      private

      def resolve_editor_translator_exception!(names)

        i = names.index { |role, _| role == :translator }
        return names if i.nil?

        j = names.index { |role, _| role == :editor }
        return names if j.nil?

        return names unless names[i][1] == names[j][1]

        # rename the first instance and drop the second one
        i, j = j, i if j < i

        names[i][0] = :editortranslator
        names.slice!(j)

        names
      end
    end

  end
end
