Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      post "certi/generate" => "lets_encrypts#generate_certificate"
      post "certi/regenerate" => "lets_encrypts#regenerate_certificate"
      delete "certi/delete" => "lets_encrypts#delete_certificate"
    end
  end
end
