module WillPaginate::I18nViewHelpers
  def will_paginate(collection, options = {})
    super(collection,
      options.merge(
        :previous_label => "P #{I18n.t('will_paginate.previous')}",
        :next_label => "#{I18n.t('will_paginate.next')} N"
        )
      )
  end
end

ActionView::Base.send(:include, WillPaginate::I18nViewHelpers)
