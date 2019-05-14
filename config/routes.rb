Rails.application.routes.draw do
  # routes for Hist
  mount Hist::Engine => '/hist'

  mount Ckeditor::Engine => '/ckeditor'

  resources :homosaurus_v2

  # Generic file routes
  resources :generic_objects, path: :files, except: :index do
    collection do
      get 'batch_edit'
      post 'batch_add'
      post 'batch_replace'
      post 'batch_delete'
    end
    member do
      get 'stats'
      get 'citation'
      get 'swap_visibility'
      get 'regenerate_thumbnail'
      get 'make_coll_image'
    end
  end

  scope module: 'admin', path: '/admin', as: 'admin' do
    get 'carousel_edit', to: 'admin#carousel_edit', as: :carousel_edit
    post 'carousel_update', to: 'admin#carousel_update', as: :carousel_update
  end

  # Collection routes
  resources :collections, path: :col, only: [:show, :index, :new, :edit, :create, :update, :destroy]
  #get 'col', :to => 'collections#public_index', :as => 'collections_public'
  #get 'col/:id', :to => 'collections#public_show', :as => 'collections_public_show'
  get 'col/facet/:id', :to => 'collections#facet', :as => 'collections_facet'
  # Added Institution Routes
  get 'ajax/cols/:id', :to => 'institutions#update_collections', :as => 'generic_files_update_collections'
  get 'ajax/cols', :to => 'institutions#update_collections', :as => 'generic_files_update_collections_no_id'

  get 'places', :to => 'catalog#map', :as => 'places'

  resources :institutions, path: :inst, only: [:show, :index, :new, :edit, :create, :update, :destroy]
  get 'inst/facet/:id', :to => 'institutions#facet', :as => 'institutions_facet'

  # Autocomplete Routes
  get '/autocomplete/creators', to: "autocomplete#creators", as: :creators_autocomplete
  get '/autocomplete/contributors', to: "autocomplete#contributors", as: :contributors_autocomplete
  get '/autocomplete/publishers', to: "autocomplete#publishers", as: :publishers_autocomplete
  get '/autocomplete/language', to: "autocomplete#languages", as: :languages_autocomplete
  get '/autocomplete/dates', to: "autocomplete#dates", as: :dates_autocomplete
  get '/autocomplete/homosaurus_subjects', to: "autocomplete#homosaurus_subject", as: :homosaurus_subject_autocomplete
  get '/autocomplete/geonames', to: "autocomplete#geonames_subject", as: :geonames_subject_autocomplete
  get '/autocomplete/lcsh_subjects', to: "autocomplete#lcsh_subject", as: :lcsh_subject_autocomplete
  get '/autocomplete/other_subjects', to: "autocomplete#other_subject", as: :other_subjects_autocomplete
  get '/autocomplete/exactMatch', to: "autocomplete#exact_match", as: :exact_match_autocomplete
  get '/autocomplete/closeMatch', to: "autocomplete#close_match", as: :close_match_autocomplete

  # Added Collection Routes
  get 'collections/members_public/:id' => 'collections#members_public', as: :collection_member_public
  get 'collections/members_private/:id' => 'collections#members_private', as: :collection_member_private
  get 'collections/collection_invisible/:id' => 'collections#collection_invisible', as: :collection_invisible
  get 'collections/collection_visible/:id' => 'collections#collection_visible', as: :collection_visible
  get 'collections/collection_thumbnail_set/:id/:item_id' => 'collections#collection_thumbnail_set', as: :collection_thumbnail_set

  #Static Paths
  resources :abouts, only: [:new, :edit, :create, :update, :show], :path => :about
  resources :learns, only: [:new, :edit, :create, :update, :show], :path => :learn
  resources :posts, path: :news

  #get 'feedback' => 'abouts#feedback', as: :feedback
  #post 'feedback' => 'abouts#feedback'
  #get 'feedback_complete' => 'abouts#feedback_complete', as: :feedback_complete
  #get 'subscribe' => 'abouts#subscribe', as: :subscribe
  get 'feedback' => 'contact#feedback', as: :feedback
  post 'feedback' => 'contact#feedback'
  get 'feedback_complete' => 'contact#feedback_complete', as: :feedback_complete

  #get 'about' => 'about#index', as: :about
  get 'about/project' => 'abouts#project', as: :about_project
  #get 'about/news' => 'abouts#news', as: :about_news
  get 'about/team' => 'abouts#team', as: :about_team
  get 'about/board' => 'abouts#board', as: :about_board
  get 'about/poli
ies' => 'abouts#policies', as: :about_policies
  get 'about/contact' => 'abouts#contact', as: :about_contact

  get 'contact' => 'contact#index', as: :contact

  mount Blacklight::Engine => '/'
  #root to: "catalog#index"
  root to: 'homepage#index'
  devise_for :users
  mount Hydra::RoleManagement::Engine => '/'

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
  


  # advanced routes for advanced search
  get 'search' => 'advanced#index', as: :advanced
  
  resources :downloads, only: 'show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # formats browse
  get 'genre', :to => 'catalog#genre_facet', :as => 'genre_facet'

  # subject browse
  get 'topic', :to => 'catalog#topic_facet', :as => 'topic_facet'

  authenticate :user, -> (user) { user.admin? } do
    mount Blazer::Engine => '/analytics'
  end

  require 'sidekiq/web'
  require 'tilt/erb' # Required for sidekiq-statistic to work
  require 'sidekiq-statistic'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]

  resources 'oai',
            only: [:index]
end
