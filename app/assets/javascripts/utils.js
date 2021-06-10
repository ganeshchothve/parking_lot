// Creating new namespace for Iris to avoid conflicts with other libraries.
Iris = { utils:  {} };
Iris.utils.datepickerOptions = {
  useCurrent: false,
  icons: {
    time: 'mdi mdi-clock',
    date: 'mdi mdi-calendar',
    up: 'mdi mdi-chevron-up',
    down: 'mdi mdi-chevron-down',
    previous: 'mdi mdi-chevron-left',
    next: 'mdi mdi-chevron-right',
    today: 'mdi mdi-screenshot',
    clear: 'mdi mdi-trash',
    close: 'mdi mdi-remove'
  },
  format: 'DD/MM/YYYY'
};
Iris.utils.autoNumericOptions = {
  aSep: ',',
  aDec: '.',
  aForm: false,
  mDec: '0',
  dGroup: 2
};
Iris.utils.daterangepickerOptions = {
  opens: "left",
  parentEl: "body",
  autoUpdateInput: false,
  locale: {
    format: 'DD/MM/YYYY'
  },
  ranges: {
    'today': [moment(), moment()],
    'yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
    'tomorrow': [moment().add(1, 'days'), moment().add(1, 'days')],
    'last week': [moment().subtract(1, 'week').startOf("week"), moment().subtract(1, 'week').endOf("week")],
    'this week': [moment().startOf("week"), moment().endOf("week")],
    'last month': [moment().subtract(29, 'days'), moment()],
    'this month': [moment().startOf('month'), moment().endOf('month')]
  }

};
Iris.utils.datetimepickerOptions = {
  icons: {
    time: 'fa fa-clock',
    date: 'fa fa-calendar',
    up: 'fa fa-chevron-up',
    down: 'fa fa-chevron-down',
    previous: 'fa fa-chevron-left',
    next: 'fa fa-chevron-right',
    today: 'fa fa-screenshot',
    clear: 'fa fa-trash',
    close: 'fa fa-remove'
  }
};
