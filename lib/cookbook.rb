require 'csv'
require_relative 'recipe'

class Cookbook
  def initialize(csv_file_path)
    @csv_path = csv_file_path
    @recipes = []
    load_csv
  end

  def all
    @recipes
  end

  def find(index)
    @recipes[index]
  end

  def add_recipe(recipe)
    @recipes << recipe
    save_csv
  end

  def remove_recipe(recipe_index)
    @recipes.delete_at(recipe_index)
    save_csv
  end

  def destroy_all
    @recipes = []
  end

  def save
    save_csv
  end

  private

  def save_csv
    csv_options = { force_quotes: true }
    filepath    = @csv_path
    CSV.open(filepath, 'wb', csv_options) do |csv|
      @recipes.each do |recipe|
        csv << [recipe.name, recipe.description, recipe.prep_time, recipe.difficulty, recipe.done]
      end
    end
  end

  def load_csv
    csv_options = { col_sep: ',' }
    filepath    = @csv_path

    CSV.foreach(filepath, csv_options) do |row|
      recipe = Recipe.new(row[0], row[1], row[2], row[3], row[4])
      @recipes << recipe
    end
  end
end
