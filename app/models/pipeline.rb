class Pipeline
  include Mongoid::Document
  include Mongoid::Timestamps

  field :entity_type, type: String
  field :pipeline_id, type: Integer
  field :pipeline_stage_id, type: Integer
  field :lead_closed_reason, type: String

  belongs_to :workflow

  validates :entity_type, presence: true, uniqueness: { scope: :workflow_id, message: 'is already present in a workflow' }
  def get_pipeline_stage_details user
    @pipelines_stages = Kylas::FetchPipelineStageDetails.new(user, self.pipeline_id).call
    if @pipelines_stages[:success]
      return @pipelines_stages[:data][:stages_details]
    end
  end


end