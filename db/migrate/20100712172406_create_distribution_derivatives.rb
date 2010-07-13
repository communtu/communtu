class CreateDistributionDerivatives < ActiveRecord::Migration
  def self.up
    create_table :distribution_derivatives do |t|
      t.integer :distribution_id
      t.integer :derivative_id

      t.timestamps
    end
    Distribution.all.each do |dist|
      Derivative.all.each do |der|
        DistributionDerivative.create({:distribution=>dist,:derivative=>der})
      end
    end
    lubuntu = Derivative.create({:name => "Lubuntu", :icon_file => "", :sudo => "gksudo", :dialog => "zenity"})
    lucid = Distribution.find_by_short_name("Lucid")
    DistributionDerivative.create({:distribution=>lucid,:derivative=>lubuntu})
  end

  def self.down
    drop_table :distribution_derivatives
  end
end
