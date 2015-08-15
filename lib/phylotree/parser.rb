require "phylotree/parser/version"
require "phylotree/parser/pattern"

module PhyloTree
  class Parser
    class DuplicateDetectionError < StandardError; end

    BLANK_BRANCH_NAME = :__BRANCH__
    SELF_BRANCH_NAME  = :__SELF__

    def initialize(file)
      @file = file
      @in_useful_range = false
      @queue = []
      @raw_tree = {}
    end

    def parse
      parse_html.css('table').each do |table|
        parse_table(table)
      end
      self
    end

    def prettify
      self.class.prettify(@raw_tree)
    end

    def prettify_to_array
      self.class.prettify_to_array(prettify)
    end

    class << self
      def prettify(raw_tree)
        self_branch = raw_tree[SELF_BRANCH_NAME]
        descendants = {}
        raw_tree.select { |name, _| name != SELF_BRANCH_NAME }.each_pair do |name, branch|
          descendants[name] = prettify(branch)
        end
        {}.tap do |pretty_tree|
          unless self_branch.nil?
            pretty_tree[:conditions] = self_branch[:conditions]
            pretty_tree[:example_accessions] = self_branch[:example_accessions]
          end
          pretty_tree[:descendants] = descendants unless descendants.empty?
        end
      end

      def prettify_to_array(raw_tree, pretty_tree = [], parent = [])
        raw_tree[:descendants].each_pair do |name, branch|
          current = [*parent, { name: name, conditions: branch[:conditions] }]
          pretty_tree << current
          if !branch[:descendants].nil? && !branch[:descendants].empty?
            prettify_to_array(branch, pretty_tree, current)
          end
        end
        pretty_tree
      end
    end

    private

    def read_file
      File.read(@file).encode('UTF-8', 'windows-1252')
    end

    def parse_html
      Nokogiri::HTML(read_file)
    end

    def parse_table(table)
      table.css('tr').each do |tr|
        next unless in_useful_range?(tr.text)
        parse_tr(tr)
      end
    end

    def parse_tr(tr)
      cols = []
      conditions = []
      depth = 0
      haplogroup_candidates = []

      tr.css('td').each_with_index do |td, i|
        text = trim_white_space td.text
        cols << text

        next if text.nil? || text.empty?

        if Pattern.branch_conditions?(text)
          conditions = text.split(/ /)
          depth = i - 1
        else
          haplogroup_candidates << text
        end
      end

      return if conditions.nil? || conditions.empty?

      example_accessions = extract_example_accessions(cols)
      haplogroup = detect_haplogroup(haplogroup_candidates, example_accessions)
      grow_tree(haplogroup, conditions, example_accessions, depth)
    end

    def extract_example_accessions(cols)
      [].tap do |example_accessions|
        [-2, -1].each { |i| example_accessions << cols[i] if !cols[i].nil? && !cols[i].empty? }
      end
    end

    def detect_haplogroup(candidates, example_accessions)
      haplogroup = ''
      candidates.each do |candidate|
        next if example_accessions.include?(candidate)

        fail DuplicateDetectionError.new("#{haplogroup} <=> #{candidate}") if !haplogroup.nil? && !haplogroup.empty?
        warn "check if `#{candidate}' is haplogroup name or not" if Pattern.irregular?(candidate)

        haplogroup = candidate
      end
      haplogroup = BLANK_BRANCH_NAME if haplogroup.nil? || haplogroup.empty?
      haplogroup
    end

    def grow_tree(haplogroup, conditions, example_accessions, depth)
      @queue[depth] = haplogroup.to_sym
      node = get_deep_hash(@raw_tree, @queue, (0..depth).to_a)
      node[SELF_BRANCH_NAME] = {
        conditions: conditions,
        example_accessions: example_accessions
      }
    end

    def get_deep_hash(hash, array, itr)
      idx = itr.shift
      key = array[idx]
      hash[key] ||= {}
      next_hash = hash[key]
      return next_hash if itr.empty?
      get_deep_hash(next_hash, array, itr)
    end

    def trim_white_space(text)
      text.gsub(/^[[:space:]]+/, '').gsub(/[[:space:]]+$/, '').gsub(/[[:space:]]+/, ' ')
    end

    def in_useful_range?(text)
      if !@in_useful_range && Pattern.table_title?(text)
        @in_useful_range = true
        return false
      end
      @in_useful_range
    end
  end
end
