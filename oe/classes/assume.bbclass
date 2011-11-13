def auto_assume_provided(d):
    try:
        oe_import(d)
    except NameError:
        pass

    import kergoth.assume as assume
    import kergoth.assumptions

    return ' '.join(assume.test_assumptions())

ASSUME_PROVIDED += "${@auto_assume_provided(d)}"
