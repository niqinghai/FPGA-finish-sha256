---------------------------------------
-- Module : SHA-256 Core
-- Revision: 0.7
-- Author : Peter Fousteris
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_helper.all;

entity sha256_core is
generic ( messageLength : integer := 3*8 );
port(
      -- Inputs
      clock : in std_logic;
      reset : in std_logic; --Active-high
      enable : in std_logic; --Active-high
      message : in std_logic_vector( 511 downto 0 );
      -- Output
      digest : out std_logic_vector( 255 downto 0 )
    );
end entity;

architecture behaviour of sha256_core is
  signal Hashes : std_logic_vector( 255 downto 0 ) := ( others => '0' ); -- A generic 256-bit register. Holds H(7-0) values.
  signal W : wordArray;
  signal a, b, c, d, e, f, g, h : std_logic_vector( 31 downto 0 ); -- Working registers.
  -- A N x 512-bit array which holds every block of the padded message.
  signal M : BlockM ( ( kCalculator( messageLength ) + messageLength + 1 + 64 )/ 512 - 1 downto 0 ) := ( (others => ( others => '0' ) ) );
  signal init, ready, padded, schedulled, hashed : boolean := false;  -- Main process flags.
 -- Main hashing process  
begin
  sha256_hash: process( clock, reset, enable )
    variable i, t, hashIt : integer := 0; -- Iterators.
    variable N : integer := 0; -- Holds total number of Message blocks.
    variable T1, T2 : std_logic_vector( 31 downto 0 ); -- Hold temporary values.
    begin
      if ( reset = '1' ) then -- Asychronous reset (positive logic).
        initializeH( Hashes, constHashes ); -- Reset initial hash values.
        digest <= (others =>'0'); -- Clear Output.
        -- Reset flags.
        ready <= false; 
        init <= true;
      elsif ( rising_edge ( clock ) and enable = '1' ) then
        -- If diggest is not estimated yet and input message is not padded.
        if ( not( ready ) and not( padded ) ) then
          N := ( kCalculator( messageLength ) + messageLength + 1 + 64 )/512; -- Count total (512-bit) blocks in the padded message.
          M <= messagePadding ( message, messageLength ); -- Get padded message to M(N) blocks.
          i := 0; -- Clear M block's pointer.
          padded <= true; -- Update current flag.
        -- If diggest is not estimated yet and padded message is not schedulled for the i'th message block.
        elsif ( not( ready ) and ( padded ) and not( schedulled ) ) then
          -- Prepare the message schedule.
          if ( t >= 0 and t <= 15 ) then 
            W( 15 - t ) <= M ( i ) ( ( ( 32*( t + 1 ) ) - 1 ) downto ( 32*t ) );
          elsif ( t >= 16 and t <= 63 ) then
            W( t ) <= std_logic_vector( unsigned( sigma1 ( W( t - 2 ) ) ) + unsigned ( W ( t - 7 ) ) + unsigned ( sigma0( W( t - 15 ) ) ) + unsigned ( W ( t - 16 ) ) );
          else
            schedulled <= true; -- Update current flag.
            initializeWork( a, b, c ,d, e, f, g, h, Hashes ); -- Initialize working registers.
            hashIt := 0; -- Set hash iterator to 0.
            hashed <= false; -- Update hash flag.
          end if;
          t := t + 1; 
        -- If current M block has not been hashed.
        elsif ( not( ready ) and ( padded ) and ( schedulled ) and not( hashed ) ) then                 
          if hashIt < 64 then
            -- The current M block is hashed as defined in 6.2.2.
            T1 := std_logic_vector ( unsigned ( h ) + unsigned ( capSigma1( e ) ) + unsigned ( ch( e, f, g ) ) + unsigned ( constK( hashIt ) ) + unsigned ( W( hashIt ) ) );
            T2 := std_logic_vector ( unsigned( maj ( a, b, c ) ) + unsigned( capSigma0 ( a ) ) );
            h <= g;
            g <= f;
            f <= e;
            e <= std_logic_vector( unsigned( d ) + unsigned( T1 ) );
            d <= c;
            c <= b;
            b <= a;
            a <= std_logic_vector( unsigned( T1 ) + unsigned( T2 ) );
            hashIt := hashIt + 1; -- Increase hash iterator.
          else
            hashed <= true; -- Update current flag.
          end if;
        -- Check for remaining M blocks to be hashed.
        elsif ( not( ready ) and ( padded ) and ( schedulled ) and ( hashed ) ) then
          updateHashes( Hashes, a, b, c ,d, e, f, g, h ); -- Update hash register values.
          if ( i + 1 < N ) then 
            i := i + 1; -- Point to next Message block.
            t := 0; -- Clear schedulle iterator.
            schedulled <= false; -- Update Schedulle flag. 
          else -- All Message block have been hashed.
            ready <= true; -- Update ready flag.
          end if;
        -- Hash process is over.
        else
          -- Update output register with the final hash value.
          digest <= setDigest ( Hashes );
        end if;     
      end if;
  end process sha256_hash;

end architecture behaviour;

------------------------------------------
