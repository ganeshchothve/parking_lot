class FileIo < StringIO 
	def initialize(stream, filename) 
		super(stream) 
		@original_filename = filename 
	end 
	attr_reader :original_filename
end