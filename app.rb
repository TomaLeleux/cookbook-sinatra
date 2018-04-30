require "sinatra"
require "sinatra/reloader" if development?
require "pry-byebug"
require "better_errors"
require 'singleton'
require_relative 'lib/controller'
require_relative 'lib/cookbook'    # You need to create this file!

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path('..', __FILE__)
end

class RecipeBook
  def initialize
    @csv_file   = File.join(__dir__, './lib/recipes.csv')
    @cookbook   = Cookbook.new(@csv_file)
    @controller = Controller.new(@cookbook)
    @scraping = []
    @name = ""
    @preptime = ""
    @difficulty = ""
  end

  def list
    @cookbook.all
  end

  def create(args)
    name = args["name"]
    description = args["description"]
    prep_time = args["prep_time"]
    difficulty = args["difficulty"]
    recipe = Recipe.new(name, description, prep_time, difficulty, false)
    @cookbook.add_recipe(recipe)
  end

  def destroy
    display_recipes(false)
    index = @view.ask_user_for_index
    @cookbook.remove_recipe(index)
  end

  def import(filter)
    ingredient = @view.ask_user_for_ingredient
    filter ? difficulty = @view.ask_user_for_difficulty : 0
    puts 'Looking for "strawberry" on LetsCookFrench...'
    scrap_web_site(ingredient, difficulty)
    puts "Which recipe would you like to import? (enter index)"
    import_new_recipe(gets.chomp.to_i - 1)
  end

  def mark_as_done
    display_recipes(true)
    index = @view.ask_user_for_index
    recipe = @cookbook.find(index)
    recipe.mark_as_done!
    @cookbook.save
  end

  def list
    @cookbook.all
  end

  private

  def display_recipes(with_done)
    recipes = @cookbook.all
    @view.display(recipes, with_done)
  end

  def list_recipe_from_web
    @view.display_from_website(@scraping)
  end

  def scrap_web_site(ingredient, difficulty)
    if difficulty > 0
      url = "http://www.letscookfrench.com/recipes/find-recipe.aspx?s=#{ingredient}&st=1&dif=#{difficulty}"
    else
      url = "http://www.letscookfrench.com/recipes/find-recipe.aspx?s=#{ingredient}&st=1"
    end
    html_doc = load_html_doc(url)
    html_doc.search('.m_titre_resultat a')[0...5].each_with_index do |element, i|
      puts "#{i + 1} - #{element.text.strip}"
      @scraping << [element.attribute('href').value, element.text.strip]
    end
  end

  def import_new_recipe(index)
    puts "Importing #{@scraping[index][1]}"
    path = @scraping[index][0]
    html_doc = load_html_doc("http://www.letscookfrench.com/#{path}")
    html_doc.search('.fn').each { |element| @name = element.text.strip }
    html_doc.search('.preptime').each { |element| @preptime = element.text.strip }
    @difficulty = html_doc.css(".m_content_recette_breadcrumb").first.text.split('-')
    @cookbook.add_recipe(Recipe.new(@name, @name, @preptime, @difficulty[1].strip, false))
  end

  def load_html_doc(url)
    html_file = URI(url).read
    html_doc = Nokogiri::HTML(html_file)
    return html_doc
  end
end

recipe_book = RecipeBook.new()

get '/' do
  @title = "Welcome to the Cookbook!"
  @text = "What do you want to do next?"
  Choices = {'list' => "1 - List all recipes",
              'create' => "2 - Create a new recipe",
              'destroy' => "3 - Destroy a recipe",
              'import' => "4 - Import recipes from LetsCookFrench",
              'import_dif' => "5 - Import recipes from LetsCookFrench with difficulty choice",
              'done' => "6 - Mark recipe es done",
              'stop' => "7 - Stop and exit the program"}
  erb :index
end

post '/' do
  redirect to('/')
end

post '/action' do
  redirect to ('/' + params['choice'])
end

get '/list' do
  @list = recipe_book.list
  @title = "Try to list recipes"
  erb :list
end

get '/create' do
  @title = "Creation of a recipe"
  erb :create
end

post '/create' do
  recipe_book.create(params)
  redirect to('/')
end

get '/destroy' do
  @title = "Delete a recipe"
  erb :destroy
end

get '/import' do
  @title = "Import of a recipe"
  erb :import
end

get '/done' do
  erb :done
end
