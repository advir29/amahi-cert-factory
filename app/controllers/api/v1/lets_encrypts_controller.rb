module Api
    module V1
        class LetsEncryptsController < ApplicationController
            def generate_certificate
              success = HelperMethods.generateCertificate(generate_certificate_params)
              if success
                render :json => {success: true, last_generated_at: "16 september 2019 12:00:01", expiry_date: "8 december 2019 11:59:00"}
              else
                render :json => {success: false, last_generated_at: "16 september 2019 12:00:01", expiry_date: "8 december 2019 11:59:00"}
              end
            end

            def regenerate_certificate
              render :json => {success: true, msg: "Successfully Regenerated", generated_at: "16 september 2019 12:00:01", last_generated_at: "11 july 2019 12:00:01", expiry_date: "8 december 2019 11:59:00", last_expiry_date: "26 september 2019 11:59:00"
              }
            end

            def delete_certificate
              render :json => {success: true, msg: "Successfully Deleted", data: {}}
            end

            private
            def generate_certificate_params
              params.permit(:hda_name, :domain)
            end
        end
    end
end
