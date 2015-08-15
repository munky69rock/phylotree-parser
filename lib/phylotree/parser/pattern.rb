module PhyloTree
  class Parser
    module Pattern
      ATGC = %r{[atgcATGC]}

      REGULAR = %r{
      \(?       # unstable
      #{ATGC}   # ancestry
      \d+       # position
      #{ATGC}   # descendants
      !*        # reversion
      \)?
      }x

      IRREGULAR = %r{
      \(?                  # unstable
      (?:
       # ex: C459d
       #{ATGC}?
       \d+
       d                   # deletion

       |
      # ex: 960.XC
      \d+
        \.[\dX]?#{ATGC}+   # insertion
        d?                 # deletion

        |
      # ex: 59-60d
      \d+\-\d+d            # range

      |
      # ネームスペースだけ予約？
      reserved
      )
      !*                      # reversion
      \)?
      }x

      EXCEPTIONS = Regexp.union(%w{
      T65d G71d A249d C299d C309d A337d
      T455d C456d C459d C498d C960d
      A1409d A1656d A2074d A2395d A4317d
      A5752d A5894d C5899d C7471d T15944d
      A16166d C16187d C16193d C16257d T16325d

      59-60d 105-110d 106-111d 290-291d 291-294d 8281-8289d

      573.XC 960.XC 965.XC 5899.XC 8278.XC  5899.XCd!

      44.1C 5899.1C 459.1C 15944.1T
      374.1A 455.1T 2232.1A 16259.1A
      595.1C 1719.1G 3172.1C 191.1A
      2156.1A 55.1T 65.1T 60.1T 42.1G
      12310.1A 291.1A 5752.1A 310.1T
      597.1T 3229.1A 2405.1C 8276.1C
      2484.1C 745.1T 498.1C 16169.1C
      5899.1C 8279.1T 5740.1A 960.1C
      3307.1A 93.1T 456.1T 356.1C
      3158.1T

      44.1C 55.1T 60.1T 65.1T 93.1T
      191.1A 291.1A 310.1T 356.1C 374.1A
      455.1T 456.1T 459.1C 498.1C 595.1C
      597.1T 745.1T 960.1C 1719.1G 2156.1A
      2232.1A 2405.1C 2484.1C 3158.1T 3172.1C
      3229.1A 3307.1A 5740.1A 5752.1A 5899.1C
      5899.1C 8276.1C 8279.1T 12310.1A 15944.1T
      16169.1C 16259.1A
      C5899.1d!  459.1Cd!
      60.1TT 292.1AT 368.1AGAA
      8289.1CCCCCTCTA 8289.1CCCCCTCTACCCCCTCTA

      455.2T 2232.2A

      (573.XC) (745.1T) (960.1C)
      (C965d) (C16193d)
      reserved
                                })

      BRANCH_CONDITION = %!
      (?:
      #{REGULAR}
       |
      #{EXCEPTIONS}
      )
      !

      BRANCH_CONDITIONS = %r{
      \A
      #{BRANCH_CONDITION}
      (?:\s#{BRANCH_CONDITION})*
        \z
      }x

      TABLE_TITLE = %r{mt\-MRCA}

      class << self
        def irregular?(text)
          !text[%r{\A#{IRREGULAR}\z}].nil?
        end

        def table_title?(text)
          !text[TABLE_TITLE].nil?
        end

        def branch_conditions?(text)
          !text[BRANCH_CONDITIONS].nil?
        end
      end
    end
  end
end
