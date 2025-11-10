# app/api/api/v1/inquiries.rb
module Api
  module V1
    class Inquiries < Grape::API
      resource :inquiries do

        # GET /api/v1/inquiries
        # desc 'List all inquiries'
        # get do
        #   inquiries = Inquiry.order(created_at: :desc)
        #   present inquiries, with: Api::Entities::Inquiry
        # end

        # GET /api/v1/inquiries/:id
        # desc 'Show a single inquiry'
        # params do
        #   requires :id, type: Integer, desc: 'Inquiry ID'
        # end
        # get ':id' do
        #   inquiry = Inquiry.find(params[:id])
        #   present inquiry, with: Api::Entities::Inquiry
        # end

        # POST /api/v1/inquiries
        desc 'Create a new inquiry'
        params do
          requires :full_name, type: String
          requires :email, type: String
          requires :location, type: String
          requires :event_type, type: String
          optional :role, type: String
          optional :event_date, type: Date
          optional :event_location, type: String
          optional :budget, type: String
          optional :instagram, type: String
          optional :source, type: String
          requires :message, type: String
        end
        post do
          inquiry = Inquiry.create!(declared(params))
          status 201
          present inquiry, with: Api::Entities::Inquiry
        end

        # PUT /api/v1/inquiries/:id
        # desc 'Update an inquiry'
        # params do
        #   requires :id, type: Integer
        #   optional :full_name, type: String
        #   optional :email, type: String
        #   optional :location, type: String
        #   optional :event_type, type: String
        #   optional :role, type: String
        #   optional :event_date, type: Date
        #   optional :event_location, type: String
        #   optional :budget, type: String
        #   optional :instagram, type: String
        #   optional :source, type: String
        #   optional :message, type: String
        #   at_least_one_of :full_name, :email, :location, :event_type, :role,
        #                   :event_date, :event_location, :budget,
        #                   :instagram, :source, :message
        # end
        # put ':id' do
        #   inquiry = Inquiry.find(params[:id])
        #   inquiry.update!(declared(params, include_missing: false))
        #   present inquiry, with: Api::Entities::Inquiry
        # end

        # DELETE /api/v1/inquiries/:id
        # desc 'Delete an inquiry'
        # params do
        #   requires :id, type: Integer
        # end
        # delete ':id' do
        #   Inquiry.find(params[:id]).destroy
        #   status 204
        #   body false
        # end

      end
    end
  end
end
