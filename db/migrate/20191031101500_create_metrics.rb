class CreateMetrics < ActiveRecord::Migration[5.2]
  def change
    create_table 'metrics' do |t|
      t.integer :type
      t.decimal :amount, precision: 10, scale: 2
      t.datetime :time, precision: 6
      t.integer :year, :month, :day, :hour, :week_of_year
      t.bigint :association_1, :association_2, :association_3, :association_4, :association_5
      t.index %i[type time], name: 'on_type_and_time]'
      t.index %i[type association_1 time], name: 'on_assoc_1'
      t.index %i[type association_2 time], name: 'on_assoc_2'
      t.index %i[type association_3 time], name: 'on_assoc_3'
      t.index %i[type association_1 association_2 time], name: 'on_assoc_1_and_2'
    end
  end
end
