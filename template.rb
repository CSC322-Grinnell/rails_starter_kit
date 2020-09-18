# First up, we clone the repo into a temporary dir so we can access the other files
require "tmpdir"
tmpdir = Dir.mktmpdir("rails-template-")
at_exit { FileUtils.remove_entry(tmpdir) }
git clone: "https://github.com/CSC322-Grinnell/rails_starter_kit.git #{tmpdir}"
source_paths.prepend tmpdir

gem "devise"
gem "activeadmin"

run "bundle install"

environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: :development
gsub_file "config/environments/production.rb",
  /(  # .+\n)*  config\.log_level = :debug/,
  "  # Don't log debug information on production, for performance and security.\n  config.log_level = :warn"

remove_file "app/assets/stylesheets/application.css"
copy_file "app/assets/stylesheets/application.scss"
copy_file "config/initializers/content_security_policy.rb", force: true
insert_into_file "app/views/layouts/application.html.erb",
  '    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">',
  after: "<%= csp_meta_tag %>\n"

insert_into_file "app/views/layouts/application.html.erb",
  "    <%= render partial: 'layouts/navbar' %>\n",
  after: "<body>\n"
copy_file "app/views/layouts/_navbar.html.erb"

insert_into_file "app/views/layouts/application.html.erb", before: / *<%= yield %>/ do
<<-RB
    <section class="flash">
      <% if flash[:notice] %>
        <p class="alert alert-primary"><%= notice %></p>
      <% end %>
      <% if flash[:alert] %>
        <p class="alert alert-warning"><%= alert %></p>
      <% end %>
    </section>
RB
  end

inject_into_class "app/controllers/application_controller.rb", "ApplicationController", <<-RB
  private

  # Checks that a user is signed in and has admin privileges.
  # If not, ask them to sign in again.
  def authenticate_admin_user!
    unless current_user && current_user.admin?
      reset_session
      redirect_to new_user_session_path, alert: t('access_denied')
    end
  end

  # Redirects admin users to the admin dashboard on login.
  # Everyone else is sent to their recent path if it was stored,
  # or the default path otherwise.
  def after_sign_in_path_for(resource)
    if current_user.admin?
      admin_dashboard_path
    else
      stored_location_for(resource) || super
   end
  end
RB

generate "devise:install"
generate "devise", "User"
generate "devise:views"
gsub_file "app/models/user.rb",
  /(  # .+\n)*  devise :database_authenticatable, :registerable,(\n\s*)?(\s)/,
  (<<-RB
  # Other available modules are:
  # :registerable, :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
  devise :database_authenticatable,\\3
RB
  ).chomp
remove_file "test/fixtures/users.yml"

copy_file "db/migrate/add_admin_to_users.rb",
  "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_add_admin_to_users.rb"
generate "active_admin:install", "User", "--skip-users", "--skip-comments"
uncomment_lines "config/initializers/active_admin.rb", /config\.site_title_link/
uncomment_lines "config/initializers/active_admin.rb", /config\.current_user_method/
uncomment_lines "config/initializers/active_admin.rb", /config\.comments = false/
gsub_file "config/initializers/active_admin.rb",
  "# config\.authentication_method = :authenticate_user!",
  "config.authentication_method = :authenticate_admin_user!"
gsub_file "config/initializers/active_admin.rb",
  "# config.logout_link_method = :get",
  "config.logout_link_method = :delete"
copy_file "app/admin/users.rb"

append_to_file "db/seeds.rb",
  "User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password', admin: true) if Rails.env.development?\n"

generate :controller, "Pages", "home", "--no-helper", "--skip-routes", "--no-assets"
route 'root to: "pages#home"'
copy_file "app/views/pages/home.html.erb", force: true
gsub_file "test/controllers/pages_controller_test.rb",
  "get pages_home_url",
  "get root_url"

copy_file "config/locales/en.yml", force: true

after_bundle do

  run "yarn add bootstrap jquery popper"

  insert_into_file "config/webpack/environment.js", before: /module\.exports/ do
<<-JS
const webpack = require("webpack")

environment.plugins.append("Provide", new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Popper: ['popper.js', 'default']
}))

JS
  end

  copy_file "app/javascript/delete-me.js"
  copy_file "app/javascript/packs/application.js", force: true

  copy_file "PROJECT_README.md", "README.md", force: true

  rails_command "db:migrate"

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
