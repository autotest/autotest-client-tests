import logging
from autotest.client import test, utils
from autotest.client.shared import error


class regression(test.test):
    version = 1

    def execute(self, old, new, compare_list):
        """
        Compare two (old, new) keyvalue files

        compare_list: list of tuples ('field_name', 'regression_op')
        regression_op(a,b) return 0 if not regression, and ~0 otherwise
        """
        kv_old = utils.read_keyval(old)
        kv_new = utils.read_keyval(new)
        failed = 0
        first_regression = None
        logging.info('========= Comparison table for %30s '
                     '=========' % self.tagged_testname)
        logging.info("%20s | %10s | %10s | %10s | %10s | %s" %
                    ('field name', 'old value', 'new value',
                     'cmp res', 'status', 'cmp function'))
        for field, cmpfn in compare_list:
            if not field in kv_old:
                raise error.TestError('Cant not find field:%s in %s'
                                      % (field, old + '/keyval'))
            if not field in kv_new:
                raise error.TestError('Cant not find field:%s in %s'
                                      % (field, new + '/keyval'))
            res = cmpfn(kv_old[field], kv_new[field])
            if res:
                failed += 1
                msg = 'FAIL'
                if not first_regression:
                    first_regression = field
            else:
                msg = 'OK'
            logging.info("%20s | %10s | %10s | %5s | %5s | %s" %
                         (field, kv_old[field],
                          kv_new[field], res, msg, cmpfn))

        logging.info("========= RESULT: total:%10d failed:%10d "
                     "==================" %
                     (len(compare_list), failed))
        if failed:
            raise error.TestError('Regression found at field:%s, old:%s, new:%s ' %
                                  (first_regression,
                                   kv_old[first_regression],
                                   kv_new[first_regression]))
