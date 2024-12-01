module Api
  module V1
    class JobPostingsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_job_posting, only: [:show]

      def index
        @job_postings = JobPosting.all
        @job_postings = @job_postings.search_by_title(params[:title]) if params[:title].present?
        @job_postings = @job_postings.search_by_location(params[:location]) if params[:location].present?
        
        if params[:start_date].present? && params[:end_date].present?
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          @job_postings = @job_postings.created_between(start_date, end_date)
        end

        @job_postings = @job_postings.recent_first.page(params[:page]).per(20)

        render json: {
          status: { code: 200 },
          data: serialize_job_postings(@job_postings),
          meta: {
            total_count: @job_postings.total_count,
            total_pages: @job_postings.total_pages,
            current_page: @job_postings.current_page
          }
        }
      end

      def show
        render json: {
          status: { code: 200 },
          data: serialize_job_posting(@job_posting)
        }
      end

      def create
        @job_posting = JobPosting.new(job_posting_params)

        if @job_posting.save
          render json: {
            status: { code: 200, message: 'Job posting created successfully.' },
            data: serialize_job_posting(@job_posting)
          }, status: :created
        else
          render json: {
            status: { 
              code: 422, 
              message: 'Job posting could not be created.',
              errors: @job_posting.errors.full_messages 
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def set_job_posting
        @job_posting = JobPosting.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: 'Job posting not found.' }
        }, status: :not_found
      end

      def job_posting_params
        params.require(:job_posting).permit(:title, :location, :company, :description, :source_url)
      end

      def serialize_job_posting(job_posting)
        {
          id: job_posting.id,
          title: job_posting.title,
          location: job_posting.location,
          company: job_posting.company,
          description: job_posting.description,
          source_url: job_posting.source_url,
          created_at: job_posting.created_at,
          updated_at: job_posting.updated_at
        }
      end

      def serialize_job_postings(job_postings)
        job_postings.map { |jp| serialize_job_posting(jp) }
      end
    end
  end
end