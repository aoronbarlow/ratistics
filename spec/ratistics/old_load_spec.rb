require 'spec_helper'

module Ratistics

  describe Load do

    let(:record_count) { 1633 }

    let(:csv_file) { File.join(File.dirname(__FILE__), '../data/race.csv') }
    let(:psv_file) { File.join(File.dirname(__FILE__), '../data/race.psv') }
    let(:csv_gz_file) { File.join(File.dirname(__FILE__), '../data/race.csv.gz') }
    let(:dat_file) { File.join(File.dirname(__FILE__), '../data/race.dat') }
    let(:dat_gz_file) { File.join(File.dirname(__FILE__), '../data/race.dat.gz') }

    let(:csv_definition) do
      [
        [:place, lambda {|i| i.to_i}],
        :div_tot,
        :div,
        :guntime,
        :nettime,
        :pace,
        [:name],
        [:age, :to_i],
        [:gender],
        [:race_num, :to_i],
        [:city_state]
      ]
    end

    let(:csv_row) do
      '1,1/362,M2039,30:43,30:42,4:57,Brian Harvey,22,M,1422,Allston MA'
    end

    let(:psv_row) do
      '1|1/362|M2039|30:43|30:42|4:57|Brian Harvey|22|M|1422|Allston MA'
    end

    let(:dat_definition) do
      [
        {:field => :place, :start => 1, :end => 6, :cast => lambda {|i| i.to_i} },
        {:field => :div_tot, :start =>  7, :end => 15},
        {:field => :div, :start =>  16, :end => 21},
        {:field => :guntime, :start =>  22, :end => 29},
        {:field => :nettime, :start =>  30, :end => 38},
        {:field => :pace, :start =>  39, :end => 44},
        {:field => :name, :start =>  45, :end => 67},
        {:field => :age, :start =>  68, :end => 70, :cast => :to_i},
        {:field => :gender, :start =>  71, :end => 72},
        {:field => :race_num, :start =>  73, :end => 78, :cast => :to_i},
        {:field => :city_state, :start =>  79, :end => 101},
      ]
    end

    let(:dat_row) do
      '    1   1/362  M2039   30:43   30:42   4:57 Brian Harvey           22 M  1422 Allston MA              '
    end

    let(:record_array) do
      [
        '1',
        '1/362',
        'M2039',
        '30:43',
        '30:42',
        '4:57',
        'Brian Harvey',
        '22',
        'M',
        '1422',
        'Allston MA',
      ]
    end

    let(:record_hash) do
      {
        :place => 1,
        :div_tot => '1/362',
        :div => 'M2039',
        :guntime => '30:43',
        :nettime => '30:42',
        :pace => '4:57',
        :name => 'Brian Harvey',
        :age => 22,
        :gender => 'M',
        :race_num => 1422,
        :city_state => 'Allston MA',
      }
    end

    let(:record_catalog) do
      [
        [:place, 1],
        [:div_tot, '1/362'],
        [:div, 'M2039'],
        [:guntime, '30:43'],
        [:nettime, '30:42'],
        [:pace, '4:57'],
        [:name, 'Brian Harvey'],
        [:age, 22],
        [:gender, 'M'],
        [:race_num, 1422],
        [:city_state, 'Allston MA'],
      ]
    end

    context 'CSV files' do

      context '#csv_record' do

        it 'loads a record without a definition' do
          record = Ratistics::Load.csv_record(csv_row)
          record.should eq record_array
        end

        it 'loads a record with a definition' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition)
          record.should eq record_hash
        end

        it 'ignores an array record without a definition' do
          record = Ratistics::Load.csv_record(record_array)
          record.should eq record_array
        end

        it 'loads an array record with a definition' do
          record = Ratistics::Load.csv_record(record_array, def: csv_definition)
          record.should eq record_hash
        end

        it 'ignores extra fields not in the definition' do
          definition = [:place]
          record = Ratistics::Load.csv_record(csv_row, def: definition)
          record.should == {:place => '1'}
        end

        it 'accepts any data type for the field name' do
          definition = ['place']
          record = Ratistics::Load.csv_record(csv_row, def: definition)
          record.should == {'place' => '1'}
        end

        it 'ignores fields defined with nil' do
          definition = [
            :place,
            nil,
            :div,
          ]
          record = Ratistics::Load.csv_record(csv_row, def: definition)
          record.should == {
            :place => '1',
            :div => 'M2039',
          }
        end

        it 'accepts definition fields as arrays' do
          definition = [
            [:place],
          ]
          record = Ratistics::Load.csv_record(csv_row, def: definition)
          record.should == {:place => '1'}
        end

        it 'calls the method on every record when the second definition field element is a symbol' do
          definition = [
            [:place, :to_i],
          ]
          record = Ratistics::Load.csv_record(csv_row, def: definition)
          record.should == {:place => 1}
        end

        it 'applies the second definition field element to every record when it is a lambda' do
          definition = [
            [:place, lambda {|i| i.to_i}]
          ]
          record = Ratistics::Load.csv_record(record_array, def: definition)
          record.should == {:place => 1}
        end

        it 'supports :col_sep option' do
          record = Ratistics::Load.csv_record(psv_row, :col_sep => '|')
          record.should eq record_array
        end

        it 'recognizes quoted fields' do
          data = '1,"1/362",M2039,"30:43",30:42,"4:57","Harvey, Brian",22,M,1422,"Allston, MA"'
          result = ["1", "1/362", "M2039", "30:43", "30:42", "4:57", "Harvey, Brian", "22", "M", "1422", "Allston, MA"]
          record = Ratistics::Load.csv_record(data)
          record.should eq result
        end

        it 'supports empty fields' do
          data = '1,,1/362,M2039,"",30:43,30:42,"4:57","Harvey, Brian",22,,M,1422,Allston MA'
          record = Ratistics::Load.csv_record(data)
          record.count.should eq 14
          record.should eq ["1", "", "1/362", "M2039", "", "30:43", "30:42", "4:57", "Harvey, Brian", "22", "", "M", "1422", "Allston MA"]
        end

        it 'returns a hash when :as option is nil' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition)
          record.should eq record_hash
        end

        it 'returns a hash when :as option is :hash' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :hash)
          record.should eq record_hash
        end

        it 'returns a hash when :as option is :map' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :map)
          record.should eq record_hash
        end

        it 'returns a catalog when :as option is :array' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :array)
          record.should eq record_catalog
        end

        it 'returns a catalog when :as option is :catalog' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :catalog)
          record.should eq record_catalog
        end

        it 'returns a catalog when :as option is :catalogue' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :catalogue)
          record.should eq record_catalog
        end

        it 'returns a simple array when :as option is :frame' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :frame)
          record.should eq record_array
        end

        it 'returns a simple array when :as option is :dataframe' do
          record = Ratistics::Load.csv_record(csv_row, def: csv_definition, as: :dataframe)
          record.should eq record_array
        end
      end

      context '#csv_data' do

        let(:contents) { File.open(csv_file, 'rb').read }

        it 'loads a single record without a definition' do
          record = Ratistics::Load.csv_data(csv_row)
          record.count.should eq 1
          record.first.should eq record_array
        end

        it 'loads a single record with a definition' do
          record = Ratistics::Load.csv_data(csv_row, def: csv_definition)
          record.count.should eq 1
          record.first.should eq record_hash
        end

        it 'loads multiple records without a definition' do
          record = Ratistics::Load.csv_data(contents)
          record.count.should eq record_count
          record.first.should eq record_array
        end

        it 'loads multiple records with a definition' do
          record = Ratistics::Load.csv_data(contents, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'supports :col_sep option' do
          record = Ratistics::Load.csv_data(psv_row, :col_sep => '|')
          record.count.should eq 1
          record.first.should eq record_array
        end

        it 'supports :row_sep option' do
          data = csv_row + '|' + csv_row + '|' + csv_row 
          record = Ratistics::Load.csv_data(data, :row_sep => '|')
          record.count.should eq 3
          record.first.should eq record_array
        end

        it 'recognizes quoted fields' do
          data = '1,"1/362",M2039,"30:43",30:42,"4:57","Harvey, Brian",22,M,1422,"Allston, MA"'
          result = ["1", "1/362", "M2039", "30:43", "30:42", "4:57", "Harvey, Brian", "22", "M", "1422", "Allston, MA"]
          record = Ratistics::Load.csv_data(data)
          record.count.should eq 1
          record.first.should eq result
        end

        it 'skips the first line when :headers option is true' do
          record = Ratistics::Load.csv_data(contents, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
        end

        it 'uses the header line for the definition when :headers option is true without a definition' do
          record = Ratistics::Load.csv_data(contents, :headers => true)
          record.count.should eq record_count-1
          record_array.size.should eq record.first.keys.size
          record.first.keys.each do |key|
            record_array.should include(key.to_s)
          end
        end

        it 'uses the provided definition instead of the header line when :headers option is true' do
          record = Ratistics::Load.csv_data(contents, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
          record.first.keys.should eq record_hash.keys
        end

        it 'returns a hash when :as option is nil' do
          record = Ratistics::Load.csv_data(contents, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'returns a hash when :as option is :hash' do
          record = Ratistics::Load.csv_data(contents, as: :hash, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'returns a hash when :as option is :map' do
          record = Ratistics::Load.csv_data(contents, as: :map, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'returns a catalog when :as option is :array' do
          record = Ratistics::Load.csv_data(contents, as: :array, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_catalog
        end

        it 'returns a catalog when :as option is :catalog' do
          record = Ratistics::Load.csv_data(contents, as: :catalog, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_catalog
        end

        it 'returns a catalog when :as option is :catalogue' do
          record = Ratistics::Load.csv_data(contents, as: :catalog, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_catalog
        end

        it 'returns a simple array when :as option is :frame' do
          record = Ratistics::Load.csv_data(contents, as: :frame, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_array
        end

        it 'returns a simple array when :as option is :dataframe' do
          record = Ratistics::Load.csv_data(contents, as: :dataframe, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_array
        end

        context 'with Hamster', :hamster => true do

          let(:contents) { csv_row }

          it 'returns a Ruby Array when no :hamster option is given' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition)
            records.should be_kind_of Array
          end

          it 'returns a Ruby Array when the :hamster option is set to false' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => false)
            records.should be_kind_of Array
          end

          it 'returns a Hamster::Vector when the :hamster option is set to true' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => true)
            records.should be_kind_of Hamster::Vector
          end

          it 'returns a Hamster::List when the :hamster option is set to :list' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :list)
            records.should be_kind_of Hamster::List
          end

          it 'returns a Hamster::Stack when the :hamster option is set to :stack' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :stack)
            records.should be_kind_of Hamster::Stack
          end

          it 'returns a Hamster::Queue when the :hamster option is set to :queue' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :queue)
            records.should be_kind_of Hamster::Queue
          end

          it 'returns a Hamster::Set when the :hamster option is set to :set' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :set)
            records.should be_kind_of Hamster::Set
          end

          it 'returns a Hamster::Vector when the :hamster option is set to :vector' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :vector)
            records.should be_kind_of Hamster::Vector
          end

          it 'returns a Hamster::Vector when the :hamster option is set to an unknown type' do
            records = Ratistics::Load.csv_data(contents, def: csv_definition, :hamster => :bogus)
            records.should be_kind_of Hamster::Vector
          end
        end
      end

      context '#csv_file' do

        it 'loads records without a definition' do
          record = Ratistics::Load.csv_file(csv_file)
          record.count.should eq record_count
          record.first.should eq record_array
        end

        it 'loads records with a definition' do
          record = Ratistics::Load.csv_file(csv_file, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'supports :col_sep option' do
          record = Ratistics::Load.csv_file(psv_file, :col_sep => '|')
          record.count.should eq record_count
          record.first.should eq record_array
        end

        it 'skips the first line when :headers option is true' do
          record = Ratistics::Load.csv_file(csv_file, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
        end

        it 'uses the header line for the definition when :headers option is true without a definition' do
          record = Ratistics::Load.csv_file(csv_file, :headers => true)
          record.count.should eq record_count-1
          record_array.size.should eq record.first.keys.size
          record.first.keys.each do |key|
            record_array.should include(key.to_s)
          end
        end

        it 'uses the provided definition instead of the header line when :headers option is true' do
          record = Ratistics::Load.csv_file(csv_file, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
          record.first.keys.should eq record_hash.keys
        end

        it 'supports the :hamster option', :hamster => true do
          records = Ratistics::Load.csv_file(csv_file, def: csv_definition, :hamster => true)
          records.should be_kind_of Hamster::Vector
          records.size.should eq record_count
        end
      end

      context '#csv_gz_file' do

        it 'loads records without a definition' do
          record = Ratistics::Load.csv_gz_file(csv_gz_file)
          record.count.should eq record_count
          record.first.should eq record_array
        end

        it 'loads records with a definition' do
          record = Ratistics::Load.csv_gz_file(csv_gz_file, def: csv_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'skips the first line when :headers option is true' do
          record = Ratistics::Load.csv_gz_file(csv_gz_file, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
        end

        it 'uses the header line for the definition when :headers option is true without a definition' do
          record = Ratistics::Load.csv_gz_file(csv_gz_file, :headers => true)
          record.count.should eq record_count-1
          record_array.size.should eq record.first.keys.size
          record.first.keys.each do |key|
            record_array.should include(key.to_s)
          end
        end

        it 'uses the provided definition instead of the header line when :headers option is true' do
          record = Ratistics::Load.csv_gz_file(csv_gz_file, def: csv_definition, :headers => true)
          record.count.should eq record_count-1
          record.first.should_not eq record_hash
          record.first.keys.should eq record_hash.keys
        end

        it 'supports the :hamster option', :hamster => true do
          records = Ratistics::Load.csv_gz_file(csv_gz_file, def: csv_definition, :hamster => true)
          records.should be_kind_of Hamster::Vector
          records.size.should eq record_count
        end
      end
    end

    context 'fixed-field files' do

      context '#dat_record' do

        it 'loads a record with the definition' do
          record = Ratistics::Load.dat_record(dat_row, def: dat_definition)
          record.should eq record_hash
        end

        it 'ignores data fields not in the definition' do
          definition = [{
            :field => :place,
            :start => 1,
            :end => 6,
          }]
          record = Ratistics::Load.dat_record(dat_row, def: definition)
          record.should == {:place => '1'}
        end

        it 'supports any data type for the field name' do
          definition = [{
            :field => 'place',
            :start => 1,
            :end => 6,
          }]
          record = Ratistics::Load.dat_record(dat_row, def: definition)
          record.should == {'place' => '1'}
        end

        it 'calls a method on every record when the :cast field element is a symbol' do
          definition = [{
            :field => :place,
            :start => 1,
            :end => 6,
            :cast => :to_i
          }]
          record = Ratistics::Load.dat_record(dat_row, def: definition)
          record.should == {:place => 1}
        end

        it 'applies the :cast field element to every record when it is a lambda' do
          definition = [{
            :field => :place,
            :start => 1,
            :end => 6,
            :cast => lambda {|i| i.to_i}
          }]
          record = Ratistics::Load.dat_record(dat_row, def: definition)
          record.should == {:place => 1}
        end

        it 'returns a hash when :as option is nil'

        it 'returns a hash when :as option is :hash'

        it 'returns a hash when :as option is :map'

        it 'returns a catalog when :as option is :array'

        it 'returns a catalog when :as option is :catalog'

        it 'returns a catalog when :as option is :catalogue'

        it 'returns a simple array when :as option is :array'

        it 'returns a simple array when :as option is :frame'

        it 'returns a simple array when :as option is :dataframe'
      end

      context '#dat_data' do

        let(:contents) { File.open(dat_file, 'rb').read }

        it 'loads a single record with the definition' do
          record = Ratistics::Load.dat_data(dat_row, def: dat_definition)
          record.count.should eq 1
          record.first.should eq record_hash
        end

        it 'loads multiple records with the definition' do
          record = Ratistics::Load.dat_data(contents, def: dat_definition)
          record.count.should eq record_count
          record.first.should eq record_hash
        end

        it 'returns a hash when :as option is nil'

        it 'returns a catalog when :as option is :array'

        it 'returns a catalog when :as option is :catalog'

        it 'returns a catalog when :as option is :catalogue'

        it 'returns a simple array when :as option is :array'

        it 'returns a simple array when :as option is :frame'

        it 'returns a simple array when :as option is :dataframe'

        context 'with Hamster', :hamster => true do

          let(:contents) { dat_row }

          it 'returns a Ruby Array when no :hamster option is given' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition)
            records.should be_kind_of Array
          end

          it 'returns a Ruby Array when the :hamster option is set to false' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => false)
            records.should be_kind_of Array
          end

          it 'returns a Hamster::Vector when the :hamster option is set to true' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => true)
            records.should be_kind_of Hamster::Vector
          end

          it 'returns a Hamster::List when the :hamster option is set to :list' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :list)
            records.should be_kind_of Hamster::List
          end

          it 'returns a Hamster::Stack when the :hamster option is set to :stack' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :stack)
            records.should be_kind_of Hamster::Stack
          end

          it 'returns a Hamster::Queue when the :hamster option is set to :queue' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :queue)
            records.should be_kind_of Hamster::Queue
          end

          it 'returns a Hamster::Set when the :hamster option is set to :set' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :set)
            records.should be_kind_of Hamster::Set
          end

          it 'returns a Hamster::Vector when the :hamster option is set to :vector' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :vector)
            records.should be_kind_of Hamster::Vector
          end

          it 'returns a Hamster::Vector when the :hamster option is set to an unknown type' do
            records = Ratistics::Load.dat_data(contents, def: dat_definition, :hamster => :bogus)
            records.should be_kind_of Hamster::Vector
          end
        end
      end

      context '#dat_file' do

        it 'loads records with the definition' do
          records = Ratistics::Load.dat_file(dat_file, def: dat_definition)
          records.count.should eq record_count
          records.first.should eq record_hash
        end

        it 'returns a Ruby Array' do
          records = Ratistics::Load.dat_file(dat_file, def: dat_definition)
          records.should be_kind_of Array
        end

        it 'supports the :hamster option', :hamster => true do
          records = Ratistics::Load.dat_file(dat_file, def: dat_definition, :hamster => true)
          records.should be_kind_of Hamster::Vector
          records.size.should eq record_count
        end
      end

      context '#dat_gz_file' do

        it 'loads records with the definition' do
          records = Ratistics::Load.dat_gz_file(dat_gz_file, def: dat_definition)
          records.count.should eq record_count
          records.first.should eq record_hash
        end

        it 'returns a Ruby Array' do
          records = Ratistics::Load.dat_gz_file(dat_gz_file, def: dat_definition)
          records.should be_kind_of Array
        end

        it 'supports the :hamster option', :hamster => true do
          records = Ratistics::Load.dat_gz_file(dat_gz_file, def: dat_definition, :hamster => true)
          records.should be_kind_of Hamster::Vector
          records.size.should eq record_count
        end
      end

    end
  end
end