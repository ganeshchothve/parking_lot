module Mongoid
  module Autoinc
    class Incrementor
      def update
        if seed
          if exists?
            find.find_one_and_update({c: seed}, upsert: true, return_document: :after).fetch('c')
          else
            create
          end
        end
      end
    end
  end
end
