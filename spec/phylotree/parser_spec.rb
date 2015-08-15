require 'spec_helper'
require 'nokogiri'
require 'json'

describe PhyloTree::Parser do
  let(:src_file)  { File.expand_path('../../src/mtDNA tree Build 16.htm', __FILE__) }
  let(:parsed_json_file) { File.expand_path('../../src/phylotree.json', __FILE__) }
  let(:parsed_array_json_file) { File.expand_path('../../src/phylotree_array.json', __FILE__) }
  let(:expected_json)  { JSON.parse(File.read(parsed_json_file), symbolize_names: true) }
  let(:expected_array_json)  { JSON.parse(File.read(parsed_array_json_file), symbolize_names: true) }
  let(:parser) { PhyloTree::Parser.new(src_file) }

  describe '#prettify' do
    before { parser.parse }

    it 'should be same' do
      expect(parser.prettify).to eq(expected_json)
    end
  end

  describe '#prettify_to_array' do
    before { parser.parse }

    def sort_array_json(json)
      new_json = []
      json.each do |ar|
        new_json << ar.map do |h|
          h.sort
        end
      end
      new_json.sort{ |a,b| a.map{ |h| h[1][1] }.join('-') <=>  b.map{ |h| h[1][1] }.join('-') }
    end

    it 'should be same' do
      expect(sort_array_json(parser.prettify_to_array).to_json).to eq(sort_array_json(expected_array_json).to_json)
    end
  end

  describe '#extract_example_accessions' do
    let(:cols) { ['L1b1a', 'T5393C ', '', '', 'JN214480', ''] }
    
    it 'should extract only example_accessions' do
      expect(parser.send(:extract_example_accessions, cols)).to eq(%w(JN214480))
    end
  end
  
  describe '#detect_haplogroup' do
    let(:candidates) { %w(L1b1a JN214480) }
    let(:example_accessions) { %w(JN214480) }
    
    it 'should return haplogroup' do
      expect(parser.send(:detect_haplogroup, candidates, example_accessions)).to eq('L1b1a')
    end
    
    it 'should return BLANK_BRANCH_NAME when candidates has no valid haplogroup' do
      expect(parser.send(:detect_haplogroup, %w(), example_accessions)).to eq(PhyloTree::Parser::BLANK_BRANCH_NAME)
    end

  end
  
  describe '#in_useful_range?' do
    it 'should be true only after reading table title' do
      expect(parser.send(:in_useful_range?, 'some descriptions above ')).to be false
      expect(parser.send(:in_useful_range?, 'mt-MRCA')).to be false
      expect(parser.send(:in_useful_range?, 'tree data below')).to be true
    end
  end

  describe '#get_deep_hash' do
    let(:array) do
      [
          :depth1,
          :depth2,
          :depth3
      ]
    end
    let(:hash) do
      {
          depth1: {
              depth2: {
                  depth3: {
                      key: :value
                  }
              }
          }
      }
    end
    it 'should return specified depth hash element' do
      expect(parser.send(:get_deep_hash, hash, array, (0..2).to_a)).to eql({ key: :value })
    end
  end

  describe '#grow_tree' do
    let(:haplogroup) { 'B' }
    let(:conditions) { ['A1234T'] }
    let(:example_accessions) { ['ex1'] }
    let(:depth) { 3 }

    before do
      parser.instance_variable_set(:@raw_tree, {
                                                 depth1: {
                                                     depth2: {}
                                                 }
                                             })
      parser.instance_variable_set(:@queue, [:depth1, :depth2])
      parser.send(:grow_tree, haplogroup, conditions, example_accessions, 2)
    end

    it 'should update specified node' do
      expect(parser.send(:get_deep_hash,
                 parser.instance_variable_get(:@raw_tree),
                 parser.instance_variable_get(:@queue),
                 (0..2).to_a
             )).to eq({
                          __SELF__: {
                            conditions: conditions,
                            example_accessions: example_accessions
                          }
                      })
    end
  end
end

describe PhyloTree::Parser::Pattern do
  let(:pattern) { PhyloTree::Parser::Pattern }

  describe 'irregular?' do
    let(:irregulars) { %w(44.1C A16166d 59-60d 573.XC reserved) }
    let(:regular) { 'A1234T' }

    it 'should be irregular' do
      irregulars.each do |irregular|
        expect(pattern.irregular?(irregular)).to be true
      end
    end

    it 'should not be irregular' do
      expect(pattern.irregular?(regular)).to be false
    end
  end

  describe 'branch_conditions?' do
    let(:condition) { 'C152T T2887C G3010A C5060T G7830A' }
    let(:not_condition) { "L1'2'3'4'5'6" }

    it 'should judge condition pattern' do
      expect(pattern.branch_conditions?(condition)).to be true
      expect(pattern.branch_conditions?(not_condition)).to be false
    end
  end
end
