Rails.application.routes.draw do

  mount Blacklight::Engine => '/'
  #root to: "catalog#index"
  root to: 'homepage#index'
  devise_for :users

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable
  end
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/files', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end
  
  # Generic file routes
  resources :generic_files, path: :files, except: :index do
    member do
      get 'stats'
    end
  end

  # advanced routes for advanced search
  get 'search' => 'advanced#index', as: :advanced
  
  resources :downloads, only: 'show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  #Static Paths
  resources :abouts, only: [:new, :edit, :create, :update, :show], :path => :about
  resources :learns, only: [:new, :edit, :create, :update, :show], :path => :learn

  get 'feedback' => 'abouts#feedback', as: :feedback
  post 'feedback' => 'abouts#feedback'
  get 'feedback_complete' => 'abouts#feedback_complete', as: :feedback_complete
  get 'subscribe' => 'abouts#subscribe', as: :subscribe

  #get 'about' => 'about#index', as: :about
  get 'about/project' => 'abouts#project', as: :about_project
  #get 'about/news' => 'abouts#news', as: :about_news
  get 'about/team' => 'abouts#team', as: :about_team
  get 'about/board' => 'abouts#board', as: :about_board
  get 'about/policies' => 'abouts#policies', as: :about_policies
  get 'about/contact' => 'abouts#contact', as: :about_contact

  get 'places', :to => 'catalog#map', :as => 'places'

  get 'col', :to => 'collections#public_index', :as => 'collections_public'
  get 'col/:id', :to => 'collections#public_show', :as => 'collections_public_show'
  get 'col/facet/:id', :to => 'collections#facet', :as => 'collections_facet'

  get 'inst', :to => 'institutions#public_index', :as => 'institutions_public'
  get 'inst/:id', :to => 'institutions#public_show', :as => 'institutions_public_show'
  get 'inst/facet/:id', :to => 'institutions#facet', :as => 'institutions_facet'

  # formats browse
  get 'genre', :to => 'catalog#genre_facet', :as => 'genre_facet'

  # subject browse
  get 'topic', :to => 'catalog#topic_facet', :as => 'topic_facet'

  mount Blazer::Engine => '/analytics'

  require 'sidekiq/web'
  require 'tilt/erb' # Required for sidekiq-statistic to work
  require 'sidekiq-statistic'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
end
