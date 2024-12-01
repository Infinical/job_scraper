module Api
  module V1
    class JobPreferencesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_job_preference, only: [:show, :update, :destroy]

      def index
        @job_preferences = current_user.job_preferences
        render json: {
          status: { code: 200 },
          data: serialize_job_preferences(@job_preferences)
        }
      end

      def show
        render json: {
          status: { code: 200 },
          data: serialize_job_preference(@job_preference)
        }
      end

      def create
        @job_preference = current_user.job_preferences.build(job_preference_params)

        if @job_preference.save
          render json: {
            status: { code: 200, message: 'Job preference created successfully.' },
            data: serialize_job_preference(@job_preference)
          }, status: :created
        else
          render json: {
            status: { 
              code: 422, 
              message: 'Job preference could not be created.',
              errors: @job_preference.errors.full_messages 
            }
          }, status: :unprocessable_entity
        end
      end

      def update
        if @job_preference.update(job_preference_params)
          render json: {
            status: { code: 200, message: 'Job preference updated successfully.' },
            data: serialize_job_preference(@job_preference)
          }
        else
          render json: {
            status: { 
              code: 422, 
              message: 'Job preference could not be updated.',
              errors: @job_preference.errors.full_messages 
            }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @job_preference.destroy
        render json: {
          status: { code: 200, message: 'Job preference deleted successfully.' }
        }
      end

      private

      def set_job_preference
        @job_preference = current_user.job_preferences.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: 'Job preference not found.' }
        }, status: :not_found
      end

      def job_preference_params
        params.require(:job_preference).permit(keywords: [], locations: [])
      end

      def serialize_job_preference(job_preference)
        {
          id: job_preference.id,
          keywords: job_preference.keywords,
          locations: job_preference.locations,
          created_at: job_preference.created_at,
          updated_at: job_preference.updated_at
        }
      end

      def serialize_job_preferences(job_preferences)
        job_preferences.map { |jp| serialize_job_preference(jp) }
      end
    end
  end
end