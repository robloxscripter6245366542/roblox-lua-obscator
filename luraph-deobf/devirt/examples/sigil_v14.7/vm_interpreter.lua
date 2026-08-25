-- ============================================================================
-- sample_sigil.lua — Luraph v14.7 VM INTERPRETER (recovered + beautified)
--
--  Provenance : peeled statically from sample_sigil.lua (base-85 -> LZMA1),
--               no execution required. Original was 99,942 bytes on ONE line.
--  This file  : token-identical to the recovered source (whitespace only;
--               verified byte-for-byte at the token level) and parses as Luau.
--               8,006 lines. Local names (fj, tj, D, S, v, G, ...) are Luraph's
--               randomised identifiers — no original names survive obfuscation.
--
--  Structure  :
--    * Returns one big table of ~162 handler functions (the runtime helpers).
--    * Register machine: `e[]`-style register file; operands in parallel arrays.
--    * Control flow is FLATTENED: 66 `while true do` loops with binary-search
--      opcode compares (`if v>21.0 then ... else if v<21.0 then ...`) instead
--      of a straight dispatch switch. This is why the public-corpus dispatcher
--      regex does not match this build.
--    * 125 distinct opcodes are exercised by the bytecode; the recovered
--      per-build opcode map (opcodes.full.json) classifies them:
--        SETTABLE 33, TEST 14, COMPARE 14, JMP 11, ARITH 10, CALL 8,
--        NEWTABLE 8, DATAOP 8, GETTABLE 5, LOADK_N 5, LOADK_S 2, MOVE 1, ...
--    * JMP (op 286) dominates the histogram — every basic block ends in a jump.
--
--  This is the ENGINE that runs the program bytecode; the program logic itself
--  is in sample_sigil.devirtualized.lua (lifted from the bytecode).
-- ============================================================================

local R= ... ;
return ( {
  fj=function (D,D,S,v,G)
    S= #G;
    G[S+1.0] =D;
    (G) [S+2.0] =v;
    return S;
  end,tj=function (D,D,S,v,G)
    (D) [S] = (G[48] [v] ) ;
  end,dh=function (D,S)
    local v,G=21;
    while true do
      if v>21.0 then
        v=D:Ih(S,v) ;
        continue;
      else
        if v<21.0 then
          return -2,G;
        else
          if v<112.0 and v>15.0 then
            G=S[16] (R,S[10] ) ;
            v= (112) ;
          end;
        end;
      end;
    end;
    return nil;
  end,Mj=function (D,S,v,G,N,I,n,i)
    if G>93.0 then
      N=I[23] (n) ;
      return 19808,v,N,i,S;
    else
      if G<93.0 and G>69.0 then
        v=I[23] (n) ;
      else
        if G<81.0 then
          S=I[23] (n) ;
        else
          if G>81.0 and G<105.0 then
            i=D:Cj(n,I,i) ;
          end;
        end;
      end;
    end;
    return nil,v,N,i,S;
  end,Sj=function (D,S,v,G,N)
    local I,n=76;
    while true do
      if I>59.0 then
        if I<=76.0 then
          I= (59) ;
          n= ( #v[34] ) ;
        else
          I=D:ij(n,v,I,S) ;
          continue;
        end;
      elseif I~=37.0 then
        I=94;
        (v[34] ) [n+1.0] =N;
      else
        (v[34] ) [n+3.0] =G;
        break;
      end;
    end;
  end,Qj=function (D,S,v,G)
    if S then
      D:Rj(v,G) ;
    end;
  end,Vj=function (D,S,v,G,N,I)
    if S<=126.0 then
      v=D:fj(N,v,G,I) ;
    else
      D:bj(I,v) ;
      return 63903,v;
    end;
    return nil,v;
  end,hh=function (D,S,v,G)
    v[26] = (nil) ;
    (v) [27] = (nil) ;
    G= (95) ;
    while true do
      if G<95.0 then
        v[27] =D.l;
        break;
      else
        if not (G>50.0)then
        else
          G=D:Hh(S,v,G) ;
        end;
      end;
    end;
    return G;
  end,eq=function (D,D,S)
    S= (D[22417] ) ;
    return S;
  end,m=function (D,D)
    D[19] = (nil) ;
    (D) [20] = (nil) ;
    D[21] =nil;
    D[22] = (nil) ;
    (D) [23] = (nil) ;
  end,c=coroutine.wrap,W=unpack,Ah=function (D,S,v,G,N,I,n,i,P)
    repeat
      if I<126.0 then
        G=S[42] ( ) -69290;
        break;
      else
        if I>69.0 then
          I,N=D:Qh(S,N,I) ;
          continue;
        end;
      end;
    until false;
    i=S[23] (G) ;
    P= (nil) ;
    n= (nil) ;
    v=nil;
    return I,n,v,N,P,G,i;
  end,eh=function (D,S)
    local v,G= (106) ;
    while true do
      if v>44.0 then
        if not (v>65.0)then
          (S) [10] = (S[10] +2.0) ;
          v= (44) ;
        else
          v,G=D:lh(S,G,v) ;
        end;
      else
        return -2,G;
      end;
    end;
    return nil;
  end,rq=function (D,D,S)
    D= (S[22674] ) ;
    return D;
  end,Cj=function (D,D,S,v)
    v=S[23] (D) ;
    return v;
  end,X=function (D,S,v)
    S= -89128959+ (D.bq( (D.fq( (D.qq( (D.Dq(D.n[3] ,D.n[7] ) ) -v[21002] , (20) ) ) ) ) <=D.n[3]and v[21002]or D.n[2] , (20) ) ) ;
    (v) [27084] = (S) ;
    return S;
  end,Fh=function (D,D)
    return D;
  end,a=function (D,S,v,G)
    if S<88.0 then
      G[2] = {
      } ;
      return 43194,S;
    else
      if S>87.0 then
        S=D:k(v,S,G) ;
      end;
    end;
    return nil,S;
  end,S=string.byte,sh=function (D,D,S)
    S= (D[11372] ) ;
    return S;
  end,qj=function (D,D,S,v,G)
    v= (92) ;
    (S) [G] =D;
    return v;
  end,kj=function (D,D,S)
    D[9] = (S) ;
  end,g='r\101\x61\x64u8',p=setfenv,Bj=function (D,S,v,G,N,I)
    if not (v>73.0)then
      if not (v>20.0)then
        if v<=17.0 then
          G=I[50] ( ) ;
        else
          if v~=18.0 then
            G=I[36] ( ) ;
          else
            G=I[35] ( ) ;
          end;
        end;
      else
        local n=106;
        while true do
          if n~=106.0 then
            break;
          else
            n= (65) ;
            if not (v>60.0)then
              G=I[51] ( ) ;
            else
              local n= (95) ;
              while true do
                if n==95.0 then
                  n= (50) ;
                  if I[5] ==I[33]then
                    if I[35] >S then
                      (I) [53] = - ( -209) ;
                    end;
                    if not (167^194>I[38] )then
                    else
                      for S=115,226,105 do
                        if not (S>=220.0)then
                          (I) [42] ,I[52] =N,I[43]and I[51] ;
                          continue;
                        else
                          (I) [36] ,I[12] =I[42] , ( -I[52] ) ;
                          break;
                        end;
                      end;
                    end;
                  else
                    if I[5] ==I[49]then
                      while - ( -190)do
                        (I) [53] = (I[43] ) ;
                      end;
                    else
                      if v<=71.0 then
                        G=I[45] ( ) ;
                      else
                        G= ( -I[35] ( ) ) ;
                      end;
                    end;
                  end;
                else
                  if n~=50.0 then
                  else
                    break;
                  end;
                end;
              end;
            end;
            continue;
          end;
        end;
      end;
    else
      local S=104;
      while true do
        if S<104.0 then
          break;
        else
          if S>39.0 then
            if not (v>136.0)then
              if not (v<=99.0)then
                local N=50;
                while true do
                  if N==105.0 then
                    break;
                  else
                    if N==50.0 then
                      N= (105) ;
                      if v==102.0 then
                        G=I[39] ( ) ;
                      else
                        G=D:yj(I,G) ;
                      end;
                      continue;
                    end;
                  end;
                end;
              else
                G=I[37] ( ) ;
              end;
            else
              local N= (114) ;
              repeat
                if N==114.0 then
                  N,G=D:Fj(v,I,G,N) ;
                  continue;
                else
                  if N~=41.0 then
                  else
                    break;
                  end;
                end;
              until false;
            end;
            S= (39) ;
          end;
        end;
      end;
    end;
    return G;
  end,zj=function (D,D,S,v)
    S= (65) ;
    D= ( #v) ;
    return S,D;
  end,Kh=function (D,D,S)
    for v=0.0,255.0 do
      (D[2] ) [v] =S(v) ;
    end;
  end,oq=function (D,S,v)
    S= -29642+ ( ( (D.cq(v[21002] ) ) +D.n[2] <v[11202]and v[22968]or v[677] ) +v[27695] +D.n[1] +v[11112] ) ;
    (v) [23560] =S;
    return S;
  end,K='re\z  \u{0061}\x64u\0512',B=function (D,S,v,G,N)
    v[13] = (nil) ;
    G=73;
    while true do
      if G~=73.0 then
        D:_(v,S) ;
        break;
      else
        v[11] = (S[D.g] ) ;
        if not N[6843]then
          G=D:F(N,G) ;
        else
          G=D:y(G,N) ;
        end;
        continue;
      end;
    end;
    v[14] = (nil) ;
    return G;
  end,j=function ( ... )
    ( ... ) [ ... ] =nil;
  end,Xh=function (D,S,v)
    S= -268435361+ (D.Vq( (D.Vq( (D.fq( (D.Iq( (v[938] ==v[13343]and v[20931]or v[20931] ) +v[24321] ,v[677] ) ) ) ) , (v[17476] ) ) ) , (v[17476] ) ) ) ;
    v[11372] = (S) ;
    return S;
  end,Yj=function (D,S,v)
    v= (29+ ( (D.fq(D.n[5] +S[23165] +S[723] ) ) -S[6055] +S[17476] >S[22968]and S[10774]or S[20760] ) ) ;
    (S) [15579] =v;
    return v;
  end,Cq=function (D,D,S,v)
    (S) [D] =v[54] ( ) ;
  end,Z=bit32.countrz,Lj=function (D,S,v,G,N,I,n,i)
    v= (nil) ;
    S= (nil) ;
    G=nil;
    for P=6,65,59 do
      if P<65.0 then
        v,S=D:gj(v,S,n) ;
        continue;
      else
        if not (P>6.0)then
        else
          G=D:vj(G,n) ;
        end;
      end;
    end;
    N= (nil) ;
    I= (nil) ;
    i= (nil) ;
    for P=18,109,91 do
      if P~=18.0 then
        i=D:oj(S,i) ;
      else
        N,I=D:Kj(N,n,v,I) ;
      end;
    end;
    return G,v,I,N,S,i;
  end,ph=function (D,D)
    D[33] = {
    } ;
  end,i=math,Y=function (D,S,v)
    v[21002] = ( -2924701234+ ( (D.qq( (D.fq(v[20760] -D.n[1] ) ) +D.n[2] , (S) ) ) +D.n[1] >=v[20760]and D.n[3]or D.n[5] ) ) ;
    S= ( -4011062096+ (D.bq( ( (D.Vq( (D.Iq(S+v[20760] ,D.n[9] ,D.n[5] ) ) , (S) ) ) >D.n[1]and D.n[5]or D.n[8] ) >=D.n[6]and D.n[5]or D.n[1] , (S) ) ) ) ;
    v[8599] = (S) ;
    return S;
  end,Nj=function (D,S,v,G,N,I,n)
    if I==80.0 then
      N=D.D;
      I=111;
      return 54461,G,I,N;
    else
      if I==111.0 then
        G=S[35] ( ) ;
        if S[40] ~=S[46]then
          N=D:Bj(n,G,N,v,S) ;
        end;
        return 3832,G,I,N;
      end;
    end;
    return nil,G,I,N;
  end,I=string.packsize,E=string,oh=function (D,S,v,G,N)
    if S==109.0 then
      if G[12] ~=G[21]then
        D:Kh(G,v) ;
      end;
      (G) [29] =D.e;
      return 32989,S;
    else
      S=D:vh(S,G,N) ;
      return 12790,S;
    end;
    return nil,S;
  end,L="\99o\z p\u{079}",Wj=function (D,D,S,v,G)
    G[S] = (D) ;
    v=11;
    return v;
  end,b=false,t=coroutine.yield,Gj=function (D,D,S,v,G,N)
    if not (G<129.0)then
      S= ( #D) ;
      return D,63610,S;
    else
      D= (N[48] [v] ) ;
    end;
    return D,nil,S;
  end,Vq=bit32.rrotate,Vh=function (D,D,S)
    (D) [41] = (nil) ;
    D[42] = (nil) ;
    (D) [43] =nil;
    S=0;
    return S;
  end,Rh=function (D,D,S,v)
    v= (nil) ;
    D= (nil) ;
    S= (126) ;
    return v,S,D;
  end,v="r\z  \101ad\u{0069}3\z  2",rh=function (D,S,v,G,N)
    local I;
    v= (120) ;
    while true do
      I,v=D:uh(N,v,S,G) ;
      if I==50154 then
        continue;
      else
        if I==17143 then
          break;
        end;
      end;
    end;
    S[24] =D.p;
    S[25] =4.294967296E9;
    return v;
  end,Iq=bit32.bxor,kh=function (D,D,S)
    return S-D[40] ;
  end,aj=function (D,D,S,v)
    S[D] =v;
  end,zh=function (D,S,v)
    v= -3976+ ( (D.Eq( (S[30736] +S[8599] +S[11202] <=S[756]and D.n[5]or S[11112] ) -S[20760] , (S[6843] ) ) ) -S[13737] ) ;
    (S) [10774] = (v) ;
    return v;
  end,bq=bit32.lrotate,l=bit32.bxor,F=function (D,S,v)
    v= ( -67+ ( (D.Vq( (D.Vq( (D.Dq(D.n[1] ) ) -v, (S[27084] ) ) ) , (S[27084] ) ) ) -D.n[3] >=D.n[1]and S[20760]or S[6625] ) ) ;
    S[6843] =v;
    return v;
  end,k=function (D,S,v,G)
    G[1] =D.u;
    if not (not S[20760] )then
      v=D:J(S,v) ;
    else
      v= (5639546153+ ( (D.cq(D.n[7] -D.n[7] +D.n[7] ) ) -D.n[7] +D.n[9] -D.n[5] ) ) ;
      S[20760] = (v) ;
    end;
    return v;
  end,hj=function (D,D,S,v,G)
    if G~=113.0 then
      (v) [2.0] = (D) ;
      return 46413;
    else
      v[4.0] = (S) ;
    end;
    return nil;
  end,V=math.floor,M=function ( )
    return function ( )
      return {
      } ;
    end;
  end,Mq=function (D,S,v,G)
    local N;
    G= (85) ;
    while true do
      if G<79.0 then
        G= (79) ;
        (S) [28] = ( {
        } ) ;
        continue;
      elseif G>79.0 and G<98.0 then
        if S[54] ~=S[40]then
        else
          for I=16,64,48 do
            if not (I>16.0)then
              while S[7]do
                D:sj( ) ;
                return v, -1,G;
              end;
            else
              D:Xj(S) ;
            end;
          end;
        end;
        G=48;
        continue;
      else
        if G<85.0 and G>48.0 then
          N=S[42] ( ) -3152;
          G= (98) ;
          continue;
        else
          if G>85.0 then
            D:_j(S,N) ;
            break;
          end;
        end;
      end;
    end;
    local I,n,i=S[35] ( ) ~=0.0;
    for P=47,347,100 do
      if not (P<=147.0)then
        if not (P>247.0)then
          n= (S[42] ( ) -51240) ;
          continue;
        else
          i=S[23] (n) ;
        end;
      else
        if P~=47.0 then
          for P=1.0,N do
            local U;
            U=D:mj(S,U,I,N) ;
            if I then
              S[48] [P] = {
                U, (S[29] (U) )
              } ;
            else
              S[48] [P] =U;
            end;
          end;
        else
          S[8] = (I) ;
        end;
      end;
    end;
    v=nil;
    for N=96,297,19 do
      if not (N>115.0)then
        if N<=96.0 then
          S[34] =S[23] (n*3.0) ;
        else
          for P=1.0,n do
            D:Cq(P,i,S) ;
          end;
        end;
      else
        if not (N>134.0)then
          D:Aj(i,S) ;
        else
          if not (N<172.0)then
            v= (i[S[42] ( ) ] ) ;
            break;
          else
            D:Qj(I,i,S) ;
            continue;
          end;
        end;
      end;
    end;
    return v,nil,G;
  end,yh=function (D,S,v,G)
    if S[38] ~=S[33]then
      for N=104,277,67 do
        if N~=104.0 then
          return -2, (D:Fh(G) ) ;
        else
          (S) [10] = (S[10] +v) ;
          continue;
        end;
      end;
    end;
    return 5757;
  end,Dh=function (D,S)
    local v,G=35;
    while true do
      if v==35.0 then
        v,G=D:ch(S,G,v) ;
      elseif v==38.0 then
        v=77;
        (S) [10] =S[10] +2.0;
      else
        if v~=77.0 then
        else
          return -2,G;
        end;
      end;
    end;
    return nil;
  end,xj=function (D,S,v,G)
    v[52] = (function ( ... )
      local N=v[26] ("#", ... ) ;
      if N~=0.0 then
      else
        return N,v[7] ;
      end;
      return N, {
        ...
      } ;
    end) ;
    v[53] = (function (N,I)
      local n,i,P,U,c,q,W,K,j,o=N[8] ,N[11] ,N[4.0] ,N[5.0] ,N[1.0] ,N[3.0] ,N[2.0] ,N[10.0] ,N[6.0] ;
      if not (i>=3)then
        if not (i>=1)then
          o=function ( ... )
            local e,r,H,_,C,X,l=v[23] (n) ,1.0;
            local Z;
            repeat
              local T= (W[r] ) ;
              if v[38] ==v[12]then
                (v) [38] =v[33] ;
              elseif v[25] ==v[41]then
                return ;
              else
                if T<3 then
                  if T<1 then
                    if v[49] ==v[5]then
                    else
                      (e) [13.0] =e[3.0] [e[12.0] ] ;
                      r+=1.0;
                    end;
                    e[14.0] =e[12.0] +U[r] ;
                    if v[42] ~=Z then
                    else
                      if v[7] ~=99 then
                      else
                        return ;
                      end;
                    end;
                    if v[49] ~=v[25]then
                    else
                      (v) [49] = (56) ;
                    end;
                    if Z~=v[40]then
                      e[14.0] =e[3.0] [e[14.0] ] ;
                      r+=2.0;
                      e[15.0] =e[12.0] +P[r] ;
                      e[15.0] = (e[3.0] [e[15.0] ] ) ;
                      r+=2.0;
                      e[16.0] =e[12.0] +P[r] ;
                      (e) [16.0] = (e[3.0] [e[16.0] ] ) ;
                      (e) [17.0] =e[1.0] [e[13.0] ] ;
                      (e) [18.0] =e[1.0] [e[14.0] ] ;
                      e[19.0] =e[1.0] [e[15.0] ] ;
                      (e) [20.0] = (e[1.0] [e[16.0] ] ) ;
                      e[21.0] =nil;
                      e[22.0] = (e[17.0] +e[18.0] ) ;
                      r+=8.0;
                      (e) [17.0] =e[22.0] %U[r] ;
                    end;
                    r+=1.0;
                    (e) [21.0] = (v[27] (e[20.0] ,e[17.0] ) ) ;
                    r+=1.0;
                    if v[51] ==v[7]then
                    else
                      e[22.0] = (v[1] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      e[23.0] = (v[44] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      e[22.0] = (v[4] (e[22.0] ,e[23.0] ) ) ;
                      r+=1.0;
                      e[20.0] = (e[22.0] %P[r] ) ;
                      (e) [22.0] = (e[19.0] +e[20.0] ) ;
                      r+=2.0;
                      e[19.0] = (e[22.0] %P[r] ) ;
                      r+=1.0;
                      e[21.0] = (v[27] (e[18.0] ,e[19.0] ) ) ;
                      r+=1.0;
                      (e) [22.0] = (v[1] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                    end;
                    e[23.0] = (v[44] (e[21.0] ,P[r] ) ) ;
                    if v[33] ==v[12]then
                      return v[33] ;
                    end;
                    if v[38] ==v[40]then
                      if r then
                        v[41] =122;
                        return ;
                      end;
                    end;
                    if v[12] ~=v[21]then
                      r+=1.0;
                      e[22.0] = (v[4] (e[22.0] ,e[23.0] ) ) ;
                      r+=1.0;
                      (e) [18.0] =e[22.0] %P[r] ;
                      (e) [22.0] =e[17.0] +e[18.0] ;
                      r+=2.0;
                      (e) [17.0] = (v[47] (e[22.0] ,P[r] ) ) ;
                      r+=1.0;
                      (e) [21.0] = (v[27] (e[20.0] ,e[17.0] ) ) ;
                      r+=1.0;
                      (e) [22.0] = (v[1] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      e[23.0] = (v[44] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      e[22.0] = (v[4] (e[22.0] ,e[23.0] ) ) ;
                      r+=1.0;
                      e[20.0] = (e[22.0] %P[r] ) ;
                      (e) [22.0] =e[19.0] +e[20.0] ;
                      r+=2.0;
                      e[19.0] = (e[22.0] %P[r] ) ;
                      r+=1.0;
                      (e) [21.0] = (v[27] (e[18.0] ,e[19.0] ) ) ;
                      r+=1.0;
                      (e) [22.0] = (v[1] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      e[23.0] = (v[44] (e[21.0] ,P[r] ) ) ;
                      r+=1.0;
                      (e) [22.0] = (v[4] (e[22.0] ,e[23.0] ) ) ;
                      r+=1.0;
                      e[18.0] = (e[22.0] %P[r] ) ;
                      (e[1.0] ) [e[13.0] ] = (e[17.0] ) ;
                      (e[1.0] ) [e[14.0] ] = (e[18.0] ) ;
                      (e[1.0] ) [e[15.0] ] =e[19.0] ;
                      e[1.0] [e[16.0] ] =e[20.0] ;
                    end;
                    r+=5.0;
                    if v[35] ==v[12]then
                    else
                      r=c[r] ;
                    end;
                  else
                    if T~=2 then
                      if not (Z)then
                      else
                        for g,y,E in Z do
                          if g>=1.0 then
                            (y) [2] = (y) ;
                            y[3] =e[g] ;
                            y[1] =3;
                            Z[g] = (nil) ;
                          end;
                        end;
                      end;
                      return ;
                    else
                      if v[7] ==v[50]then
                        if H or v[42]then
                          v[25] ,v[38] =131+243>=v[41] , (v[40] ) ;
                          return -v[7] ;
                        end;
                        if 209 then
                          return ;
                        end;
                      end;
                      H= (false) ;
                      X+=_;
                      if _<=0.0 then
                        H=X>=l;
                      else
                        H= (X<=l) ;
                      end;
                      if not (H)then
                      else
                        if v[2] ==v[43]then
                          if v[25]then
                            (v) [5] = (v[46] ) ;
                            return v[12]or -83;
                          end;
                          return ;
                        end;
                        e[c[r] +3.0] =X;
                        r= (q[r] ) ;
                      end;
                    end;
                  end;
                else
                  if v[35] ~=v[40]then
                    if not (T<5)then
                      if v[50] ==v[25]then
                        v[43] = - ( -60) ;
                        return ;
                      else
                        if T==6 then
                          if v[40] ==v[46]then
                            return v[33] ;
                          end;
                          if v[51] ==v[25]then
                          else
                            (e) [9.0] = (P[r] ) ;
                            r+=1.0;
                          end;
                          e[10.0] =U[r] ;
                          r+=1.0;
                          (e) [11.0] =U[r] ;
                          r+=1.0;
                          C= ( {
                            [5] =C, [4] =X, [1] =l, [3] =_
                          } ) ;
                          _=e[11.0] ;
                          l=e[10.0] ;
                          X=e[9.0] -_;
                          r= (j[r] ) ;
                        else
                          X= (C[4] ) ;
                          l=C[1] ;
                          _=C[3] ;
                          C= (C[5] ) ;
                        end;
                      end;
                    else
                      if T~=4 then
                        if v[40] ==v[22]then
                          return v[35] ;
                        end;
                        H= ( {
                          ...
                        } ) ;
                        e[1.0] =H[1.0] ;
                        (e) [2.0] =H[2.0] ;
                        r+=1.0;
                        e[3.0] = (I[q[r] ] [K[r] ] ) ;
                        r+=1.0;
                        e[4.0] = (e[1.0] [K[r] ] ) ;
                        r+=1.0;
                        e[5.0] = (P[r] ) ;
                        e[6.0] =e[2.0] ;
                        r+=2.0;
                        e[7.0] =U[r] ;
                        r+=1.0;
                        C= {
                          [5] =C, [4] =X, [1] =l, [3] =_
                        } ;
                        _=e[7.0] ;
                        l=e[6.0] ;
                        X=e[5.0] -_;
                        r=j[r] ;
                      else
                        r= (c[r] ) ;
                      end;
                    end;
                  end;
                end;
              end;
              r+=1.0;
            until false;
          end;
        else
          if v[7] ~=v[5]then
          else
            if not (54)then
            else
              (v) [38] ,v[25] =103, ( (140 or 28) <v[38] ) ;
            end;
            if not (18)then
            else
              return 103;
            end;
          end;
          if i~=2 then
            o=function ( ... )
              local e,r,H,_,C,X,l,Z,T,g,y=v[23] (n) ,1.0,1.0, (v[18] ( ) ) ;
              local E;
              repeat
                local O= (W[H] ) ;
                if not (O<7)then
                  if not (O>=11)then
                    if not (O<9)then
                      if O~=10 then
                        if e[j[H] ] ==U[H]then
                        else
                          H=q[H] ;
                        end;
                      else
                        (e) [4.0] = (_[K[H] ] ) ;
                        H+=1.0;
                        (e) [5.0] =e[3.0] ;
                        H+=1.0;
                        e[4.0] =e[4.0] (e[5.0] ) ;
                        r= (4.0) ;
                        H+=1.0;
                        if e[4.0] ==P[H]then
                          H=c[H] ;
                        end;
                      end;
                    else
                      if O~=8 then
                        H= (c[H] ) ;
                      else
                        if v[45] ==v[40]then
                        else
                          (e) [4.0] = (_[K[H] ] ) ;
                          H+=1.0;
                          (e) [5.0] = (e[3.0] ) ;
                          H+=1.0;
                          e[6.0] = (U[H] ) ;
                          H+=1.0;
                        end;
                        e[4.0] =e[4.0] (e[5.0] ,e[6.0] ) ;
                        r= (4.0) ;
                        H+=1.0;
                        if v[2] ==r then
                          while -v[40]do
                            v[42] ,v[2] = ( -195) ^ ( -179) , (v[2] ) ;
                            return v[33] ;
                          end;
                          if 133 then
                            return v[35] ;
                          end;
                        else
                          if v[49] ==v[5]then
                            return 95<v[35] ;
                          else
                            if not (not e[4.0] )then
                            else
                              H=c[H] ;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if C==v[38]then
                      return ;
                    elseif not (O>=13)then
                      if O==12 then
                        (e) [4.0] = (I[j[H] ] ) ;
                        H+=1.0;
                        e[5.0] = (U[H] ) ;
                        H+=1.0;
                        (e[4.0] ) (e[5.0] ) ;
                        r=3.0;
                        H+=1.0;
                        e[4.0] =_[K[H] ] ;
                        H+=1.0;
                        e[4.0] =e[4.0] [U[H] ] ;
                        H+=1.0;
                        (e) [5.0] =U[H] ;
                        H+=1.0;
                        e[4.0] (e[5.0] ) ;
                        r= (3.0) ;
                        H+=1.0;
                        H= (c[H] ) ;
                      else
                        if v[7] ==v[41]then
                          if not (v[40] )then
                          else
                            return ;
                          end;
                        end;
                        (e) [4.0] = (U[H] ) ;
                        H+=1.0;
                        e[5.0] =U[H] ;
                        H+=1.0;
                        (e) [6.0] =U[H] ;
                        H+=1.0;
                        (e) [7.0] = #e[2.0] ;
                        H+=1.0;
                        (e) [8.0] = (U[H] ) ;
                        H+=1.0;
                        l= ( {
                          [1] =T, [3] =y, [4] =E, [5] =l
                        } ) ;
                        y=e[8.0] ;
                        T= (e[7.0] ) ;
                        E= (e[6.0] -y) ;
                        H= (j[H] ) ;
                      end;
                    else
                      if O==14 then
                        if v[12] ==v[37]then
                          (v) [2] ,v[40] =v[41] , - ( -133) ;
                        end;
                        if v[22] ~=v[46]then
                        else
                          while v[49]and -21 do
                            return ;
                          end;
                          (v) [40] ,v[12] =v[2]and v[45] , (89) ;
                        end;
                        if v[25] ~=v[46]then
                        else
                          (v) [51] = (v[51] ) ;
                        end;
                        if v[39] ~=v[2]then
                          E=l[4] ;
                          T= (l[1] ) ;
                          y= (l[3] ) ;
                          l= (l[5] ) ;
                          H+=1.0;
                          (e) [6.0] = (_[K[H] ] ) ;
                          H+=1.0;
                          e[6.0] =e[6.0] [U[H] ] ;
                          H+=1.0;
                          e[7.0] =e[4.0] ;
                          H+=1.0;
                          e[8.0] =_[U[H] ] ;
                          H+=1.0;
                          e[8.0] =e[8.0] [P[H] ] ;
                          H+=1.0;
                          (e) [9.0] = (e[4.0] ) ;
                          H+=1.0;
                          (e) [10.0] = (U[H] ) ;
                          H+=1.0;
                          r=10.0;
                          g,Z=v[52] (e[8.0] (v[22] (e,r,9.0) ) ) ;
                          g+=7.0;
                          r=g;
                          X= (0.0) ;
                          for a=8.0,g do
                            if v[38] ~=v[25]then
                            else
                              (v) [51] = (X) ;
                            end;
                            X+=1.0;
                            e[a] = (Z[X] ) ;
                          end;
                          H+=1.0;
                          (e) [6.0] =e[6.0] (v[22] (e,r,7.0) ) ;
                          r=6.0;
                          H+=1.0;
                          e[4.0] = (e[6.0] ) ;
                        end;
                        H+=1.0;
                        if v[40] ==v[43]then
                          if not (v[21] )then
                          else
                            r=v[52] ;
                          end;
                          v[50] = (v[7] ) ;
                        end;
                        if v[12] ~=v[22]then
                        else
                          if not (158)then
                          else
                            (v) [21] =v[46] ;
                            C= (v[35] ) ;
                          end;
                          v[49] =v[7] ;
                        end;
                        if r==v[37]then
                        else
                          e[6.0] =I[j[H] ] ;
                          H+=1.0;
                          (e) [7.0] = (e[5.0] ) ;
                          H+=1.0;
                          (e) [8.0] =I[c[H] ] ;
                          H+=1.0;
                          e[9.0] = (e[5.0] ) ;
                          H+=1.0;
                          e[10.0] = (U[H] ) ;
                          H+=1.0;
                          r= (10.0) ;
                          g,Z=v[52] (e[8.0] (v[22] (e,r,9.0) ) ) ;
                          g+=7.0;
                          r=g;
                          X= (0.0) ;
                          for a=8.0,g do
                            X+=1.0;
                            e[a] = (Z[X] ) ;
                          end;
                          H+=1.0;
                          (e) [6.0] =e[6.0] (v[22] (e,r,7.0) ) ;
                          r= (6.0) ;
                          H+=1.0;
                        end;
                        e[5.0] = (e[6.0] ) ;
                        H+=1.0;
                        H= (c[H] ) ;
                      else
                        e[10.0] =_[K[H] ] ;
                        H+=1.0;
                        e[10.0] = (e[10.0] [U[H] ] ) ;
                        H+=1.0;
                        (e) [11.0] =U[H] ;
                        H+=1.0;
                        e[12.0] =e[4.0] ;
                        H+=1.0;
                        (e) [13.0] =e[5.0] ;
                        H+=1.0;
                        r= (13.0) ;
                        if not (C)then
                        else
                          for a,F,M in C do
                            if not (a>=1.0)then
                            else
                              F[2] =F;
                              (F) [3] = (e[a] ) ;
                              F[1] = (3) ;
                              (C) [a] = (nil) ;
                            end;
                          end;
                        end;
                        return e[10.0] (v[22] (e,r,11.0) ) ;
                      end;
                    end;
                  end;
                else
                  if O>=3 then
                    if not (O>=5)then
                      if O~=4 then
                        if v[21] ==v[40]then
                        else
                          g= {
                            ...
                          } ;
                        end;
                        for a=1.0,q[H]do
                          e[a] =g[a] ;
                        end;
                      else
                        if v[2] ~=v[51]then
                        else
                          return 246;
                        end;
                        if v[33] ==v[36]then
                        else
                          g= (e[1.0] ) ;
                          (e) [11.0] = (g) ;
                          e[10.0] =g[P[H] ] ;
                          H+=1.0;
                          (e) [12.0] =e[9.0] ;
                          H+=1.0;
                        end;
                        e[10.0] =e[10.0] (e[11.0] ,e[12.0] ) ;
                        if v[42] ==C then
                        else
                          r=10.0;
                          H+=1.0;
                          e[11.0] =I[j[H] ] ;
                          H+=1.0;
                          (e) [12.0] = (I[c[H] ] ) ;
                          H+=1.0;
                          (e) [13.0] =e[4.0] ;
                        end;
                        H+=1.0;
                        if v[45] ~=v[46]then
                          e[14.0] = (U[H] ) ;
                          H+=1.0;
                          (e) [12.0] =e[12.0] (e[13.0] ,e[14.0] ) ;
                          r=12.0;
                        end;
                        H+=1.0;
                        if v[46] ~=v[22]then
                          (e) [13.0] = (e[10.0] ) ;
                          H+=1.0;
                          e[11.0] =e[11.0] (e[12.0] ,e[13.0] ) ;
                          r= (11.0) ;
                          H+=1.0;
                          e[4.0] =e[11.0] ;
                          H+=1.0;
                        end;
                        e[11.0] = (_[K[H] ] ) ;
                        if v[43] ~=v[2]then
                        else
                          while r do
                            return 158/222;
                          end;
                        end;
                        if v[2] ~=v[43]then
                          H+=1.0;
                          e[11.0] =e[11.0] [U[H] ] ;
                          H+=1.0;
                          (e) [12.0] = (_[U[H] ] ) ;
                          H+=1.0;
                          e[12.0] =e[12.0] [P[H] ] ;
                          H+=1.0;
                          (e) [13.0] =e[5.0] ;
                          H+=1.0;
                          e[14.0] =U[H] ;
                          H+=1.0;
                          e[12.0] =e[12.0] (e[13.0] ,e[14.0] ) ;
                          r= (12.0) ;
                          H+=1.0;
                          (e) [13.0] = (_[U[H] ] ) ;
                          H+=1.0;
                          (e) [13.0] = (e[13.0] [P[H] ] ) ;
                          H+=1.0;
                          e[14.0] = (e[4.0] ) ;
                        end;
                        H+=1.0;
                        if H==v[46]then
                          while v[25]do
                            return ;
                          end;
                        end;
                        e[15.0] = (e[10.0] ) ;
                        H+=1.0;
                        r=15.0;
                        Z,X=v[52] (e[13.0] (v[22] (e,r,14.0) ) ) ;
                        Z+=12.0;
                        r= (Z) ;
                        g= (0.0) ;
                        for a=13.0,Z do
                          g+=1.0;
                          (e) [a] =X[g] ;
                        end;
                        H+=1.0;
                        e[11.0] =e[11.0] (v[22] (e,r,12.0) ) ;
                        r= (11.0) ;
                        H+=1.0;
                        e[5.0] =e[11.0] ;
                        H+=1.0;
                        H= (c[H] ) ;
                      end;
                    else
                      if v[51] ~=v[12]then
                      else
                        if not (v[45] )then
                        else
                          return ;
                        end;
                        g= ( -36) ;
                      end;
                      if O~=6 then
                        if C~=v[2]then
                        else
                          v[36] ,v[12] =X, (v[41] ) ;
                        end;
                        if v[22] ~=v[46]then
                          (e) [10.0] =_[K[H] ] ;
                          H+=1.0;
                          (e) [10.0] = (e[10.0] [U[H] ] ) ;
                          H+=1.0;
                          e[11.0] =_[U[H] ] ;
                          H+=1.0;
                          e[11.0] = (e[11.0] [P[H] ] ) ;
                          H+=1.0;
                          e[12.0] =e[4.0] ;
                          H+=1.0;
                          e[13.0] =U[H] ;
                          H+=1.0;
                          e[11.0] =e[11.0] (e[12.0] ,e[13.0] ) ;
                          r=11.0;
                          H+=1.0;
                          g= (e[2.0] ) ;
                          e[13.0] = (g) ;
                          (e) [12.0] = (g[P[H] ] ) ;
                          H+=1.0;
                          (e) [14.0] = (e[9.0] ) ;
                          H+=1.0;
                          r= (14.0) ;
                          Z,X=v[52] (e[12.0] (v[22] (e,r,13.0) ) ) ;
                          Z+=11.0;
                          r=Z;
                          g= (0.0) ;
                          for _=12.0,Z do
                            g+=1.0;
                            e[_] =X[g] ;
                          end;
                          H+=1.0;
                          (e) [10.0] =e[10.0] (v[22] (e,r,11.0) ) ;
                          r= (10.0) ;
                          H+=1.0;
                          e[4.0] =e[10.0] ;
                          H+=1.0;
                        end;
                        e[10.0] =I[j[H] ] ;
                        H+=1.0;
                        (e) [11.0] =I[c[H] ] ;
                        H+=1.0;
                        (e) [12.0] =e[5.0] ;
                        H+=1.0;
                        e[13.0] =U[H] ;
                        H+=1.0;
                        (e) [11.0] =e[11.0] (e[12.0] ,e[13.0] ) ;
                        r=11.0;
                        H+=1.0;
                        (e) [12.0] = (e[4.0] ) ;
                        H+=1.0;
                        (e) [10.0] =e[10.0] (e[11.0] ,e[12.0] ) ;
                        r= (10.0) ;
                        H+=1.0;
                        (e) [5.0] = (e[10.0] ) ;
                        H+=1.0;
                        H=c[H] ;
                      else
                        if v[37] ~=v[12]then
                        else
                          v[7] = (v[45] ) ;
                          while true do
                            (v) [43] = (v[43] ) ;
                            C=v[21] ;
                          end;
                        end;
                        (e) [6.0] =U[H] ;
                        H+=1.0;
                        e[7.0] = (U[H] ) ;
                        H+=1.0;
                        (e) [8.0] =U[H] ;
                        H+=1.0;
                        l= {
                          [1] =T, [3] =y, [4] =E, [5] =l
                        } ;
                        y= (e[8.0] ) ;
                        T=e[7.0] ;
                        E=e[6.0] -y;
                        H=j[H] ;
                      end;
                    end;
                  else
                    if O<1 then
                      E= (l[4] ) ;
                      T= (l[1] ) ;
                      if C==v[12]then
                        if not (189)then
                        else
                          v[41] =v[37] ;
                          return v[46]or v[51] ;
                        end;
                        if v[21]then
                          return ;
                        end;
                      end;
                      if v[38] ==v[5]then
                      else
                        y= (l[3] ) ;
                        l= (l[5] ) ;
                        H+=1.0;
                        e[6.0] =U[H] ;
                      end;
                      H+=1.0;
                      (e) [7.0] = ( #e[1.0] ) ;
                      if v[38] ~=v[7]then
                        H+=1.0;
                      end;
                      (e) [8.0] = (U[H] ) ;
                      H+=1.0;
                      l= {
                        [1] =T, [3] =y, [4] =E, [5] =l
                      } ;
                      y=e[8.0] ;
                      T= (e[7.0] ) ;
                      E= (e[6.0] -y) ;
                      H= (j[H] ) ;
                    else
                      if O==2 then
                        E=l[4] ;
                        T= (l[1] ) ;
                        y=l[3] ;
                        l= (l[5] ) ;
                      else
                        g= (false) ;
                        E+=y;
                        if not (y<=0.0)then
                          g=E<=T;
                        else
                          g=E>=T;
                        end;
                        if g then
                          (e) [j[H] +3.0] = (E) ;
                          H=q[H] ;
                        end;
                      end;
                    end;
                  end;
                end;
                H+=1.0;
              until false;
            end;
          else
            o= (function ( ... )
              local e,r,H,_,C,X,l,Z,T=v[23] (n) ,1.0, (v[18] ( ) ) ;
              local g,y,E=1.0;
              repeat
                local O= (W[g] ) ;
                if not (O>=7)then
                  if O<3 then
                    if not (O>=1)then
                      if v[25] ==v[50]then
                        while v[39]do
                          return ;
                        end;
                        if v[35]then
                          v[46] ,v[51] =v[42] ,184;
                          return v[42] ;
                        end;
                      end;
                      y= (false) ;
                      E+=_;
                      if _<=0.0 then
                        y= (E>=Z) ;
                      else
                        y= (E<=Z) ;
                      end;
                      if not (y)then
                      else
                        (e) [j[g] +3.0] =E;
                        g= (c[g] ) ;
                      end;
                    else
                      if O==2 then
                        (e) [10.0] = (H[U[g] ] ) ;
                        g+=1.0;
                        e[10.0] =e[10.0] [U[g] ] ;
                        g+=1.0;
                        e[11.0] = (e[5.0] ) ;
                        g+=1.0;
                        if l then
                          for a,F in l do
                            if a>=1.0 then
                              (F) [2] = (F) ;
                              F[3] = (e[a] ) ;
                              (F) [1] = (3) ;
                              l[a] = (nil) ;
                            end;
                          end;
                        end;
                        return e[10.0] (e[11.0] ) ;
                      else
                        if v[46] ==v[42]then
                          v[39] ,v[39] =v[5] , (v[35] ) ;
                          if v[7]then
                            v[43] =v[25] ;
                          end;
                        end;
                        if v[50] ~=v[12]then
                        else
                          v[41] ,v[22] =143,221;
                        end;
                        (e) [3.0] =I[q[g] ] ;
                        g+=1.0;
                        (e) [4.0] =P[g] ;
                        g+=1.0;
                        (e[3.0] ) (e[4.0] ) ;
                        r= (2.0) ;
                        g+=1.0;
                        e[3.0] =H[U[g] ] ;
                        g+=1.0;
                        (e) [3.0] =e[3.0] [U[g] ] ;
                        g+=1.0;
                        (e) [4.0] = (U[g] ) ;
                        g+=1.0;
                        (e[3.0] ) (e[4.0] ) ;
                        r=2.0;
                        g+=1.0;
                        g= (q[g] ) ;
                      end;
                    end;
                  else
                    if O<5 then
                      if O==4 then
                        g=q[g] ;
                      else
                        if v[45] ~=v[12]then
                          (e) [8.0] = (H[U[g] ] ) ;
                          g+=1.0;
                        end;
                        (e) [8.0] =e[8.0] [U[g] ] ;
                        if v[7] ~=v[21]then
                          g+=1.0;
                          e[9.0] =H[U[g] ] ;
                          g+=1.0;
                          (e) [9.0] =e[9.0] [P[g] ] ;
                          g+=1.0;
                          (e) [10.0] =e[3.0] ;
                          g+=1.0;
                          e[11.0] =P[g] ;
                          g+=1.0;
                          (e) [9.0] =e[9.0] (e[10.0] ,e[11.0] ) ;
                          r= (9.0) ;
                          g+=1.0;
                          e[10.0] =I[q[g] ] ;
                          g+=1.0;
                          y= (e[10.0] ) ;
                          e[11.0] = (y) ;
                          (e) [10.0] = (y[U[g] ] ) ;
                          g+=1.0;
                        end;
                        e[12.0] = (e[7.0] ) ;
                        if v[52] ==v[7]then
                          while v[46]do
                            return v[39] ;
                          end;
                        end;
                        g+=1.0;
                        r=12.0;
                        C,X=v[52] (e[10.0] (v[22] (e,r,11.0) ) ) ;
                        C+=9.0;
                        r= (C) ;
                        y= (0.0) ;
                        for a=10.0,C,1 do
                          y+=1.0;
                          e[a] = (X[y] ) ;
                        end;
                        g+=1.0;
                        (e) [8.0] =e[8.0] (v[22] (e,r,9.0) ) ;
                        r= (8.0) ;
                        g+=1.0;
                        (e) [3.0] = (e[8.0] ) ;
                        g+=1.0;
                        g= (q[g] ) ;
                      end;
                    else
                      if O==6 then
                        if e[c[g] ] ==P[g]then
                        else
                          if v[38] ==v[2]then
                          else
                            g=j[g] ;
                          end;
                        end;
                      else
                        if v[22] ~=l then
                        else
                          (v) [46] =v[22]or v[33] ;
                          while v[36] <v[36]do
                            v[43] ,v[39] =198<= -176,43;
                            (v) [5] ,v[52] =v[35] , (v[45] ) ;
                          end;
                        end;
                        if v[12] ==v[43]then
                        else
                          E=T[4] ;
                          Z=T[1] ;
                          _=T[3] ;
                          T= (T[5] ) ;
                          g+=1.0;
                          (e) [4.0] =v[23] (16.0) ;
                          g+=1.0;
                          (e) [5.0] =P[g] ;
                          g+=1.0;
                          e[6.0] = (U[g] ) ;
                        end;
                        g+=1.0;
                        if v[50] ~=v[25]then
                        else
                          while v[52]do
                            return ;
                          end;
                        end;
                        if v[33] ~=v[22]then
                        elseif v[12]then
                          return v[33] ;
                        end;
                        if v[22] ==l then
                          if not ( -220>46)then
                          else
                            g=g;
                          end;
                        end;
                        if v[7] ==v[12]then
                        else
                          (e) [7.0] = (U[g] ) ;
                          g+=1.0;
                          e[8.0] =U[g] ;
                          g+=1.0;
                          e[9.0] =U[g] ;
                          g+=1.0;
                          e[10.0] = (U[g] ) ;
                          g+=1.0;
                          (e) [11.0] = (U[g] ) ;
                          g+=1.0;
                          (e) [12.0] =U[g] ;
                          g+=1.0;
                          e[13.0] =U[g] ;
                          g+=1.0;
                          e[14.0] = (U[g] ) ;
                          g+=1.0;
                          e[15.0] = (U[g] ) ;
                          g+=1.0;
                          (e) [16.0] = (U[g] ) ;
                          g+=1.0;
                          e[17.0] = (U[g] ) ;
                          g+=1.0;
                          e[18.0] = (U[g] ) ;
                          g+=1.0;
                          e[19.0] = (U[g] ) ;
                          g+=1.0;
                          e[20.0] = (U[g] ) ;
                          g+=1.0;
                          y=e[4.0] ;
                          v[3] (e,5.0,20.0,1.0,y) ;
                          g+=1.0;
                          e[5.0] = (H[U[g] ] ) ;
                          g+=1.0;
                          e[5.0] = (e[5.0] [U[g] ] ) ;
                          g+=1.0;
                          (e) [6.0] = #e[1.0] ;
                          g+=1.0;
                          e[6.0] = (e[6.0] *K[g] ) ;
                          g+=1.0;
                        end;
                        (e) [5.0] =e[5.0] (e[6.0] ) ;
                        r= (5.0) ;
                        if v[21] ==v[33]then
                        else
                          g+=1.0;
                        end;
                        e[6.0] =U[g] ;
                        if v[45] ~=v[12]then
                          g+=1.0;
                          e[7.0] = ( #e[1.0] ) ;
                          g+=1.0;
                          (e) [8.0] =U[g] ;
                        end;
                        g+=1.0;
                        if v[5] ~=v[43]then
                        else
                          (v) [36] =l;
                        end;
                        T= ( {
                          [4] =E, [1] =Z, [5] =T, [3] =_
                        } ) ;
                        _=e[8.0] ;
                        Z= (e[7.0] ) ;
                        E=e[6.0] -_;
                        g=j[g] ;
                      end;
                    end;
                  end;
                else
                  if O>=10 then
                    if not (O<12)then
                      if v[39] ==v[25]then
                        if not (v[25] )then
                        else
                          v[51] =v[5] ;
                          return ;
                        end;
                        (v) [46] ,v[2] =v[52] , (v[52] ) ;
                      else
                        if O~=13 then
                          E= (T[4] ) ;
                          Z= (T[1] ) ;
                          _=T[3] ;
                          T= (T[5] ) ;
                        else
                          y= {
                            ...
                          } ;
                          for a=1.0,q[g]do
                            (e) [a] = (y[a] ) ;
                          end;
                        end;
                      end;
                    else
                      if O~=11 then
                        (e) [6.0] =P[g] ;
                        g+=1.0;
                        (e) [7.0] = (U[g] ) ;
                        g+=1.0;
                        e[8.0] = (U[g] ) ;
                        g+=1.0;
                        T= ( {
                          [4] =E, [1] =Z, [5] =T, [3] =_
                        } ) ;
                        _=e[8.0] ;
                        Z=e[7.0] ;
                        E=e[6.0] -_;
                        g= (j[g] ) ;
                      else
                        if v[37] ==v[5]then
                        else
                          e[3.0] = (H[U[g] ] ) ;
                          g+=1.0;
                          e[4.0] =e[2.0] ;
                          g+=1.0;
                          (e) [5.0] = (P[g] ) ;
                          g+=1.0;
                          e[3.0] =e[3.0] (e[4.0] ,e[5.0] ) ;
                          r=3.0;
                          g+=1.0;
                          if not e[3.0]then
                            if r~=v[51]then
                              g=j[g] ;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if not (O<8)then
                      if v[12] ==v[37]then
                      else
                        if v[25] ==v[46]then
                          return 176;
                        elseif v[46] ==v[40]then
                          (v) [52] ,v[25] =v[2] , -v[40] ;
                        elseif O==9 then
                          e[3.0] =H[U[g] ] ;
                          g+=1.0;
                          e[4.0] = (e[2.0] ) ;
                          g+=1.0;
                          (e) [3.0] =e[3.0] (e[4.0] ) ;
                          r= (3.0) ;
                          g+=1.0;
                          if e[3.0] ~=U[g]then
                          else
                            g=q[g] ;
                          end;
                        else
                          if v[46] ==v[38]then
                            while v[41]do
                              v[35] ,v[22] =v[5] , - ( -196) ;
                            end;
                          end;
                          if v[12] ==l then
                            while - ( -106)do
                              return ;
                            end;
                          end;
                          (e) [3.0] =P[g] ;
                          g+=1.0;
                          (e) [4.0] = (U[g] ) ;
                          g+=1.0;
                          (e) [5.0] = (I[q[g] ] ) ;
                          g+=1.0;
                          e[5.0] = ( #e[5.0] ) ;
                          g+=1.0;
                          e[6.0] = (U[g] ) ;
                          g+=1.0;
                          T= ( {
                            [4] =E, [1] =Z, [5] =T, [3] =_
                          } ) ;
                          _= (e[6.0] ) ;
                          Z=e[5.0] ;
                          E=e[4.0] -_;
                          g=j[g] ;
                        end;
                      end;
                    else
                      if v[43] ~=v[12]then
                      else
                        return ;
                      end;
                      if v[43] ~=v[46]then
                        e[10.0] =H[U[g] ] ;
                        g+=1.0;
                        (e) [10.0] = (e[10.0] [U[g] ] ) ;
                        g+=1.0;
                        e[11.0] = (H[U[g] ] ) ;
                        g+=1.0;
                      end;
                      e[11.0] =e[11.0] [P[g] ] ;
                      g+=1.0;
                      if v[38] ~=v[5]then
                      else
                        while - (232<252)do
                          return 181;
                        end;
                        while true do
                          return 55;
                        end;
                      end;
                      if v[39] ~=v[46]then
                      else
                        if not (v[49] )then
                        else
                          return ;
                        end;
                      end;
                      if g==v[37]then
                        return ;
                      end;
                      if v[22] ~=v[2]then
                        (e) [12.0] =e[3.0] ;
                        g+=1.0;
                        (e) [13.0] = (P[g] ) ;
                        g+=1.0;
                        (e) [11.0] =e[11.0] (e[12.0] ,e[13.0] ) ;
                        r= (11.0) ;
                        g+=1.0;
                        e[12.0] =H[U[g] ] ;
                        g+=1.0;
                        e[12.0] =e[12.0] [P[g] ] ;
                        g+=1.0;
                        e[13.0] = (e[3.0] ) ;
                        g+=1.0;
                        (e) [14.0] =U[g] ;
                        g+=1.0;
                        r= (14.0) ;
                        y,C=v[52] (e[12.0] (v[22] (e,r,13.0) ) ) ;
                        y+=11.0;
                        r= (y) ;
                        X= (0.0) ;
                        for H=12.0,y,1 do
                          if v[52] ~=v[25]then
                          else
                            if v[38] ^ ( -229)then
                              return ;
                            end;
                          end;
                          X+=1.0;
                          (e) [H] = (C[X] ) ;
                        end;
                        g+=1.0;
                        (e) [10.0] =e[10.0] (v[22] (e,r,11.0) ) ;
                        r=10.0;
                        g+=1.0;
                        e[3.0] = (e[10.0] ) ;
                        g+=1.0;
                        (e) [10.0] = (I[q[g] ] ) ;
                        g+=1.0;
                        y=e[1.0] ;
                        e[12.0] =y;
                        e[11.0] =y[U[g] ] ;
                        g+=1.0;
                        (e) [13.0] =e[9.0] ;
                        g+=1.0;
                        e[11.0] =e[11.0] (e[12.0] ,e[13.0] ) ;
                        r= (11.0) ;
                        g+=1.0;
                        (e) [12.0] =e[3.0] %K[g] ;
                        g+=1.0;
                        e[10.0] =e[10.0] (e[11.0] ,e[12.0] ) ;
                        r= (10.0) ;
                        g+=1.0;
                        (e) [11.0] = (e[9.0] *K[g] ) ;
                        g+=1.0;
                        (e) [12.0] = (e[11.0] -K[g] ) ;
                        g+=1.0;
                        (e) [13.0] = (e[10.0] //P[g] ) ;
                        g+=1.0;
                        e[13.0] = (e[13.0] +P[g] ) ;
                        g+=1.0;
                      end;
                      (e) [13.0] =e[4.0] [e[13.0] ] ;
                      if v[37] ==v[12]then
                      else
                        g+=1.0;
                        (e[5.0] ) [e[12.0] ] = (e[13.0] ) ;
                        g+=1.0;
                      end;
                      e[12.0] = (e[10.0] %P[g] ) ;
                      g+=1.0;
                      (e) [12.0] = (e[12.0] +P[g] ) ;
                      g+=1.0;
                      e[12.0] = (e[4.0] [e[12.0] ] ) ;
                      g+=1.0;
                      e[5.0] [e[11.0] ] =e[12.0] ;
                      g+=1.0;
                      g= (q[g] ) ;
                    end;
                  end;
                end;
                g+=1.0;
              until false;
            end) ;
          end;
        end;
      else
        if i<4 then
          o=function ( ... )
            local e,r,H,_,C,X,l,Z,T,g,y,E,O,a=v[23] (n) ,1.0,0.0,1.0,1.0, (v[18] ( ) ) ;
            local F,M,b,d,s,x,p,J,h,t;
            repeat
              local V=W[C] ;
              if V<148 then
                if V>=74 then
                  if not (V>=111)then
                    if not (V<92)then
                      if V<101 then
                        if not (V>=96)then
                          if not (V>=94)then
                            if V~=93 then
                              if v[41] ==v[5]then
                                v[45] ,v[5] =252, ( -v[42] ) ;
                                return v[46] ;
                              else
                                if v[41] ==v[33]then
                                  if not (v[50] )then
                                  else
                                    return -v[7] ;
                                  end;
                                else
                                  if e[j[C] ]then
                                    C=c[C] ;
                                  end;
                                end;
                              end;
                            else
                              if e[q[C] ] ==U[C]then
                                C=j[C] ;
                              end;
                            end;
                          else
                            if v[36] ==v[2]then
                              return ;
                            else
                              if V~=95 then
                                l=j[C] ;
                              else
                                if v[45] ==v[40]then
                                  while 82/114<v[46]do
                                    return ;
                                  end;
                                end;
                                b= (57.0) ;
                                l= (nil) ;
                                M= (nil) ;
                                y=nil;
                                O=90;
                                repeat
                                  if O==90.0 then
                                    l=0;
                                    M=4503599627370495;
                                    l*=M;
                                    O= ( -77+ (v[46] [18.0] ( (v[46] [14.0] ( (v[46] [14.0] ( (j[C] -q[C] <=O and O or j[C] ) <=q[C]and V or V) ) ,O) ) ,j[C] ) ) ) ;
                                    continue;
                                  else
                                    if O==28.0 then
                                      y=19.0;
                                      M= (M[y] ) ;
                                      break;
                                    else
                                      if O~=113.0 then
                                      else
                                        M= (v[46] ) ;
                                        O= -24+ (v[46] [14.0] ( (v[46] [7.0] ( (v[46] [19.0] (q[C] ) ) ,q[C] ) ) -O+V+V) ) ;
                                      end;
                                    end;
                                  end;
                                until false;
                                if o~=v[5]then
                                else
                                  if not (v[40] )then
                                  else
                                    return -h;
                                  end;
                                  return ;
                                end;
                                if v[33] ~=v[22]then
                                  y= (v[46] ) ;
                                end;
                                t= (nil) ;
                                p=nil;
                                O=87;
                                while true do
                                  if O>33.0 then
                                    if not (O>=87.0)then
                                      y= (y[t] ) ;
                                      O= (107+ ( ( (v[46] [12.0] (V-V-j[C] ) ) >=O and V or j[C] ) -O-j[C] ) ) ;
                                    else
                                      t=7.0;
                                      O= (75+ ( (v[46] [17.0] (j[C] ) ) -j[C] +O-j[C] +j[C] -O) ) ;
                                    end;
                                  elseif not (O<=12.0)then
                                    t= (v[46] ) ;
                                    p= (11.0) ;
                                    O=9+ ( (v[46] [11.0] ( (v[46] [20.0] ( (v[46] [16.0] ( (v[46] [17.0] (V) ) ) ) <=O and q[C]or O,q[C] ) ) ,j[C] ) ) +q[C] ) ;
                                  else
                                    t= (t[p] ) ;
                                    break;
                                  end;
                                end;
                                if v[33] ==v[5]then
                                  return b;
                                end;
                                p= (W[C] ) ;
                                J= (nil) ;
                                h= (nil) ;
                                O= (49) ;
                                while true do
                                  if O>11.0 then
                                    if v[49] ==v[2]then
                                      return ;
                                    else
                                      if not (O<92.0)then
                                        p-=J;
                                        O= -78+ ( (v[46] [16.0] ( (v[46] [16.0] (O+q[C] ,q[C] ) ) ) ) +j[C] -q[C] -j[C] ) ;
                                      else
                                        J= (j[C] ) ;
                                        O= (43+ ( ( (v[46] [17.0] (O) ) -j[C] -O-j[C] >O and q[C]or O) ~=j[C]and O or q[C] ) ) ;
                                        continue;
                                      end;
                                    end;
                                  else
                                    if v[33] ==v[38]then
                                    else
                                      J= (V) ;
                                    end;
                                    h=j[C] ;
                                    break;
                                  end;
                                end;
                                if v[43] ==v[33]then
                                  if (197>=74) -180 then
                                    F= (v[40] ) ;
                                  end;
                                  if not (g)then
                                  else
                                    (v) [46] ,v[42] = -92% -215, (36) ;
                                  end;
                                end;
                                t=t(p,J,h) ;
                                O=109;
                                repeat
                                  if O<104.0 and O>39.0 then
                                    y=j[C] ;
                                    break;
                                  else
                                    if O>90.0 and O<109.0 then
                                      if v[43] ==v[2]then
                                      else
                                        y=y(t,p) ;
                                        O= (140+ ( (v[46] [17.0] (q[C] +O-O~=O and j[C]or O) ) -O+q[C] ) ) ;
                                        continue;
                                      end;
                                    else
                                      if O>104.0 then
                                        p=q[C] ;
                                        O=196+ ( (v[46] [14.0] ( (v[46] [19.0] ( (v[46] [16.0] (q[C] ) ) ) ) +O>=q[C]and q[C]or j[C] ) ) -V) ;
                                        continue;
                                      else
                                        if not (O<90.0)then
                                        else
                                          if v[52] ~=b then
                                          else
                                            return ;
                                          end;
                                          M=M(y) ;
                                          O=56+ (v[46] [16.0] ( (v[46] [22.0] ( (v[46] [16.0] (O+O-j[C] ,O,O) ) ,q[C] ) ) -q[C] ,q[C] ,O) ) ;
                                        end;
                                      end;
                                    end;
                                  end;
                                until false;
                                M-=y;
                                y=V;
                                O=8;
                                repeat
                                  if O>17.0 then
                                    if O~=71.0 then
                                      M=M>y;
                                      O=16+ (v[46] [17.0] ( (v[46] [11.0] ( (v[46] [11.0] (V+O,O) ) +O,j[C] ,O) ) +O) ) ;
                                    else
                                      y=q[C] ;
                                      O= ( -710+ ( (v[46] [7.0] ( (v[46] [16.0] (j[C] ) ) +V-j[C] ,q[C] ) ) +j[C] +O) ) ;
                                    end;
                                  elseif O>8.0 then
                                    if M then
                                      M= (V) ;
                                    end;
                                    break;
                                  else
                                    M+=y;
                                    O= (84+ ( (v[46] [14.0] ( (v[46] [16.0] (O+O-O,q[C] ,O) ) ,q[C] ) ) -O-O) ) ;
                                    continue;
                                  end;
                                until false;
                                if not (not M)then
                                elseif v[2] ~=v[42]then
                                  M= (j[C] ) ;
                                end;
                                O=52;
                                while true do
                                  if O>6.0 then
                                    if O~=52.0 then
                                      if o~=v[12]then
                                        if not (not M)then
                                        else
                                          M= (V) ;
                                        end;
                                      end;
                                      break;
                                    else
                                      y=V;
                                      O= ( (v[46] [20.0] ( (v[46] [20.0] (q[C] -V,q[C] ) ) ,j[C] ) ) +O-q[C] <=O and O or q[C] ) ;
                                      continue;
                                    end;
                                  elseif O<6.0 then
                                    M=M>y;
                                    O= -89+ ( (v[46] [17.0] (j[C] +V-V-O-j[C] ) ) +V) ;
                                  else
                                    if not (M)then
                                    else
                                      M= (j[C] ) ;
                                    end;
                                    O=51+ ( (v[46] [11.0] ( (v[46] [17.0] (O-V<=q[C]and O or O) ) ) ) -O-j[C] ) ;
                                    continue;
                                  end;
                                end;
                                if v[7] ~=v[43]then
                                  l+=M;
                                  b+=l;
                                  W[C] =b;
                                  b= (I) ;
                                  l=c[C] ;
                                end;
                                O= (114) ;
                                repeat
                                  if O==114.0 then
                                    b=b[l] ;
                                    O= -536870851+ (v[46] [20.0] ( (v[46] [12.0] (V-j[C] ==O and q[C]or q[C] ) ) -V-V,q[C] ) ) ;
                                  else
                                    if v[52] ==v[46]then
                                      return v[38] ;
                                    else
                                      if O~=41.0 then
                                      else
                                        l=b;
                                        M= (2) ;
                                        break;
                                      end;
                                    end;
                                  end;
                                until false;
                                O=46;
                                while true do
                                  if not (O>46.0)then
                                    if O>16.0 then
                                      if o~=v[5]then
                                        l= (l[M] ) ;
                                        O= (53+ (v[46] [7.0] ( (v[46] [17.0] ( (v[46] [19.0] ( (v[46] [11.0] ( (v[46] [16.0] (O,q[C] ) ) -j[C] ) ) ) ) ) ) ,q[C] ) ) ) ;
                                      end;
                                    else
                                      y= (1) ;
                                      O= ( -64+ ( ( ( (v[46] [14.0] (O,O,O) ) >=V and V or q[C] ) -O+q[C] >=O and V or V) +O) ) ;
                                    end;
                                  else
                                    if not (O>47.0)then
                                      if v[25] ~=v[43]then
                                      else
                                        return ;
                                      end;
                                      M= (M[y] ) ;
                                      l=l[M] ;
                                      O= ( -4294967134+ (v[46] [19.0] ( (v[46] [18.0] (O-O-O-V,j[C] ) ) ~=V and V or O) ) ) ;
                                    else
                                      if O==53.0 then
                                        M= (b) ;
                                        O= ( -4294967151+ (v[46] [14.0] ( (v[46] [14.0] ( (v[46] [7.0] ( (v[46] [20.0] (q[C] -O,q[C] ) ) ,q[C] ) ) -V) ) ,O,j[C] ) ) ) ;
                                      else
                                        if v[52] ==v[12]then
                                          if not (g)then
                                          else
                                            (v) [40] ,v[7] =198, (v[40] ) ;
                                            return ;
                                          end;
                                          while v[2]do
                                            return v[7] ;
                                          end;
                                        end;
                                        M= (e) ;
                                        break;
                                      end;
                                    end;
                                  end;
                                end;
                                y=j[C] ;
                                M=M[y] ;
                                y= (e) ;
                                O=90;
                                repeat
                                  if O<113.0 then
                                    t=q[C] ;
                                    O= -4294967277+ ( (v[46] [19.0] ( (v[46] [12.0] ( (v[46] [16.0] (q[C] -O-V,O,j[C] ) ) ) ) ) ) +V) ;
                                  else
                                    if O>90.0 then
                                      y= (y[t] ) ;
                                      l[M] =y;
                                      break;
                                    end;
                                  end;
                                until false;
                              end;
                            end;
                          end;
                        else
                          if V<98 then
                            if V~=97 then
                              M+=y;
                            else
                              if v[49] ~=v[2]then
                              else
                                o,v[36] =v[41] * (95%180) ,v[51] ;
                                return ;
                              end;
                              if v[25] ==v[22]then
                              else
                                (v) [10] = (e[c[C] ] ) ;
                              end;
                            end;
                          else
                            if V<99 then
                              e[q[C] ] = (e[j[C] ] ==e[c[C] ] ) ;
                            else
                              if v[36] ==v[2]then
                                (v) [45] =247 or -224;
                              elseif v[39] ==v[5]then
                                v[33] = - (70-175) ;
                                return ;
                              else
                                if V~=100 then
                                  if not (e[j[C] ] <e[q[C] ] )then
                                    C=c[C] ;
                                  end;
                                else
                                  M= (K[C] ) ;
                                  y=e;
                                end;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V>=106)then
                          if v[35] ==v[2]then
                          else
                            if v[42] ==v[5]then
                              while v[52]do
                                return ;
                              end;
                            elseif v[35] ==v[12]then
                              (v) [52] ,g=179, ( -138- -176) ;
                            else
                              if not (V<103)then
                                if not (V>=104)then
                                  if e[q[C] ] ==U[C]then
                                  else
                                    C= (j[C] ) ;
                                  end;
                                else
                                  if V==105 then
                                    (e) [j[C] ] = (e[c[C] ] [P[C] ] ) ;
                                  else
                                    O=q[C] ;
                                    y=y[O] ;
                                  end;
                                end;
                              else
                                if V==102 then
                                  b= (e) ;
                                  l= (_) ;
                                else
                                  b=q[C] ;
                                end;
                              end;
                            end;
                          end;
                        else
                          if v[7] ==v[5]then
                            v[5] ,v[51] =v[43] ,v[42] ^v[50] ;
                            while v[51]do
                              return ;
                            end;
                          end;
                          if V<108 then
                            if V~=107 then
                              e[j[C] ] = (v[44] (e[q[C] ] ,e[c[C] ] ) ) ;
                            else
                              (b) [l] =M;
                            end;
                          else
                            if not (V<109)then
                              if V~=110 then
                                b= (e) ;
                                l= (q[C] ) ;
                                M= (K[C] ) ;
                              else
                                if v[36] ~=v[46]then
                                else
                                  (v) [51] ,v[33] =v[49] ,v[33] ;
                                  return ;
                                end;
                                if v[37] ~=v[46]then
                                  b=U[C] ;
                                  l=b[9] ;
                                  b= ( #l) ;
                                  M=b>0.0 and {
                                  } ;
                                  if M then
                                    if v[46] ==v[38]then
                                    else
                                      for Y=1.0,b,1 do
                                        y=l[Y] ;
                                        O=y[2] ;
                                        t=y[1] ;
                                        if O==0.0 then
                                          if not T then
                                            T= {
                                            } ;
                                          end;
                                          y=T[t] ;
                                          if not y then
                                            y= ( {
                                              [1] =t, [2] =e
                                            } ) ;
                                            T[t] = (y) ;
                                          end;
                                          (M) [Y-1.0] = (y) ;
                                        else
                                          if O==1.0 then
                                            (M) [Y-1.0] =e[t] ;
                                          else
                                            (M) [Y-1.0] =I[t] ;
                                          end;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                                b=D[P[C] ] (M) ;
                                (v[24] ) (b,X) ;
                                (e) [j[C] ] =b;
                              end;
                            else
                              l= (q[C] ) ;
                            end;
                          end;
                        end;
                      end;
                    else
                      if V<83 then
                        if V<78 then
                          if V<76 then
                            if v[22] ==v[25]then
                              if not (232)then
                              else
                                return (231 and 65) ~=J;
                              end;
                            elseif v[41] ==v[33]then
                              if - ( -137)then
                                (v) [46] ,J=199, (p) ;
                                v[21] = (F) ;
                              end;
                              v[49] ,v[38] =v[46] , ( -J) ;
                            else
                              if V==75 then
                                M= (c[C] ) ;
                              else
                                e[c[C] ] =K[C] ==P[C] ;
                              end;
                            end;
                          else
                            if V~=77 then
                              b=q[C] ;
                              e[b] (v[22] (e,_,b+1.0) ) ;
                              _=b-1.0;
                            else
                              (e) [q[C] ] = (e[c[C] ] *K[C] ) ;
                            end;
                          end;
                        else
                          if not (V<80)then
                            if V<81 then
                              b= (I[c[C] ] ) ;
                              e[j[C] ] =b[2] [b[1] ] [e[q[C] ] ] ;
                            else
                              if v[51] ~=v[12]then
                                if V~=82 then
                                  if v[49] ==v[2]then
                                  else
                                    M=M[y] ;
                                  end;
                                else
                                  y=y[O] ;
                                end;
                              end;
                            end;
                          else
                            if V~=79 then
                              O= (q[C] ) ;
                              y=y[O] ;
                              M+=y;
                            else
                              M= (M[y] ) ;
                              y=P[C] ;
                              M= (M[y] ) ;
                            end;
                          end;
                        end;
                      else
                        if V>=87 then
                          if not (V>=89)then
                            if V==88 then
                              if not (not (e[q[C] ] <=K[C] ) )then
                              else
                                C=c[C] ;
                              end;
                            else
                              b= (j[C] ) ;
                              _=b;
                            end;
                          else
                            if not (V<90)then
                              if V==91 then
                                if v[51] ~=v[12]then
                                else
                                  if not (v[21] )then
                                  else
                                    h= (v[22] ) ;
                                  end;
                                  v[36] =v[39] ;
                                end;
                                b=nil;
                                l= (nil) ;
                                M= (52) ;
                                repeat
                                  if not (M<52.0)then
                                    b= ( -3.623878595E9) ;
                                    M=7+ ( (v[46] [14.0] ( (v[46] [11.0] ( (v[46] [14.0] (V-M,V,M) ) +M,M) ) ) ) -M) ;
                                  else
                                    if v[51] ==v[2]then
                                      if F then
                                        F= -v[39] ;
                                      end;
                                    end;
                                    l= (0) ;
                                    break;
                                  end;
                                until false;
                                y= (4503599627370495) ;
                                M= (7) ;
                                while true do
                                  if M==7.0 then
                                    l*=y;
                                    M=57+ ( (v[46] [17.0] ( (v[46] [14.0] (V+M,V) ) +V) ) +M-M) ;
                                    continue;
                                  else
                                    if M~=58.0 then
                                    else
                                      y=v[46] ;
                                      break;
                                    end;
                                  end;
                                end;
                                if v[42] ==v[12]then
                                  if -v[35]then
                                    v[41] ,v[51] =v[42] , -t;
                                    return v[45] ;
                                  end;
                                end;
                                O=7.0;
                                M= (99) ;
                                repeat
                                  if M==99.0 then
                                    y=y[O] ;
                                    M=6+ (v[46] [11.0] ( (v[46] [12.0] ( (v[46] [11.0] (M+V==V and V or V) ) ) ) +V,M) ) ;
                                  else
                                    if M==102.0 then
                                      O=v[46] ;
                                      break;
                                    end;
                                  end;
                                until false;
                                local Y=135;
                                if Y==135 then
                                  t=11.0;
                                  O= (O[t] ) ;
                                  t= (v[46] ) ;
                                end;
                                p= (20.0) ;
                                J=nil;
                                if Y~=139 then
                                else
                                  (v) [21] ,v[22] =v[51] , - ( -48) ;
                                end;
                                M= (116) ;
                                repeat
                                  if Y==96 then
                                    while true do
                                      v[52] = (o) ;
                                      return ;
                                    end;
                                    return - (130%253) ;
                                  end;
                                  if M>67.0 then
                                    t=t[p] ;
                                    p= (v[46] ) ;
                                    M= ( -763363261+ (v[46] [20.0] ( (v[46] [16.0] (M+M-V-M) ) ==V and M or V, (9) ) ) ) ;
                                    continue;
                                  else
                                    if not (M<116.0)then
                                    else
                                      J=19.0;
                                      p= (p[J] ) ;
                                      break;
                                    end;
                                  end;
                                until false;
                                M=118;
                                while true do
                                  if M>24.0 then
                                    if M~=118.0 then
                                      p=p(J) ;
                                      M= -190840992+ ( (v[46] [20.0] ( (v[46] [11.0] (V-M,V) ) <=M and V or V, (11) ) ) +M+V) ;
                                      continue;
                                    else
                                      if Y==135 then
                                        J=V;
                                        M= (68+ (v[46] [11.0] ( (v[46] [12.0] (V-V+V-V+V) ) ,V) ) ) ;
                                      end;
                                    end;
                                  elseif M~=24.0 then
                                    p+=J;
                                    break;
                                  else
                                    J=V;
                                    M= (181+ ( (v[46] [22.0] ( (v[46] [12.0] (M~=M and V or V) ) , (M) ) ) +M-V-V) ) ;
                                    continue;
                                  end;
                                end;
                                if v[40] ~=v[52]then
                                  M= (23) ;
                                  repeat
                                    if M<23.0 then
                                      t=t(p,J) ;
                                      break;
                                    else
                                      if not (M>10.0)then
                                      else
                                        J= (19) ;
                                        M= ( -58+ ( ( (v[46] [14.0] ( (v[46] [19.0] ( (v[46] [14.0] (M,M) ) ) ) >V and V or M) ) <V and M or V) -M) ) ;
                                        continue;
                                      end;
                                    end;
                                  until false;
                                  p=V;
                                  M= (69) ;
                                end;
                                repeat
                                  if M<69.0 and M>18.0 then
                                    O=O(t,p) ;
                                    M= ( -4294967249+ ( (v[46] [19.0] (V) ) -M-V+M+M+V) ) ;
                                    continue;
                                  elseif M<63.0 then
                                    t= (W[C] ) ;
                                    break;
                                  elseif M>69.0 then
                                    p= (W[C] ) ;
                                    M=68+ ( (v[46] [11.0] ( (M>=V and V or M) +M-M-M,V) ) -M) ;
                                    continue;
                                  else
                                    if M<96.0 and M>63.0 then
                                      t-=p;
                                      M= ( -186272+ (v[46] [7.0] ( (v[46] [20.0] ( (v[46] [12.0] (V) ) <V and V or M, (19) ) ) +V==M and M or V, (11) ) ) ) ;
                                      continue;
                                    end;
                                  end;
                                until false;
                                M=19;
                                repeat
                                  if M==19.0 then
                                    O+=t;
                                    M= (287+ ( (v[46] [22.0] ( (v[46] [12.0] (M-M) ) , (M) ) ) -V-M-V) ) ;
                                    continue;
                                  else
                                    if M==86.0 then
                                      t= (V) ;
                                      break;
                                    end;
                                  end;
                                until false;
                                local m= (205) ;
                                if v[43] ==v[33]then
                                else
                                  O+=t;
                                  M= (103) ;
                                end;
                                while true do
                                  if M<103.0 then
                                    y=y(O,t) ;
                                    l+=y;
                                    break;
                                  else
                                    t= (26) ;
                                    M= ( -24+ (v[46] [18.0] ( (v[46] [12.0] ( ( (v[46] [7.0] (M, (22) ) ) >M and M or M) -M==V and V or M) ) , (1) ) ) ) ;
                                  end;
                                end;
                                M= (122) ;
                                repeat
                                  if M<60.0 then
                                    if Y~=135 then
                                    else
                                      W[C] = (b) ;
                                      M= (60+ (v[46] [18.0] ( (v[46] [7.0] ( (v[46] [22.0] ( (v[46] [11.0] ( (v[46] [19.0] ( (v[46] [18.0] (M, (M) ) ) ) ) ,V,M) ) , (M) ) ) , (M) ) ) , (M) ) ) ) ;
                                    end;
                                  else
                                    if M>60.0 then
                                      b+=l;
                                      M= -151+ (v[46] [19.0] ( (v[46] [17.0] ( (v[46] [20.0] ( (v[46] [7.0] (V, (8) ) ) , (27) ) ) ) ) -V-V) ) ;
                                    else
                                      if M>17.0 and M<122.0 then
                                        b=e;
                                        l= (c[C] ) ;
                                        b=b[l] ;
                                        break;
                                      end;
                                    end;
                                  end;
                                until false;
                                M=12;
                                repeat
                                  if Y~=135 then
                                  elseif Y==90 then
                                    if not (m)then
                                    else
                                      v[42] =v[49] ;
                                      v[36] = ( -24>=m) ;
                                    end;
                                  else
                                    if Y==193 then
                                      while 101<= (46==68)do
                                        v[33] ,g=214~=185, - (69<=200) ;
                                        v[49] = -104;
                                      end;
                                      if not (v[7] <= -115)then
                                      else
                                        (v) [41] = -v[50] ;
                                      end;
                                    else
                                      if M<123.0 and M>12.0 then
                                        l= (l[y] ) ;
                                        b= (b<l) ;
                                        if not (b)then
                                        else
                                          b= (q[C] ) ;
                                          C=b;
                                        end;
                                        break;
                                      elseif M>30.0 then
                                        y= (j[C] ) ;
                                        M=30+ (v[46] [7.0] ( (v[46] [7.0] ( (v[46] [22.0] ( (v[46] [16.0] (V+V-V) ) , (15) ) ) , (0) ) ) , (18) ) ) ;
                                        continue;
                                      else
                                        if M<30.0 then
                                          l= (e) ;
                                          M= ( -4294967077+ (v[46] [19.0] ( (v[46] [14.0] ( (v[46] [11.0] (M+V-M) ) <=V and V or V,M,V) ) ) ) ) ;
                                        end;
                                      end;
                                    end;
                                  end;
                                until false;
                              else
                                b=nil;
                                l= (nil) ;
                                M= (nil) ;
                                y=63;
                                while true do
                                  if y==73.0 then
                                    if v[33] ~=v[37]then
                                      M=4503599627370495;
                                    end;
                                    y= -70+ ( (v[46] [22.0] ( (v[46] [17.0] ( (v[46] [14.0] (y) ) ) ) >=y and V or y, (15) ) ) -y~=V and V or y) ;
                                    continue;
                                  elseif y==20.0 then
                                    l*=M;
                                    break;
                                  else
                                    if y==18.0 then
                                      l= (0) ;
                                      y= -52+ (v[46] [19.0] ( (v[46] [11.0] (y+y,V,V) ) -y-y-V) ) ;
                                      continue;
                                    else
                                      if y==63.0 then
                                        if v[22] ==v[25]then
                                        else
                                          b= (264.0) ;
                                          y= ( -45+ ( (v[46] [16.0] ( (v[46] [11.0] (V-V-V,V,V) ) ,y) ) +y<V and V or y) ) ;
                                          continue;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                                O= (nil) ;
                                t= (nil) ;
                                p= (nil) ;
                                y=102;
                                repeat
                                  if y<122.0 and y>71.0 then
                                    if v[21] ==v[12]then
                                    else
                                      M=v[46] ;
                                    end;
                                    y= ( -77+ ( (v[46] [22.0] ( (v[46] [20.0] ( (v[46] [19.0] (V-y) ) , (1) ) ) , (11) ) ) -V<y and y or V) ) ;
                                    if y~=o then
                                    else
                                      while v[46]do
                                        v[50] =F;
                                      end;
                                    end;
                                    continue;
                                  elseif y>102.0 then
                                    t=22.0;
                                    y= -73+ ( (v[46] [7.0] ( (v[46] [14.0] (V+y+V) ) +y, (21) ) ) >V and V or V) ;
                                  elseif y<17.0 and y>8.0 then
                                    O= (17.0) ;
                                    y=21+ ( (v[46] [17.0] ( (v[46] [12.0] (V) ) -V) ) -y+y-y) ;
                                    continue;
                                  elseif y<71.0 and y>17.0 then
                                    t=t[p] ;
                                    break;
                                  else
                                    if y<13.0 then
                                      M=M[O] ;
                                      y= (161+ ( ( (v[46] [19.0] ( (v[46] [17.0] (y) ) ) ) +y>=y and V or y) -V-V) ) ;
                                    elseif y>13.0 and y<60.0 then
                                      if v[2] ~=v[35]then
                                      else
                                        return ;
                                      end;
                                      if v[7] ~=v[21]then
                                        O= (O[t] ) ;
                                      end;
                                      t=v[46] ;
                                      p= (12.0) ;
                                      y= -11796420+ (v[46] [7.0] ( (v[46] [14.0] (y) ) +V-V+y<y and y or V, (y) ) ) ;
                                    else
                                      if not (y>60.0 and y<102.0)then
                                      else
                                        O= (v[46] ) ;
                                        y= (122+ (v[46] [12.0] ( (v[46] [17.0] ( (v[46] [16.0] (y+y,y,V) ) -y) ) -y) ) ) ;
                                      end;
                                    end;
                                  end;
                                until false;
                                J= (nil) ;
                                y= (104) ;
                                repeat
                                  if y==39.0 then
                                    J= (V) ;
                                    break;
                                  else
                                    p=V;
                                    y= -65+ ( (v[46] [18.0] ( ( (v[46] [16.0] (V,V,V) ) -y<=y and V or y) -V, (19) ) ) +y) ;
                                    continue;
                                  end;
                                until false;
                                if v[7] ==v[51]then
                                  if not (h)then
                                  else
                                    return ;
                                  end;
                                end;
                                p= (p~=J) ;
                                y=87;
                                while true do
                                  if y<87.0 then
                                    J=V;
                                    p-=J;
                                    break;
                                  else
                                    if not (y>74.0)then
                                    else
                                      if p then
                                        p= (V) ;
                                      end;
                                      if not p then
                                        p= (W[C] ) ;
                                      end;
                                      y= -16+ ( (v[46] [16.0] (V-V+y+V) ) -V~=y and V or V) ;
                                      continue;
                                    end;
                                  end;
                                end;
                                if v[50] ~=v[5]then
                                else
                                  while true do
                                    (v) [21] = (250) ;
                                    v[39] ,o=v[36] ,v[36] ;
                                  end;
                                end;
                                if v[25] ==o then
                                  if not (v[39] )then
                                  else
                                    return -v[35] ;
                                  end;
                                  while v[52]do
                                    v[36] = (F) ;
                                  end;
                                end;
                                if v[46] ==v[42]then
                                else
                                  t=t(p) ;
                                  p= (0) ;
                                  O=O(t,p) ;
                                end;
                                y=122;
                                repeat
                                  if y==122.0 then
                                    t= (W[C] ) ;
                                    y= -8+ ( (v[46] [14.0] ( (v[46] [16.0] ( (v[46] [14.0] ( (v[46] [12.0] (V) ) ) ) ) ) ) ) +V-V) ;
                                  else
                                    O=O==t;
                                    break;
                                  end;
                                until false;
                                if O then
                                  O= (V) ;
                                end;
                                if not O then
                                  O= (W[C] ) ;
                                end;
                                t= (W[C] ) ;
                                y= (48) ;
                                while true do
                                  if not (y<=48.0)then
                                    if y~=98.0 then
                                      t=V;
                                      y= (98+ (v[46] [17.0] ( (v[46] [16.0] ( (v[46] [7.0] ( (v[46] [16.0] ( (v[46] [16.0] (y,V,y) ) ,V,V) ) , (17) ) ) ,V,y) ) >=V and y or V) ) ) ;
                                    else
                                      O-=t;
                                      break;
                                    end;
                                  else
                                    O-=t;
                                    y=102+ ( (v[46] [12.0] ( (v[46] [19.0] ( (v[46] [19.0] (y+y) ) ) ) <=V and y or V) ) -y) ;
                                  end;
                                end;
                                if v[35] ==v[12]then
                                else
                                  M=M(O) ;
                                  l+=M;
                                  b+=l;
                                  W[C] =b;
                                  b=K[C] ;
                                end;
                                l= (e) ;
                                M= (q[C] ) ;
                                y= (67) ;
                                repeat
                                  if y>67.0 then
                                    if v[36] ~=v[7]then
                                      b=b<=l;
                                      b=not b;
                                      break;
                                    end;
                                  else
                                    if not (y<70.0)then
                                    else
                                      l= (l[M] ) ;
                                      y= (70+ (v[46] [22.0] ( (v[46] [14.0] ( (v[46] [16.0] ( (v[46] [18.0] ( (v[46] [14.0] (V,y) ) , (v[46] [8.0] ('<\i\u{038}','\13\0\0\0\0\0\0\0') ) ) ) ) ) ,V) ) ==y and y or V, (26) ) ) ) ;
                                    end;
                                  end;
                                until false;
                                if not (b)then
                                else
                                  if v[52] ==v[7]then
                                  else
                                    M=86;
                                    while true do
                                      if M~=61.0 then
                                        b=c[C] ;
                                        M=61;
                                        continue;
                                      else
                                        if v[49] ==v[5]then
                                        else
                                          C=b;
                                          break;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                              end;
                            else
                              M=M[y] ;
                              y=e;
                            end;
                          end;
                        else
                          if V<85 then
                            if V~=84 then
                              M=e;
                            else
                              y= (c[C] ) ;
                            end;
                          else
                            if v[41] ==v[33]then
                              (v) [35] = (v[2] ) ;
                              while v[51]do
                                return ;
                              end;
                            else
                              if V==86 then
                                e[q[C] ] = (e[c[C] ] /K[C] ) ;
                              else
                                b=e;
                                l=q[C] ;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if V>=129 then
                      if V>=138 then
                        if V<143 then
                          if not (V>=140)then
                            if V==139 then
                              e[j[C] ] = (e[c[C] ] ^e[q[C] ] ) ;
                            else
                              Z= (s[4] ) ;
                              E= (s[1] ) ;
                              x= (s[3] ) ;
                              s=s[5] ;
                            end;
                          else
                            if not (V>=141)then
                              M= (e) ;
                            else
                              if V~=142 then
                                if not (T)then
                                else
                                  if v[38] ~=v[40]then
                                  else
                                    if 100+155<=29-190 then
                                      (v) [42] ,F=177,v[42] ;
                                      return v[41] ;
                                    end;
                                  end;
                                  for Y,m in T do
                                    if not (Y>=1.0)then
                                    else
                                      local u= (158) ;
                                      if u==158 then
                                      else
                                        return -v[12] ;
                                      end;
                                      (m) [2] = (m) ;
                                      (m) [3] = (e[Y] ) ;
                                      m[1] = (3) ;
                                      (T) [Y] = (nil) ;
                                    end;
                                  end;
                                end;
                                return ;
                              else
                                e[c[C] ] = (e[j[C] ] +P[C] ) ;
                              end;
                            end;
                          end;
                        else
                          if v[45] ~=v[33]then
                          else
                            if not ( - (13+22) )then
                            else
                              (v) [38] = ( -v[43] ) ;
                              (v) [51] ,v[49] =127,v[21] ;
                            end;
                            (v) [37] = (v[42] ) ;
                          end;
                          if not (V<145)then
                            if V>=146 then
                              local Y= (221) ;
                              if Y==234 then
                                if not (Y)then
                                else
                                  v[41] =231-2 and 32==249;
                                end;
                              else
                                if V==147 then
                                  M=e;
                                  y=j[C] ;
                                  M=M[y] ;
                                else
                                  y= (U[C] ) ;
                                  M=M[y] ;
                                end;
                              end;
                            else
                              e[q[C] ] =e[j[C] ] ~=e[c[C] ] ;
                            end;
                          else
                            if V==144 then
                              e[c[C] ] =K[C] -e[q[C] ] ;
                            else
                              l=j[C] ;
                              b= (b[l] ) ;
                            end;
                          end;
                        end;
                      else
                        if V<133 then
                          if not (V<131)then
                            if V~=132 then
                              e[c[C] ] =e[q[C] ] <=K[C] ;
                            else
                              b=q[C] ;
                              l,M,y=Z( ) ;
                              if l then
                                e[b+1.0] =M;
                                (e) [b+2.0] =y;
                                C=c[C] ;
                              end;
                            end;
                          else
                            if V==130 then
                              e[q[C] ] = (K[C] *U[C] ) ;
                            else
                              if v[45] ==v[5]then
                                if not (v[33] )then
                                else
                                  return ;
                                end;
                              end;
                              y= (y[O] ) ;
                              O= (b) ;
                            end;
                          end;
                        else
                          if V>=135 then
                            if not (V<136)then
                              if V~=137 then
                                (b) [l] = (M) ;
                              else
                                (e) [j[C] ] =e[c[C] ] //P[C] ;
                              end;
                            else
                              if not (not e[j[C] ] )then
                              else
                                C= (c[C] ) ;
                              end;
                            end;
                          else
                            if v[33] ==v[36]then
                              repeat
                                return 8;
                              until false;
                              return 153;
                            else
                              if V==134 then
                                local Y=109;
                                if Y==101 then
                                  return 104;
                                end;
                                y=e;
                                O=j[C] ;
                              else
                                b= (c[C] ) ;
                                l= (0.0) ;
                                for Y=b,b+ (q[C] -1.0) ,1 do
                                  (e) [Y] =a[r+l] ;
                                  l+=1.0;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    else
                      if V<120 then
                        if V<115 then
                          if V>=113 then
                            if V~=114 then
                              b=e;
                              l= (j[C] ) ;
                            else
                              b= (e) ;
                              l=q[C] ;
                              M=e;
                            end;
                          else
                            if V==112 then
                              M+=y;
                            else
                              M= (e) ;
                              y=j[C] ;
                            end;
                          end;
                        else
                          if not (V>=117)then
                            if V==116 then
                              if P[C] ~=e[j[C] ]then
                                C=c[C] ;
                              end;
                            else
                              M=e;
                              y=j[C] ;
                              M= (M[y] ) ;
                            end;
                          else
                            if V<118 then
                              b= (e) ;
                              l= (q[C] ) ;
                              M= {
                              } ;
                            elseif v[22] ==v[2]then
                              (v) [38] ,v[52] =v[7] ,v[42] ;
                              return v[5] ;
                            else
                              if V~=119 then
                                e[j[C] ] =W;
                              else
                                local Y=c[C] ;
                                if not (T)then
                                else
                                  for m,u in T do
                                    if m>=Y then
                                      (u) [2] =u;
                                      u[3] =e[m] ;
                                      (u) [1] = (3) ;
                                      (T) [m] =nil;
                                    end;
                                  end;
                                end;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V>=124)then
                          if V>=122 then
                            if V~=123 then
                              y= (e) ;
                              O= (q[C] ) ;
                              y= (y[O] ) ;
                            else
                              (e) [c[C] ] =e[j[C] ] ==P[C] ;
                            end;
                          else
                            if V==121 then
                              local Y=42;
                              b=j[C] ;
                              l=c[C] ;
                              M= (q[C] ) ;
                              if l==0.0 then
                              else
                                _= (b+l-1.0) ;
                              end;
                              y,O=nil;
                              if l==1.0 then
                                y,O=v[52] (e[b] ( ) ) ;
                              else
                                y,O=v[52] (e[b] (v[22] (e,_,b+1.0) ) ) ;
                              end;
                              if M~=1.0 then
                                if M==0.0 then
                                  y=y+b-1.0;
                                  _= (y) ;
                                else
                                  y=b+M-2.0;
                                  _= (y+1.0) ;
                                end;
                                l=0.0;
                                for m=b,y,1 do
                                  if Y==42 then
                                    l+=1.0;
                                  end;
                                  e[m] =O[l] ;
                                end;
                              else
                                _=b-1.0;
                              end;
                            else
                              X[P[C] ] =K[C] ;
                            end;
                          end;
                        else
                          if not (V<126)then
                            if not (V>=127)then
                              R=e[c[C] ] ;
                            else
                              if v[36] ==v[7]then
                                return ;
                              elseif o==v[46]then
                                if not (119%p)then
                                else
                                  return -55==J;
                                end;
                              else
                                if V==128 then
                                  d,a=v[52] ( ... ) ;
                                else
                                  y=e;
                                  O= (j[C] ) ;
                                  y= (y[O] ) ;
                                end;
                              end;
                            end;
                          else
                            if V==125 then
                              y= (b) ;
                              O= (2) ;
                            else
                              M= (e) ;
                              y= (c[C] ) ;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                else
                  if not (V<37)then
                    if not (V<55)then
                      if not (V>=64)then
                        if V<59 then
                          if V<57 then
                            if V~=56 then
                              y=j[C] ;
                              M=M[y] ;
                              b[l] =M;
                            else
                              b= (e) ;
                              l= (j[C] ) ;
                              M=X;
                            end;
                          else
                            if V~=58 then
                              M= (e) ;
                              y= (q[C] ) ;
                              M= (M[y] ) ;
                            else
                              e[q[C] ] =U[C] >=e[j[C] ] ;
                            end;
                          end;
                        else
                          if not (V>=61)then
                            if V~=60 then
                              if T then
                                for Y,m in T do
                                  if not (Y>=1.0)then
                                  else
                                    if v[21] ==v[5]then
                                    else
                                      (m) [2] =m;
                                    end;
                                    m[3] =e[Y] ;
                                    (m) [1] =3;
                                    (T) [Y] = (nil) ;
                                  end;
                                end;
                              end;
                              b=c[C] ;
                              return v[22] (e,b+j[C] -2.0,b) ;
                            else
                              b=e;
                            end;
                          else
                            if not (V>=62)then
                              O=q[C] ;
                              y=y[O] ;
                              M-=y;
                            else
                              if V==63 then
                                if e[c[C] ] <e[j[C] ]then
                                  C= (q[C] ) ;
                                end;
                              else
                                y= (c[C] ) ;
                                M=M[y] ;
                                M= #M;
                              end;
                            end;
                          end;
                        end;
                      else
                        if V<69 then
                          if V>=66 then
                            if not (V>=67)then
                              M= (P[C] ) ;
                              b[l] =M;
                            else
                              if V~=68 then
                                l=U[C] ;
                              else
                                O= (O[b] ) ;
                                y= (y[O] ) ;
                                (l) [M] =y;
                              end;
                            end;
                          else
                            if V==65 then
                              l= (_) ;
                            else
                              e[j[C] ] =P[C] <e[c[C] ] ;
                            end;
                          end;
                        else
                          if V>=71 then
                            if V>=72 then
                              if V~=73 then
                                if not (T)then
                                else
                                  for Y,m,u in T do
                                    if v[46] ~=v[25]then
                                    else
                                      while 243 do
                                        return ;
                                      end;
                                    end;
                                    if v[5] ==v[46]then
                                      if not (v[46] )then
                                      else
                                        v[43] ,v[36] =198, (v[5] <=v[49] ) ;
                                        return 91;
                                      end;
                                      while o do
                                        v[51] = - ( -207) ;
                                      end;
                                    elseif not (Y>=1.0)then
                                    else
                                      m[2] = (m) ;
                                      (m) [3] = (e[Y] ) ;
                                      m[1] =3;
                                      (T) [Y] = (nil) ;
                                    end;
                                  end;
                                end;
                                return e[j[C] ] ( ) ;
                              else
                                b= (e) ;
                                l=c[C] ;
                              end;
                            else
                              l= (c[C] ) ;
                            end;
                          elseif V~=70 then
                            e[q[C] ] =e[j[C] ] <e[c[C] ] ;
                          else
                            (e) [c[C] ] = (e[q[C] ] ..K[C] ) ;
                          end;
                        end;
                      end;
                    else
                      if v[49] ==v[7]then
                        return v[42] ;
                      else
                        if not (V<46)then
                          if not (V<50)then
                            if not (V>=52)then
                              if V==51 then
                                y=c[C] ;
                                M= (M[y] ) ;
                              else
                                e[c[C] ] [P[C] ] =e[j[C] ] ;
                              end;
                            else
                              if V>=53 then
                                if V~=54 then
                                  if v[46] ~=v[37]then
                                    if e[c[C] ] ~=e[j[C] ]then
                                      C=q[C] ;
                                    end;
                                  end;
                                else
                                  if v[21] ~=v[40]then
                                  else
                                    return 55;
                                  end;
                                  l=q[C] ;
                                  b=b[l] ;
                                end;
                              else
                                b= (j[C] ) ;
                                l= (e[c[C] ] ) ;
                                (e) [b+1.0] =l;
                                e[b] = (l[P[C] ] ) ;
                              end;
                            end;
                          else
                            if V<48 then
                              if V~=47 then
                                b=c[C] ;
                                (e[b] ) (e[b+1.0] ,e[b+2.0] ) ;
                                _= (b-1.0) ;
                              else
                                b=I[c[C] ] ;
                                (b[2] ) [b[1] ] = (e[q[C] ] ) ;
                              end;
                            else
                              if V==49 then
                                e[j[C] ] [U[C] ] =P[C] ;
                              else
                                (e) [c[C] ] =j;
                              end;
                            end;
                          end;
                        else
                          if v[7] ~=v[21]then
                            if not (V>=41)then
                              if v[7] ==v[39]then
                                while v[41]do
                                  (v) [43] = (196) ;
                                  return v[21] ;
                                end;
                                return v[40] ;
                              else
                                if V>=39 then
                                  if v[51] ==v[2]then
                                    if not (v[42] )then
                                    else
                                      return 136%43>v[41] ;
                                    end;
                                  end;
                                  if V~=40 then
                                    e[q[C] ] = (v[27] (e[j[C] ] ,e[c[C] ] ) ) ;
                                  else
                                    b=1;
                                  end;
                                else
                                  if V~=38 then
                                    (e) [c[C] ] = (K[C] -P[C] ) ;
                                  else
                                    M=M[y] ;
                                    y= (P[C] ) ;
                                    M= (M[y] ) ;
                                  end;
                                end;
                              end;
                            else
                              if not (V<43)then
                                if V>=44 then
                                  if V==45 then
                                    M= (M[y] ) ;
                                    y= (e) ;
                                  else
                                    b= {
                                      ...
                                    } ;
                                    for Y=1.0,c[C]do
                                      (e) [Y] = (b[Y] ) ;
                                    end;
                                  end;
                                else
                                  (e) [j[C] ] = #e[c[C] ] ;
                                end;
                              else
                                if V~=42 then
                                  b=e;
                                  l=j[C] ;
                                else
                                  y=P[C] ;
                                  M= (M[y] ) ;
                                  b[l] =M;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if v[46] ==v[36]then
                      v[25] ,v[5] =95, ( -101 or v[39] ) ;
                    else
                      if V>=18 then
                        if V>=27 then
                          if V>=32 then
                            if V<34 then
                              if v[33] ~=v[21]then
                                if v[35] ==v[7]then
                                  v[38] ,v[35] = - (158+44) ,v[43] ^v[37] ;
                                else
                                  if v[43] ==v[25]then
                                    v[22] = (v[38] ) ;
                                  else
                                    if V~=33 then
                                      b=e;
                                      l=c[C] ;
                                      M=e;
                                    else
                                      if v[50] ==v[25]then
                                        return v[39] ;
                                      else
                                        if not (not (U[C] <e[q[C] ] ) )then
                                        else
                                          C= (j[C] ) ;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                              end;
                            else
                              if not (V<35)then
                                if V~=36 then
                                  (e) [j[C] ] =e[c[C] ] *e[q[C] ] ;
                                else
                                  l=j[C] ;
                                  for Y=b,l,1 do
                                    M=e;
                                    y=Y;
                                    Y=nil;
                                    M[y] =Y;
                                  end;
                                end;
                              else
                                b=false;
                                Z+=x;
                                if x<=0.0 then
                                  b= (Z>=E) ;
                                else
                                  b= (Z<=E) ;
                                end;
                                if not (b)then
                                else
                                  e[q[C] +3.0] =Z;
                                  C= (c[C] ) ;
                                end;
                              end;
                            end;
                          else
                            if V>=29 then
                              if not (V<30)then
                                if V==31 then
                                  (e) [j[C] ] = (c) ;
                                else
                                  b=e;
                                  l= (j[C] ) ;
                                end;
                              else
                                if v[46] ==v[45]then
                                  return v[43] ;
                                end;
                                if v[49] ~=v[5]then
                                else
                                  return -16;
                                end;
                                b=nil;
                                l=nil;
                                M=nil;
                                y= (125) ;
                                repeat
                                  if y==42.0 then
                                    if v[35] ~=v[33]then
                                      l*=M;
                                    end;
                                    break;
                                  elseif y==55.0 then
                                    M= (4503599627370495) ;
                                    y= ( -50+ ( (v[46] [16.0] ( (v[46] [14.0] (V-V,y,V) ) +V) ) -V+V) ) ;
                                    continue;
                                  elseif y==125.0 then
                                    b= (73.0) ;
                                    y=2+ ( (v[46] [12.0] ( (v[46] [17.0] (y<=V and V or V) ) -V==V and y or y) ) +V) ;
                                    continue;
                                  else
                                    if y==56.0 then
                                      l= (0) ;
                                      y= ( -2684354476+ ( (v[46] [18.0] (y-V+y-y>V and V or V, (V) ) ) -V) ) ;
                                      continue;
                                    end;
                                  end;
                                until false;
                                if v[33] ==v[12]then
                                  v[42] ,v[33] = -71+167, (88) ;
                                end;
                                M=v[46] ;
                                O=17.0;
                                t=nil;
                                y= (79) ;
                                while true do
                                  if y==89.0 then
                                    t=W[C] ;
                                    y= -536870794+ ( (v[46] [7.0] ( (v[46] [11.0] ( (v[46] [11.0] (V) ) +y,y,y) ) <=y and y or V, (V) ) ) -V) ;
                                  elseif y==79.0 then
                                    M=M[O] ;
                                    y= (91+ (v[46] [22.0] ( (v[46] [14.0] ( (v[46] [12.0] ( (v[46] [20.0] (y, (V) ) ) ~=y and V or y) ) ) ) -V, (V) ) ) ) ;
                                    continue;
                                  elseif y==115.0 then
                                    if v[42] ==v[12]then
                                      while o do
                                        return v[39] ;
                                      end;
                                    elseif v[45] ==v[5]then
                                      v[45] = (o- -117) ;
                                      (v) [49] ,v[43] =v[12] , -v[51] ;
                                    else
                                      if O then
                                        O= (V) ;
                                      end;
                                    end;
                                    break;
                                  elseif y==98.0 then
                                    if v[50] ==v[46]then
                                      while -v[5]do
                                        return ;
                                      end;
                                      v[49] ,v[25] =v[49] ,v[49] ;
                                    end;
                                    O= (V) ;
                                    y= -9+ ( (v[46] [11.0] ( (y-y>=y and y or V) -V-V,V) ) <y and y or y) ;
                                    continue;
                                  else
                                    if y==100.0 then
                                      O=O==t;
                                      y= (15+ ( (v[46] [7.0] ( (v[46] [22.0] (V-y+V<V and y or V, (V) ) ) , (V) ) ) +y) ) ;
                                    end;
                                  end;
                                end;
                                if not O then
                                  O= (W[C] ) ;
                                end;
                                y= (42) ;
                                while true do
                                  if y==42.0 then
                                    t= (W[C] ) ;
                                    O-=t;
                                    y= -31+ (v[46] [17.0] ( (v[46] [22.0] ( (y>y and V or y) +V+V>y and y or V, (V) ) ) ) ) ;
                                  else
                                    if y==1.0 then
                                      t= (V) ;
                                      break;
                                    end;
                                  end;
                                end;
                                O-=t;
                                y=108;
                                repeat
                                  if y==91.0 then
                                    O+=t;
                                    break;
                                  else
                                    if y==108.0 then
                                      t= (W[C] ) ;
                                      y= (89+ (v[46] [14.0] ( (v[46] [17.0] ( (v[46] [14.0] ( (v[46] [7.0] (V, (V) ) ) +V+y) ) ) ) ) ) ) ;
                                    end;
                                  end;
                                until false;
                                t= (W[C] ) ;
                                y=4;
                                repeat
                                  if not (y<=19.0)then
                                    if y==61.0 then
                                      M+=O;
                                      break;
                                    else
                                      O= (W[C] ) ;
                                      y= ( -25+ ( (v[46] [17.0] ( (v[46] [19.0] (y) ) -V+y-y) ) >y and y or y) ) ;
                                      continue;
                                    end;
                                  else
                                    if y>4.0 then
                                      if v[45] ~=v[46]then
                                        M=M(O) ;
                                        y= -4294967180+ (v[46] [19.0] ( (v[46] [11.0] ( (v[46] [18.0] ( (v[46] [17.0] (V) ) -y, (V) ) ) ,V,V) ) +V) ) ;
                                      end;
                                      continue;
                                    else
                                      O+=t;
                                      y= -10+ ( (v[46] [11.0] ( (v[46] [12.0] ( (v[46] [18.0] (y, (y) ) ) ) ) -V,V,y) ) +y~=V and V or y) ;
                                      continue;
                                    end;
                                  end;
                                until false;
                                y=24;
                                repeat
                                  if y<97.0 and y>24.0 then
                                    O= (q[C] ) ;
                                    break;
                                  elseif y<23.0 then
                                    l= (c[C] ) ;
                                    y=97+ (v[46] [12.0] ( (v[46] [19.0] ( (v[46] [16.0] ( (v[46] [19.0] ( (v[46] [19.0] (V) ) +V) ) ) ) ) ) ) ) ;
                                  else
                                    if y>76.0 then
                                      M=e;
                                      y= -21+ ( ( (y==V and y or V) +V-V<=V and y or y) -y>=y and y or y) ;
                                      continue;
                                    elseif y>23.0 and y<76.0 then
                                      O=W[C] ;
                                      M+=O;
                                      y= ( -4294967248+ (v[46] [14.0] ( (v[46] [19.0] ( (v[46] [18.0] (y+y~=y and y or y, (y) ) ) ==y and y or y) ) ) ) ) ;
                                      continue;
                                    else
                                      if not (y<24.0 and y>10.0)then
                                      else
                                        if v[7] ==v[49]then
                                          if not (v[5] -v[39] )then
                                          else
                                            return ;
                                          end;
                                          return v[37] ;
                                        end;
                                        if v[45] ~=v[2]then
                                          l+=M;
                                          b+=l;
                                          (W) [C] =b;
                                          b= (e) ;
                                          y= -4294967268+ ( (v[46] [16.0] ( (v[46] [20.0] (y-V-V+V, (V) ) ) ,y,y) ) +y) ;
                                        end;
                                        continue;
                                      end;
                                    end;
                                  end;
                                until false;
                                if o==v[46]then
                                  return ;
                                end;
                                if v[35] ~=v[25]then
                                else
                                  return 119%v[2] ;
                                end;
                                y=80;
                                repeat
                                  if y==2.0 then
                                    M= (M<=O) ;
                                    (b) [l] =M;
                                    break;
                                  else
                                    if y==111.0 then
                                      O= (K[C] ) ;
                                      y= (2+ (v[46] [17.0] ( (v[46] [12.0] ( (v[46] [22.0] (V+y+V, (V) ) ) ) ) -y) ) ) ;
                                    else
                                      if y==80.0 then
                                        M=M[O] ;
                                        y= ( -4294967184+ ( (v[46] [7.0] ( (v[46] [19.0] ( (v[46] [12.0] ( (v[46] [19.0] (y) ) ) ) ) ) , (V) ) ) -y+y) ) ;
                                      end;
                                    end;
                                  end;
                                until false;
                              end;
                            else
                              if V==28 then
                                (e) [j[C] ] = (e[c[C] ] %P[C] ) ;
                              else
                                y=P[C] ;
                                M-=y;
                              end;
                            end;
                          end;
                        else
                          if v[51] ==v[40]then
                            return v[5] ;
                          elseif v[5] ==v[43]then
                            while - ( -178)do
                              (v) [50] =191;
                            end;
                          else
                            if V>=22 then
                              if V>=24 then
                                if not (V<25)then
                                  if V==26 then
                                    if v[50] ~=v[46]then
                                      M= (P[C] ) ;
                                    end;
                                    b[l] =M;
                                  else
                                    if v[49] ==v[25]then
                                    else
                                      e[c[C] ] = (P[C] >=K[C] ) ;
                                    end;
                                  end;
                                else
                                  M= (M[y] ) ;
                                  y= (K[C] ) ;
                                end;
                              elseif V~=23 then
                                (e) [c[C] ] = (e[q[C] ] >e[j[C] ] ) ;
                              else
                                (e) [q[C] ] = (U[C] <K[C] ) ;
                              end;
                            else
                              if V>=20 then
                                if V~=21 then
                                  if v[52] ~=v[25]then
                                    (e[c[C] ] ) [e[j[C] ] ] = (P[C] ) ;
                                  end;
                                else
                                  e[c[C] ] = (I[j[C] ] ) ;
                                end;
                              else
                                if V~=19 then
                                  b=b[l] ;
                                  l=P[C] ;
                                else
                                  b= (e) ;
                                  l= (q[C] ) ;
                                  M=U[C] ;
                                end;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V<9)then
                          if V<13 then
                            if not (V<11)then
                              if V==12 then
                                (e) [c[C] ] =e[q[C] ] ~=K[C] ;
                              else
                                b= (69.0) ;
                                l=0;
                                M= (nil) ;
                                y=74;
                                while true do
                                  if y==74.0 then
                                    M=4503599627370495;
                                    y= ( -4294967262+ (v[46] [14.0] ( (v[46] [16.0] ( (v[46] [11.0] ( (v[46] [12.0] (y) ) -V,y) ) -V,y,y) ) ,V,y) ) ) ;
                                  elseif y==12.0 then
                                    M=v[46] ;
                                    break;
                                  else
                                    if y~=33.0 then
                                    else
                                      l*=M;
                                      y=1+ (v[46] [11.0] ( ( ( (y-V>=y and y or V) ~=V and y or V) ==V and V or y) <=y and V or V) ) ;
                                      continue;
                                    end;
                                  end;
                                end;
                                O= (22.0) ;
                                t=nil;
                                y= (83) ;
                                while true do
                                  if y<56.0 and y>22.0 then
                                    if v[40] ==v[33]then
                                      if not (v[38] )then
                                      else
                                        return v[45] ;
                                      end;
                                    end;
                                    if v[39] ==v[46]then
                                    else
                                      t= (v[46] ) ;
                                      break;
                                    end;
                                  elseif y>83.0 then
                                    t= (19.0) ;
                                    y= ( -4034920391+ (v[46] [20.0] ( ( (v[46] [19.0] (V) ) -y>y and y or y) -y-y, (V) ) ) ) ;
                                  elseif y<125.0 and y>56.0 then
                                    M=M[O] ;
                                    y= (11+ ( (v[46] [14.0] ( (v[46] [12.0] (y) ) ) ) -y+y-V>V and V or V) ) ;
                                  elseif y<83.0 and y>55.0 then
                                    O= (O[t] ) ;
                                    y= (44+ ( (v[46] [14.0] ( (v[46] [12.0] ( (v[46] [12.0] (y) ) ==y and y or V) ) ,V) ) -y>V and V or V) ) ;
                                    continue;
                                  elseif not (y<55.0)then
                                  elseif v[35] ~=v[40]then
                                    O=v[46] ;
                                    y= (158+ ( (v[46] [17.0] ( (V>=V and y or V) -y-V) ) -V-y) ) ;
                                  end;
                                end;
                                if v[35] ==v[25]then
                                else
                                  p= (nil) ;
                                  J= (nil) ;
                                  y=8;
                                end;
                                while true do
                                  if y>60.0 then
                                    if y<=71.0 then
                                      t=t[p] ;
                                      y=51+ ( ( (v[46] [14.0] (y~=V and y or y) ) +V<V and V or y) +V~=V and y or y) ;
                                      continue;
                                    else
                                      if v[33] ==v[25]then
                                      else
                                        if y==122.0 then
                                          if v[45] ==v[2]then
                                            while 164 do
                                              v[42] ,v[36] = -v[12] ,84;
                                            end;
                                          end;
                                          if v[22] ~=v[12]then
                                            p= (v[46] ) ;
                                            y= ( -126+ ( (v[46] [14.0] (y-y+V+y,V) ) +y-y) ) ;
                                          end;
                                        else
                                          J=V;
                                          break;
                                        end;
                                      end;
                                    end;
                                  elseif v[33] ==v[41]then
                                    (v) [35] ,v[42] =58,v[46] ;
                                    return - (107%154) ;
                                  elseif v[5] ==o then
                                    if not (v[38] )then
                                    else
                                      (v) [2] = (62) ;
                                      return -v[12] ;
                                    end;
                                    while v[36]do
                                      (v) [37] ,v[22] = -v[40] ,o;
                                    end;
                                  elseif y>8.0 then
                                    if y==17.0 then
                                      if v[40] ==v[37]then
                                      else
                                        J= (17.0) ;
                                        y= (43+ ( (v[46] [16.0] ( (v[46] [17.0] ( (v[46] [18.0] (V-V<y and V or V, (y) ) ) ) ) ,V) ) ~=y and y or V) ) ;
                                      end;
                                      continue;
                                    else
                                      p=p[J] ;
                                      y= ( -4294967188+ (v[46] [7.0] ( (v[46] [19.0] ( (v[46] [22.0] ( (v[46] [22.0] ( (y==y and y or V) -y, (V) ) ) , (V) ) ) ) ) , (V) ) ) ) ;
                                      continue;
                                    end;
                                  else
                                    p=17.0;
                                    y= (44+ (y+y+y-y+y-y+V) ) ;
                                  end;
                                end;
                                h=W[C] ;
                                J+=h;
                                y= (43) ;
                                repeat
                                  if y==14.0 then
                                    J=W[C] ;
                                    y= -14680043+ (v[46] [20.0] ( (v[46] [20.0] ( (v[46] [18.0] (y+y+y+y, (V) ) ) , (V) ) ) , (y) ) ) ;
                                    continue;
                                  else
                                    if y==21.0 then
                                      p-=J;
                                      t=t(p) ;
                                      break;
                                    else
                                      if y~=43.0 then
                                      else
                                        p=p(J) ;
                                        y= ( -29+ (v[46] [16.0] ( (v[46] [19.0] ( (v[46] [7.0] (V>=V and V or V, (V) ) ) -V) ) >y and y or V) ) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                until false;
                                y=72;
                                repeat
                                  if v[2] ==v[39]then
                                    if v[43] >=v[45]then
                                      v[25] = (v[36] ) ;
                                      (v) [49] ,v[2] =v[21] , (v[45] ) ;
                                    end;
                                    if 19 then
                                      return ;
                                    end;
                                  elseif y==7.0 then
                                    if v[50] ~=v[5]then
                                      O=O~=t;
                                    end;
                                    break;
                                  else
                                    if v[49] ==v[7]then
                                      (v) [12] ,v[37] =189,200;
                                    else
                                      if y~=72.0 then
                                      else
                                        O=O(t) ;
                                        t= (V) ;
                                        y= -150994937+ (v[46] [20.0] ( ( (v[46] [18.0] (y-y~=y and V or V, (V) ) ) ==y and y or V) >V and y or y, (V) ) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                until false;
                                if not (O)then
                                else
                                  O=W[C] ;
                                end;
                                if v[39] ~=v[46]then
                                  if not O then
                                    if v[52] ==v[12]then
                                    else
                                      O= (W[C] ) ;
                                    end;
                                  end;
                                end;
                                if v[7] ~=v[49]then
                                  t=V;
                                  y=12;
                                  while true do
                                    if y==101.0 then
                                      l+=M;
                                      y= ( -12+ ( (v[46] [16.0] ( (v[46] [14.0] ( (v[46] [16.0] (y>=V and y or y,V) ) ,y) ) +V,V) ) -y) ) ;
                                    elseif y==12.0 then
                                      O+=t;
                                      y= -4294967150+ ( (v[46] [19.0] ( (y-V==V and V or V) +y-y) ) -V) ;
                                    elseif y==95.0 then
                                      l= (q[C] ) ;
                                      y= (39+ ( (v[46] [22.0] ( (v[46] [20.0] (y<=y and y or y, (V) ) ) -V+V, (V) ) ) ==y and y or V) ) ;
                                    elseif y==123.0 then
                                      t=W[C] ;
                                      y= ( -93+ (v[46] [11.0] ( (v[46] [14.0] ( (v[46] [16.0] ( (v[46] [20.0] ( (v[46] [11.0] (V,y) ) , (V) ) ) ) ) ,V,V) ) ==y and V or y) ) ) ;
                                    else
                                      if y==30.0 then
                                        M=M(O,t) ;
                                        y= ( -1073741693+ ( (v[46] [18.0] ( (v[46] [14.0] ( (v[46] [11.0] (y,y,y) ) -V,y,V) ) -y, (y) ) ) -y) ) ;
                                      elseif y==50.0 then
                                        M=e;
                                        break;
                                      else
                                        if y~=0.0 then
                                        else
                                          b+=l;
                                          (W) [C] =b;
                                          b= (e) ;
                                          y= (95+ ( (v[46] [18.0] (y-y>=y and y or V, (V) ) ) +y+y<V and y or V) ) ;
                                          continue;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                                if v[40] ~=v[39]then
                                  y= (73) ;
                                  while true do
                                    if y~=20.0 then
                                      O=j[C] ;
                                      y=9+ ( (v[46] [11.0] ( (v[46] [12.0] (y-y+V==y and y or y) ) ) ) >V and V or y) ;
                                    else
                                      M= (M[O] ) ;
                                      break;
                                    end;
                                  end;
                                  O= (e) ;
                                  t= (c[C] ) ;
                                  y=99;
                                  while true do
                                    if y>99.0 then
                                      M= (M<O) ;
                                      break;
                                    else
                                      if y<102.0 then
                                        O=O[t] ;
                                        y= (201+ ( (v[46] [12.0] ( (v[46] [19.0] ( (v[46] [12.0] ( (v[46] [19.0] (y) ) <V and V or y) ) ) ) ) ) -y) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                  b[l] = (M) ;
                                end;
                              end;
                            else
                              if v[38] ~=v[25]then
                              else
                                (v) [37] ,v[38] = -v[42] ,v[51] ;
                              end;
                              if V~=10 then
                                b= (e) ;
                              else
                                e[q[C] ] [e[j[C] ] ] =e[c[C] ] ;
                              end;
                            end;
                          else
                            if not (V<15)then
                              if not (V>=16)then
                                if v[51] ==v[33]then
                                else
                                  y=U[C] ;
                                  M+=y;
                                end;
                                b[l] =M;
                              else
                                if v[38] ==v[12]then
                                  repeat
                                    o=13;
                                  until false;
                                  return ;
                                else
                                  if v[21] ==v[7]then
                                    while -v[21]do
                                      o,v[39] =v[7] , (37) ;
                                      return ;
                                    end;
                                  else
                                    if V~=17 then
                                      M=U[C] ;
                                      y= (e) ;
                                    else
                                      I[j[C] ] [U[C] ] = (e[q[C] ] ) ;
                                    end;
                                  end;
                                end;
                              end;
                            else
                              if V~=14 then
                                b=I[q[C] ] ;
                                e[c[C] ] = (b[2] [b[1] ] ) ;
                              elseif v[40] ~=v[42]then
                                b= (I[j[C] ] ) ;
                                (b[2] ) [b[1] ] = (U[C] ) ;
                              end;
                            end;
                          end;
                        else
                          if V<4 then
                            if V<2 then
                              if V==1 then
                                y=U[C] ;
                              else
                                if U[C] <=e[j[C] ]then
                                  C= (q[C] ) ;
                                end;
                              end;
                            else
                              if V==3 then
                                y= (j[C] ) ;
                              else
                                (e) [c[C] ] = (e[q[C] ] -e[j[C] ] ) ;
                              end;
                            end;
                          else
                            if not (V>=6)then
                              if V~=5 then
                                b=nil;
                                l=nil;
                                M= (nil) ;
                                y=nil;
                                O= (20) ;
                                repeat
                                  if O==99.0 then
                                    y= (0) ;
                                    break;
                                  else
                                    if O==20.0 then
                                      b=j[C] ;
                                      l=q[C] ;
                                      M= (223.0) ;
                                      O=103+ ( (v[46] [12.0] ( (v[46] [17.0] ( (v[46] [19.0] (O) ) ) ) -O-O) ) -V) ;
                                    end;
                                  end;
                                until false;
                                t= (4503599627370495) ;
                                p=nil;
                                J= (nil) ;
                                O=118;
                                repeat
                                  if O<=23.0 then
                                    if O==23.0 then
                                      p=v[46] ;
                                      O= (9+ (v[46] [16.0] ( (v[46] [17.0] ( (v[46] [19.0] ( (v[46] [16.0] (O,V) ) +O+O) ) ) ) ,V,V) ) ) ;
                                    else
                                      if v[40] ~=v[7]then
                                        J=16.0;
                                        p=p[J] ;
                                      end;
                                      break;
                                    end;
                                  else
                                    if not (O>24.0)then
                                      t=t[p] ;
                                      O= (19+ ( (v[46] [11.0] ( (v[46] [14.0] ( (O+V>=O and V or O) +V,O) ) ,V,O) ) +V) ) ;
                                    elseif not (O>=118.0)then
                                      t= (v[46] ) ;
                                      p=12.0;
                                      O= (24+ (v[46] [11.0] ( (v[46] [7.0] (V+O+V+O+O, (V) ) ) ,V,V) ) ) ;
                                    else
                                      if v[2] ==v[51]then
                                      else
                                        y*=t;
                                        O= -4294967080+ ( (v[46] [19.0] ( (v[46] [11.0] ( (v[46] [17.0] ( (v[46] [17.0] (V) ) ) ) ,O) ) <=O and O or V) ) -V) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                until false;
                                h=nil;
                                O=83;
                                repeat
                                  if O==83.0 then
                                    J=W[C] ;
                                    h=V;
                                    O= (18+ ( (v[46] [7.0] ( (v[46] [20.0] ( (v[46] [17.0] ( (v[46] [12.0] ( (v[46] [16.0] (V,O,O) ) ) ) ) ) , (V) ) ) , (V) ) ) +V) ) ;
                                    continue;
                                  else
                                    if v[21] ==v[46]then
                                      if not (v[38] )then
                                      else
                                        return ;
                                      end;
                                      v[37] ,v[38] =58, (32) ;
                                    else
                                      if O~=22.0 then
                                      else
                                        J+=h;
                                        break;
                                      end;
                                    end;
                                  end;
                                until false;
                                F=nil;
                                O=85;
                                repeat
                                  if O>79.0 and O<98.0 then
                                    h=W[C] ;
                                    O= -1426063312+ (v[46] [20.0] ( (v[46] [20.0] ( (v[46] [14.0] ( (v[46] [14.0] (V+V,V) ) +V,V,O) ) , (V) ) ) , (V) ) ) ;
                                  else
                                    if O<79.0 then
                                      F=W[C] ;
                                      O= (11+ (v[46] [16.0] ( (v[46] [16.0] ( (v[46] [14.0] ( (V-O<=O and O or V) +O,O,V) ) ,O,V) ) ,V) ) ) ;
                                    else
                                      if O>85.0 then
                                        J= (W[C] ) ;
                                        break;
                                      else
                                        if O<85.0 and O>48.0 then
                                          p=p(J,h,F) ;
                                          O= -268435432+ ( (v[46] [22.0] ( (v[46] [17.0] ( (v[46] [16.0] ( (v[46] [11.0] (O,V,V) ) ,V,V) ) ) ) -O, (V) ) ) +O) ;
                                          continue;
                                        end;
                                      end;
                                    end;
                                  end;
                                until false;
                                if v[22] ==v[33]then
                                else
                                  p-=J;
                                end;
                                J=V;
                                O= (101) ;
                                repeat
                                  if O==95.0 then
                                    if v[21] ==v[40]then
                                      v[37] ,v[2] =v[25] ,v[38] ;
                                      while v[46]do
                                        v[5] ,v[38] =v[42] , -v[33] ;
                                        return ;
                                      end;
                                    end;
                                    t+=p;
                                    break;
                                  else
                                    if O==0.0 then
                                      if v[51] ==v[12]then
                                      else
                                        t=t(p) ;
                                        p= (W[C] ) ;
                                      end;
                                      O=95+ ( (v[46] [12.0] ( (v[46] [12.0] (O<=V and O or V) ) +V) ) +V<O and V or O) ;
                                    else
                                      if O~=101.0 then
                                      else
                                        p-=J;
                                        O= -4294967190+ (v[46] [19.0] ( ( (v[46] [7.0] ( (v[46] [18.0] (O~=O and O or V, (V) ) ) , (V) ) ) ~=V and V or V) +O) ) ;
                                      end;
                                    end;
                                  end;
                                until false;
                                p=V;
                                O= (8) ;
                                repeat
                                  if O~=8.0 then
                                    p= (V) ;
                                    break;
                                  else
                                    if v[52] ==v[5]then
                                      if not (v[49]or v[45] )then
                                      else
                                        return ;
                                      end;
                                    end;
                                    t+=p;
                                    O=71+ (v[46] [17.0] ( (v[46] [14.0] ( (v[46] [19.0] (O+O+V) ) ) ) -V) ) ;
                                    continue;
                                  end;
                                until false;
                                t-=p;
                                O=34;
                                repeat
                                  if O<25.0 then
                                    if v[21] ~=v[33]then
                                      g=113;
                                      while true do
                                        if g>46.0 then
                                          if g~=113.0 then
                                            g=46;
                                            p=b;
                                            continue;
                                          else
                                            y= (v[3] ) ;
                                            g= (28) ;
                                            continue;
                                          end;
                                        else
                                          if v[41] ==v[5]then
                                            return ;
                                          else
                                            if v[52] ==v[25]then
                                              while v[36]do
                                                v[42] = (v[25] ) ;
                                                v[35] ,v[25] =v[43] >205,v[50] ;
                                              end;
                                            else
                                              if g<46.0 then
                                                g=75;
                                                t=e;
                                              else
                                                if v[21] ==v[46]then
                                                else
                                                  J= (1.0) ;
                                                end;
                                                break;
                                              end;
                                            end;
                                          end;
                                        end;
                                      end;
                                    end;
                                    p+=J;
                                    g=110;
                                    repeat
                                      if not (g>110.0)then
                                        if v[45] ==v[40]then
                                          while v[25]do
                                            return v[12] ;
                                          end;
                                        end;
                                        J= (_) ;
                                        g= (117) ;
                                        h=l;
                                        continue;
                                      else
                                        F= (1.0) ;
                                        break;
                                      end;
                                    until false;
                                    if v[36] ==v[25]then
                                      while v[25]do
                                        (v) [51] ,v[43] =v[39] ,v[2] ;
                                        return 94;
                                      end;
                                    end;
                                    for Y=58,106,43 do
                                      if Y==101 then
                                        (y) (t,p,J,h,F) ;
                                        break;
                                      else
                                        if Y~=58 then
                                        else
                                          h+=F;
                                          F=M;
                                          continue;
                                        end;
                                      end;
                                    end;
                                    break;
                                  elseif O<51.0 and O>34.0 then
                                    (W) [C] =M;
                                    O=51+ (v[46] [22.0] ( (v[46] [16.0] ( (v[46] [22.0] (O-O==O and V or O, (V) ) ) +O,O) ) , (V) ) ) ;
                                    continue;
                                  elseif O>36.0 and O<93.0 then
                                    M= (e) ;
                                    O=126+ ( (v[46] [17.0] ( (O+V<=O and O or O) ~=V and O or O) ) -V-V) ;
                                  elseif O<36.0 and O>25.0 then
                                    y+=t;
                                    O=19+ ( (v[46] [17.0] ( (v[46] [22.0] (O-O+V, (V) ) ) +V) ) +V) ;
                                  else
                                    if O<34.0 and O>24.0 then
                                      M+=y;
                                      O= (82+ ( (v[46] [20.0] ( (O<V and O or O) -O, (V) ) ) +V-O-O) ) ;
                                    elseif O>51.0 and O<118.0 then
                                      M= (M[y] ) ;
                                      O= ( -65+ ( (v[46] [22.0] ( (v[46] [16.0] (O+O<=V and V or V) ) , (V) ) ) +O-V) ) ;
                                      continue;
                                    else
                                      if not (O>93.0)then
                                      else
                                        y=b;
                                        O= ( -147+ ( ( (v[46] [20.0] (O+V+V, (V) ) ) ~=O and O or O) +V+O) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                until false;
                              else
                                if v[37] ~=v[33]then
                                else
                                  while -131 do
                                    (v) [43] ,v[33] =o,g;
                                  end;
                                  repeat
                                    v[41] ,v[22] =v[36] ,138;
                                    return ;
                                  until false;
                                end;
                                s= ( {
                                  [4] =Z, [3] =x, [5] =s, [1] =E
                                } ) ;
                                b= (j[C] ) ;
                                x=e[b+2.0] +0.0;
                                E=e[b+1.0] +0.0;
                                Z= (e[b] -x) ;
                                C= (c[C] ) ;
                              end;
                            else
                              if not (V<7)then
                                if V==8 then
                                  M-=y;
                                else
                                  b= (160.0) ;
                                  l=nil;
                                  M= (nil) ;
                                  y=101;
                                  repeat
                                    if y<101.0 then
                                      l*=M;
                                      break;
                                    else
                                      if y>0.0 then
                                        l= (0) ;
                                        M= (4503599627370495) ;
                                        y= -4294967201+ ( (v[46] [19.0] ( (v[46] [19.0] ( (v[46] [18.0] (V, (V) ) ) +y) ) >y and y or q[C] ) ) +V) ;
                                        continue;
                                      end;
                                    end;
                                  until false;
                                  M=v[46] ;
                                  O=nil;
                                  y=53;
                                  repeat
                                    if v[41] ~=v[46]then
                                      if y==16.0 then
                                        M= (M[O] ) ;
                                        O=v[46] ;
                                        break;
                                      else
                                        if y~=53.0 then
                                        else
                                          if v[22] ==v[5]then
                                          else
                                            O= (17.0) ;
                                          end;
                                          y= -37+ ( (v[46] [17.0] ( (v[46] [12.0] ( (v[46] [7.0] ( (v[46] [11.0] (q[C] ,y,q[C] ) ) , (V) ) ) ) ) ) ) +q[C] ==y and V or y) ;
                                          continue;
                                        end;
                                      end;
                                    end;
                                  until false;
                                  t= (nil) ;
                                  p=nil;
                                  y=117;
                                  while true do
                                    if y==80.0 then
                                      O=O[t] ;
                                      y=110+ (v[46] [17.0] ( ( (v[46] [22.0] ( (v[46] [19.0] (q[C] ) ) , (V) ) ) -y<=y and y or y) +q[C] ) ) ;
                                    else
                                      if y==121.0 then
                                        t-=p;
                                        break;
                                      else
                                        if y==111.0 then
                                          t=q[C] ;
                                          y= -29098093+ ( (v[46] [14.0] ( (v[46] [22.0] ( (v[46] [20.0] ( (v[46] [14.0] (y,y,V) ) , (V) ) ) +V, (V) ) ) ) ) +y) ;
                                          continue;
                                        elseif y==117.0 then
                                          t= (14.0) ;
                                          y= (73+ ( (v[46] [17.0] (V-V-y-V>=y and q[C]or y) ) ==V and y or V) ) ;
                                        else
                                          if y==2.0 then
                                            p= (V) ;
                                            y= (121+ (v[46] [11.0] ( ( (v[46] [19.0] (y+q[C] -V) ) <=q[C]and y or q[C] ) +q[C] ,y,V) ) ) ;
                                            continue;
                                          end;
                                        end;
                                      end;
                                    end;
                                  end;
                                  if v[51] ~=v[12]then
                                    J= (nil) ;
                                  end;
                                  y=3;
                                  repeat
                                    if y==3.0 then
                                      p=q[C] ;
                                      J= (V) ;
                                      y= -536870912+ (v[46] [20.0] ( ( (v[46] [17.0] ( (v[46] [19.0] (y) ) +y) ) <=q[C]and y or y) +q[C] , (y) ) ) ;
                                      continue;
                                    else
                                      O=O(t,p,J) ;
                                      break;
                                    end;
                                  until false;
                                  t=W[C] ;
                                  O-=t;
                                  t=W[C] ;
                                  y= (49) ;
                                  while true do
                                    if y<49.0 then
                                      if v[33] ~=v[49]then
                                      else
                                        if not (250)then
                                        else
                                          return ;
                                        end;
                                        if not (v[7] )then
                                        else
                                          o= (v[49] ) ;
                                        end;
                                      end;
                                      M-=O;
                                      y= ( -4294967117+ ( (v[46] [19.0] ( (v[46] [22.0] (V+y, (V) ) ) +y+y) ) -q[C] ) ) ;
                                    else
                                      if y<110.0 and y>49.0 then
                                        if v[43] ==v[12]then
                                          if not (109)then
                                          else
                                            return ;
                                          end;
                                          while -v[38]do
                                            v[42] ,v[12] =v[51] % -129, (v[50] ) ;
                                          end;
                                        end;
                                        O= (W[C] ) ;
                                        y= -6029+ (v[46] [11.0] ( (v[46] [7.0] (q[C] , (V) ) ) +V+q[C] +y+V) ) ;
                                      elseif y<92.0 and y>11.0 then
                                        O-=t;
                                        M=M(O) ;
                                        y= ( -1845493669+ (v[46] [20.0] ( (v[46] [14.0] ( (v[46] [14.0] ( (v[46] [12.0] (y) ) +q[C] ,V,y) ) +V,y,y) ) , (V) ) ) ) ;
                                        continue;
                                      else
                                        if y>92.0 then
                                          O= (q[C] ) ;
                                          M=M<=O;
                                          break;
                                        end;
                                      end;
                                    end;
                                  end;
                                  if M then
                                    M= (V) ;
                                  end;
                                  if not (not M)then
                                  else
                                    if v[38] ==v[40]then
                                    else
                                      M=V;
                                    end;
                                  end;
                                  y= (12) ;
                                  while true do
                                    if y<123.0 then
                                      O= (W[C] ) ;
                                      y=119+ (v[46] [12.0] ( (v[46] [20.0] ( (v[46] [7.0] ( (v[46] [16.0] ( (v[46] [20.0] (q[C] <=y and y or V, (V) ) ) ,y,q[C] ) ) , (V) ) ) , (V) ) ) ) ) ;
                                    else
                                      M-=O;
                                      break;
                                    end;
                                  end;
                                  l+=M;
                                  y=37;
                                  while true do
                                    if y==31.0 then
                                      b=U[C] ;
                                      break;
                                    elseif y==37.0 then
                                      b+=l;
                                      y= ( -37+ (v[46] [14.0] ( (v[46] [12.0] ( ( (v[46] [12.0] (y) ) ~=q[C]and V or y) +V) ) +y,y) ) ) ;
                                      continue;
                                    else
                                      if y==64.0 then
                                        W[C] =b;
                                        y= ( -936+ (v[46] [14.0] ( (v[46] [11.0] ( (v[46] [7.0] ( (v[46] [22.0] (y, (V) ) ) ==V and q[C]or V, (V) ) ) +V) ) ,y) ) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                  l=e;
                                  y= (117) ;
                                  repeat
                                    if y==80.0 then
                                      if b then
                                        b=j[C] ;
                                        C=b;
                                      end;
                                      if v[41] ~=v[25]then
                                      else
                                        while v[33]do
                                          v[46] =v[12] ;
                                        end;
                                        return ;
                                      end;
                                      break;
                                    else
                                      if y==117.0 then
                                        if v[38] ==v[40]then
                                        else
                                          M=q[C] ;
                                          l= (l[M] ) ;
                                        end;
                                        b=b==l;
                                        y=119+ ( ( (v[46] [14.0] ( (v[46] [22.0] (V>q[C]and V or y, (V) ) ) ,y,q[C] ) ) +y==y and y or V) -q[C] ) ;
                                        continue;
                                      end;
                                    end;
                                  until false;
                                end;
                              else
                                b=c[C] ;
                                l= (j[C] ) ;
                                _= (b+l-1.0) ;
                                if not (T)then
                                else
                                  for Y,m in T do
                                    if Y>=1.0 then
                                      m[2] =m;
                                      m[3] = (e[Y] ) ;
                                      (m) [1] =3;
                                      (T) [Y] =nil;
                                    end;
                                  end;
                                end;
                                return e[b] (v[22] (e,_,b+1.0) ) ;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
              else
                if V<222 then
                  if v[52] ~=v[33]then
                  else
                    return ;
                  end;
                  if V<185 then
                    if V<166 then
                      if not (V<157)then
                        if v[35] ==v[46]then
                          return 99;
                        else
                          if v[5] ==v[22]then
                            return 107*147<v[33] ;
                          else
                            if V<161 then
                              if v[51] ==v[7]then
                                while v[43]do
                                  (v) [12] ,v[33] =o,127;
                                end;
                              else
                                if V<159 then
                                  if v[50] ==v[7]then
                                    while v[37]do
                                      return v[7] ;
                                    end;
                                    if v[22]then
                                      v[25] ,o=v[37] ,v[43] ;
                                      return -34;
                                    end;
                                  elseif v[36] ==v[7]then
                                    return ;
                                  else
                                    if V==158 then
                                      l=q[C] ;
                                      M= (K[C] ) ;
                                    else
                                      if v[43] ==v[25]then
                                        if not (v[42] )then
                                        else
                                          return ;
                                        end;
                                      else
                                        if v[2] ==v[45]then
                                          while v[45]do
                                            return ;
                                          end;
                                        else
                                          if not (T)then
                                          else
                                            if v[49] ~=v[25]then
                                            else
                                              return ;
                                            end;
                                            for Y,m,u in T do
                                              if not (Y>=1.0)then
                                              else
                                                (m) [2] =m;
                                                m[3] = (e[Y] ) ;
                                                (m) [1] = (3) ;
                                                T[Y] =nil;
                                              end;
                                            end;
                                          end;
                                        end;
                                      end;
                                      b= (q[C] ) ;
                                      return e[b] (e[b+1.0] ) ;
                                    end;
                                  end;
                                else
                                  if V==160 then
                                    if U[C] ~=e[q[C] ]then
                                    else
                                      C=j[C] ;
                                    end;
                                  else
                                    b= (e) ;
                                    l= (_) ;
                                    M= (e) ;
                                  end;
                                end;
                              end;
                            else
                              if V>=163 then
                                if v[46] ==v[5]then
                                  v[22] = (v[12] ) ;
                                else
                                  if not (V>=164)then
                                    (e) [q[C] ] =K[C] ==e[c[C] ] ;
                                  else
                                    if V~=165 then
                                      b= (j[C] ) ;
                                      e[b] (e[b+1.0] ) ;
                                      _= (b-1.0) ;
                                    else
                                      (e) [q[C] ] = (K[C] ~=U[C] ) ;
                                    end;
                                  end;
                                end;
                              else
                                if V==162 then
                                  M= (U[C] ) ;
                                  b[l] =M;
                                else
                                  (e) [j[C] ] = (I[q[C] ] [e[c[C] ] ] ) ;
                                end;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V<152)then
                          if not (V<154)then
                            if not (V>=155)then
                              l= (1.0) ;
                              b-=l;
                            else
                              if v[7] ==v[42]then
                                return v[7] ;
                              end;
                              if v[2] ==v[51]then
                                return ;
                              else
                                if v[43] ==v[2]then
                                  v[41] ,v[36] =v[7]and v[39] ,v[33] ;
                                  (v) [25] =v[42] ;
                                else
                                  if V==156 then
                                    if v[45] ==v[5]then
                                    else
                                      H= (j[C] ) ;
                                    end;
                                    d,a=v[52] ( ... ) ;
                                    for Y=1.0,H,1 do
                                      e[Y] =a[Y] ;
                                    end;
                                    r=H+1.0;
                                  else
                                    y= (e) ;
                                    O= (c[C] ) ;
                                    y= (y[O] ) ;
                                  end;
                                end;
                              end;
                            end;
                          else
                            if V==153 then
                              if v[35] ==v[2]then
                                if v[22]then
                                  return ;
                                end;
                              end;
                              b=b[l] ;
                              (b) ( ) ;
                              b=_;
                            else
                              b= (I[c[C] ] ) ;
                              b[2] [b[1] ] [e[j[C] ] ] = (e[q[C] ] ) ;
                            end;
                          end;
                        else
                          if V>=150 then
                            if V~=151 then
                              (e) [j[C] ] = -e[c[C] ] ;
                            else
                              e[j[C] ] = (e[c[C] ] [e[q[C] ] ] ) ;
                            end;
                          elseif V==149 then
                          else
                            if not (T)then
                            else
                              for Y,m,u in T do
                                if not (Y>=1.0)then
                                else
                                  (m) [2] = (m) ;
                                  (m) [3] =e[Y] ;
                                  (m) [1] = (3) ;
                                  (T) [Y] = (nil) ;
                                end;
                              end;
                            end;
                            b= (j[C] ) ;
                            return e[b] (v[22] (e,_,b+1.0) ) ;
                          end;
                        end;
                      end;
                    else
                      if not (V>=175)then
                        if V>=170 then
                          if not (V>=172)then
                            if v[43] ~=v[40]then
                            else
                              v[50] = (o<= (57>220) ) ;
                            end;
                            if V==171 then
                              b=e;
                            else
                              M=X;
                            end;
                          else
                            if not (V>=173)then
                              e[c[C] ] =P[C] >e[j[C] ] ;
                            else
                              if V==174 then
                                if v[37] ==v[7]then
                                else
                                  O=j[C] ;
                                  y= (y[O] ) ;
                                  M+=y;
                                end;
                              else
                                e[q[C] ] =K[C] +U[C] ;
                              end;
                            end;
                          end;
                        else
                          if V<168 then
                            if V~=167 then
                              l=j[C] ;
                              M= (e) ;
                            else
                              (e) [q[C] ] = (e) ;
                            end;
                          else
                            if V~=169 then
                              e[j[C] ] = (X[U[C] ] ) ;
                            else
                              if e[c[C] ] <K[C]then
                                C=q[C] ;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V>=180)then
                          if V<177 then
                            if v[5] ==v[45]then
                              return -67 and v[38] ;
                            else
                              if v[51] ==v[40]then
                                if not (v[45] )then
                                else
                                  return ;
                                end;
                              else
                                if V==176 then
                                  b[l] =M;
                                else
                                  b= (e) ;
                                end;
                              end;
                            end;
                          else
                            if V<178 then
                              e[j[C] ] = (v[47] (e[c[C] ] ,P[C] ) ) ;
                            else
                              if V~=179 then
                                e[c[C] ] = (K[C] *e[q[C] ] ) ;
                              else
                                y= (c[C] ) ;
                                M= (M[y] ) ;
                              end;
                            end;
                          end;
                        else
                          if not (V<182)then
                            if not (V>=183)then
                              (e) [j[C] ] =q;
                            else
                              if v[46] ==v[38]then
                                (v) [51] ,v[43] =v[39] ,v[22] ;
                              else
                                if v[5] ==v[50]then
                                  while v[42]or 186 do
                                    return v[52] ;
                                  end;
                                  while v[35]do
                                    return ;
                                  end;
                                else
                                  if V~=184 then
                                    y=c[C] ;
                                    M=M[y] ;
                                  else
                                    b= (I[c[C] ] ) ;
                                    (e) [j[C] ] =b[2] [b[1] ] [P[C] ] ;
                                  end;
                                end;
                              end;
                            end;
                          else
                            if V~=181 then
                              if v[45] ==v[40]then
                              else
                                y=U[C] ;
                                M=M[y] ;
                              end;
                              b[l] = (M) ;
                            else
                              M=M( ) ;
                              (b) [l] =M;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if v[43] ~=v[25]then
                      if not (V>=203)then
                        if V<194 then
                          if v[51] ~=v[5]then
                            if V>=189 then
                              if not (V<191)then
                                if V>=192 then
                                  if V==193 then
                                    l=U[C] ;
                                  else
                                    b= (c[C] ) ;
                                    e[b] =e[b] (e[b+1.0] ,e[b+2.0] ) ;
                                    _= (b) ;
                                  end;
                                else
                                  e[c[C] ] =v[23] (j[C] ) ;
                                end;
                              else
                                if V~=190 then
                                  M=M[y] ;
                                else
                                  M=M[y] ;
                                end;
                              end;
                            else
                              if not (V<187)then
                                if V~=188 then
                                  b=b[l] ;
                                else
                                  e[q[C] ] = (v[27] (e[c[C] ] ,K[C] ) ) ;
                                end;
                              else
                                if V~=186 then
                                  if v[5] ~=v[43]then
                                    y=y[O] ;
                                    M+=y;
                                    b[l] = (M) ;
                                  end;
                                else
                                  y= (q[C] ) ;
                                end;
                              end;
                            end;
                          end;
                        else
                          if not (V>=198)then
                            if o==v[40]then
                              if v[33]then
                                (v) [35] = (v[42] ) ;
                              end;
                              if not (113)then
                              else
                                return ;
                              end;
                            else
                              if V<196 then
                                if V~=195 then
                                  y= (_) ;
                                else
                                  M+=y;
                                  b[l] = (M) ;
                                end;
                              else
                                if V==197 then
                                  if v[46] ~=v[42]then
                                  else
                                    (v) [5] = ( -v[39] ) ;
                                    return 254;
                                  end;
                                  if e[q[C] ] ==e[j[C] ]then
                                    if v[51] ==v[25]then
                                    else
                                      C=c[C] ;
                                    end;
                                  end;
                                else
                                  M= (M>y) ;
                                end;
                              end;
                            end;
                          else
                            if not (V>=200)then
                              if V~=199 then
                                (e) [j[C] ] = (e[c[C] ] +e[q[C] ] ) ;
                              else
                                (e) [c[C] ] =P[C] >K[C] ;
                              end;
                            else
                              if V>=201 then
                                if v[7] ==v[50]then
                                  while v[36] < -192 do
                                    (v) [35] ,v[25] =v[22] , ( -203) ;
                                    (v) [37] ,v[35] =v[42] ,10 or v[43] ;
                                  end;
                                elseif v[33] ==v[50]then
                                  (v) [21] = (v[21] ) ;
                                else
                                  if V==202 then
                                    (e) [q[C] ] =N;
                                  else
                                    if v[25] ~=v[51]then
                                      M=e;
                                      y= (c[C] ) ;
                                    end;
                                    M= (M[y] ) ;
                                  end;
                                end;
                              else
                                b=e;
                                l=j[C] ;
                                M=e;
                              end;
                            end;
                          end;
                        end;
                      else
                        if not (V>=212)then
                          if not (V>=207)then
                            if V<205 then
                              if V==204 then
                                b=b[l] ;
                                l= (P[C] ) ;
                              else
                                M= (M[y] ) ;
                                (b) [l] =M;
                              end;
                            else
                              if V~=206 then
                                e[j[C] ] =U[C] ;
                              else
                                if v[2] ~=v[40]then
                                  b=K[C] ;
                                end;
                                l=b[9] ;
                                if v[25] ==v[43]then
                                  while v[39]do
                                    return - ( -162) ;
                                  end;
                                end;
                                if v[51] ==v[5]then
                                else
                                  M= ( #l) ;
                                  y= (M>0.0 and {
                                  } ) ;
                                  O=v[53] (b,y) ;
                                  (v[24] ) (O,X) ;
                                  (e) [q[C] ] =O;
                                  if not (y)then
                                  else
                                    for N=1.0,M,1 do
                                      b= (l[N] ) ;
                                      O=b[2] ;
                                      t=b[1] ;
                                      if O==0.0 then
                                        if not (not T)then
                                        else
                                          T= {
                                          } ;
                                        end;
                                        p=T[t] ;
                                        if not (not p)then
                                        elseif v[42] ~=v[5]then
                                          p= ( {
                                            [2] =e, [1] =t
                                          } ) ;
                                          (T) [t] = (p) ;
                                        end;
                                        (y) [N-1.0] = (p) ;
                                      else
                                        if O~=1.0 then
                                          y[N-1.0] = (I[t] ) ;
                                        else
                                          if v[41] ==v[12]then
                                            while v[41]do
                                              (v) [36] = ( -v[7] ) ;
                                            end;
                                            while v[2]do
                                              return o;
                                            end;
                                          end;
                                          y[N-1.0] = (e[t] ) ;
                                        end;
                                      end;
                                    end;
                                  end;
                                end;
                              end;
                            end;
                          else
                            if V>=209 then
                              if V>=210 then
                                if V~=211 then
                                  e[q[C] ] =not e[c[C] ] ;
                                else
                                  M= (M~=y) ;
                                  (b) [l] =M;
                                end;
                              else
                                M= (U[C] ) ;
                                b[l] =M;
                              end;
                            else
                              if V~=208 then
                                M= (U[C] ) ;
                                y= (e) ;
                                O= (j[C] ) ;
                              else
                                M=e;
                              end;
                            end;
                          end;
                        else
                          if v[33] ==v[41]then
                            while v[25]do
                              (v) [39] ,v[46] =v[49] ,v[52] ;
                              v[37] ,v[12] =o,v[40] ;
                            end;
                          elseif v[51] ==v[5]then
                            if v[21]then
                              (v) [22] = (v[38] ) ;
                              return ;
                            end;
                            if -v[50]then
                              return ;
                            end;
                          else
                            if not (V<217)then
                              if not (V<219)then
                                if not (V<220)then
                                  if V~=221 then
                                    e[q[C] ] = (U[C] ^e[j[C] ] ) ;
                                  else
                                    if v[21] ==v[12]then
                                      (v) [39] ,v[36] =102, -v[36] ;
                                    end;
                                    y=y[O] ;
                                    M-=y;
                                    b[l] =M;
                                  end;
                                else
                                  if not (e[q[C] ] <=e[j[C] ] )then
                                  else
                                    C= (c[C] ) ;
                                  end;
                                end;
                              else
                                if v[35] ==v[7]then
                                  return ;
                                else
                                  if V==218 then
                                    b= (e) ;
                                    l= (q[C] ) ;
                                  else
                                    (e) [q[C] ] =I[c[C] ] [K[C] ] ;
                                  end;
                                end;
                              end;
                            else
                              if v[52] ~=v[7]then
                              else
                                return -242 or v[40] ;
                              end;
                              if not (V>=214)then
                                if V==213 then
                                  e[q[C] ] =e[j[C] ] ^U[C] ;
                                else
                                  if v[49] ==v[46]then
                                    if v[39]then
                                      return ;
                                    end;
                                    return ;
                                  else
                                    if not (P[C] <e[j[C] ] )then
                                    else
                                      C= (c[C] ) ;
                                    end;
                                  end;
                                end;
                              else
                                if V<215 then
                                  b=nil;
                                  l=nil;
                                  M= (nil) ;
                                  y=33;
                                  while true do
                                    if y==12.0 then
                                      M= (4503599627370495) ;
                                      break;
                                    else
                                      b=220.0;
                                      l=0;
                                      y= -597+ ( (v[46] [16.0] ( ( (v[46] [16.0] (y,y,V) ) >=y and V or V) +V-y) ) +V) ;
                                    end;
                                  end;
                                  if v[22] ==v[40]then
                                    return ;
                                  end;
                                  l*=M;
                                  O= (nil) ;
                                  y= (23) ;
                                  while true do
                                    if not (y>10.0)then
                                      O=11.0;
                                      y= ( -219039+ (v[46] [7.0] ( (v[46] [16.0] ( ( (V>y and y or y) <y and V or V) -V<y and y or y,y,V) ) , (y) ) ) ) ;
                                      continue;
                                    else
                                      if not (y<=23.0)then
                                        M=M[O] ;
                                        break;
                                      else
                                        M= (v[46] ) ;
                                        y=192+ ( (v[46] [12.0] ( (v[46] [22.0] ( (v[46] [19.0] (V==V and V or y) ) <=y and y or V, (y) ) ) ) ) -V) ;
                                      end;
                                    end;
                                  end;
                                  if v[42] ==v[33]then
                                  else
                                    O= (v[46] ) ;
                                  end;
                                  t=nil;
                                  y= (120) ;
                                  while true do
                                    if v[21] ==v[2]then
                                      while v[52]do
                                        v[38] ,v[38] =v[46] ,v[45] ^v[37] ;
                                        return ;
                                      end;
                                      v[33] = ( - ( -186) ) ;
                                    end;
                                    if y<120.0 then
                                      if v[35] ==v[33]then
                                        v[46] ,v[52] =v[49] , (v[42] ) ;
                                      end;
                                      if v[50] ==v[2]then
                                      else
                                        O= (O[t] ) ;
                                        break;
                                      end;
                                    elseif y>119.0 then
                                      t=22.0;
                                      y= -4294966320+ (v[46] [16.0] ( (v[46] [7.0] (V-y+V-V-y, (5) ) ) ,y) ) ;
                                      continue;
                                    end;
                                  end;
                                  t=v[46] ;
                                  p=nil;
                                  J= (nil) ;
                                  y=61;
                                  while true do
                                    if y<=106.0 then
                                      if not (y<106.0)then
                                        p= (p[J] ) ;
                                        J=v[46] ;
                                        break;
                                      else
                                        p=14.0;
                                        y= (59+ ( (v[46] [22.0] ( (v[46] [17.0] (y-y) ) -V, (5) ) ) -V<=y and y or y) ) ;
                                        continue;
                                      end;
                                    else
                                      if y>119.0 then
                                        t= (t[p] ) ;
                                        p= (v[46] ) ;
                                        y= -112197727+ (v[46] [14.0] ( (v[46] [20.0] ( (V<V and V or V) +y+V-y, (14) ) ) ,V) ) ;
                                        continue;
                                      else
                                        J= (12.0) ;
                                        y= (20+ (v[46] [11.0] ( (v[46] [19.0] ( (v[46] [16.0] (y>=V and V or y,V) ) ) ) +V<=V and V or y,V,V) ) ) ;
                                        continue;
                                      end;
                                    end;
                                  end;
                                  h=nil;
                                  F=nil;
                                  y= (122) ;
                                  while true do
                                    if y>17.0 and y<107.0 then
                                      F= (16.0) ;
                                      if v[42] ==v[25]then
                                        while -240 do
                                          return ;
                                        end;
                                        return ;
                                      end;
                                      y= -438319+ ( (v[46] [7.0] ( (v[46] [20.0] ( (v[46] [7.0] (y<y and y or V, (4) ) ) , (30) ) ) , (5) ) ) -y+V) ;
                                      continue;
                                    elseif y<60.0 then
                                      J=J[h] ;
                                      h=v[46] ;
                                      y= (274+ (y-y-V+V+V-V-V) ) ;
                                      continue;
                                    elseif y>60.0 and y<122.0 then
                                      if v[36] ==v[5]then
                                        return v[43] ;
                                      end;
                                      h=h[F] ;
                                      break;
                                    elseif y>107.0 then
                                      h=17.0;
                                      y= (14+ (v[46] [17.0] ( (v[46] [11.0] ( (v[46] [14.0] ( (v[46] [19.0] (V+V+y) ) ) ) ,y) ) ) ) ) ;
                                    end;
                                  end;
                                  F= (W[C] ) ;
                                  g= (nil) ;
                                  y= (92) ;
                                  while true do
                                    if y<117.0 and y>92.0 then
                                      J=J(h) ;
                                      p=p(J) ;
                                      y= -4294967062+ ( (v[46] [16.0] ( (v[46] [19.0] ( (v[46] [22.0] (V, (26) ) ) ) ) -V+y,y) ) -y) ;
                                      continue;
                                    elseif y<80.0 then
                                      h=h(F,g) ;
                                      y= ( -4294966970+ ( (v[46] [11.0] ( (v[46] [19.0] ( (v[46] [17.0] ( (v[46] [19.0] (y-V) ) ) ) ) ) ) ) -V) ) ;
                                    elseif y<110.0 and y>80.0 then
                                      if v[33] ~=v[49]then
                                      else
                                        return ;
                                      end;
                                      g= (W[C] ) ;
                                      y= -721420460+ ( (v[46] [7.0] ( (v[46] [20.0] ( (v[46] [22.0] (y, (30) ) ) , (v[46] [8.0] ('>\x698','\0\0\x00\0\0\0\u{00}\6') ) ) ) -V, (24) ) ) +y+y) ;
                                      continue;
                                    elseif y<92.0 and y>11.0 then
                                      p+=J;
                                      break;
                                    elseif y>110.0 then
                                      if v[43] ~=v[46]then
                                        J= (W[C] ) ;
                                        y= -4294966884+ (v[46] [19.0] ( (v[46] [12.0] ( (v[46] [19.0] ( (v[46] [16.0] (y,y) ) ) ) ) ) +V+y) ) ;
                                      end;
                                    end;
                                  end;
                                  y=83;
                                  while true do
                                    if y<56.0 then
                                      if v[2] ==v[40]then
                                        (v) [25] ,v[39] =49, (46) ;
                                        while -237 do
                                          (v) [21] =113;
                                        end;
                                      end;
                                      t=t(p,J) ;
                                      y=101+ (v[46] [16.0] ( (v[46] [16.0] ( (v[46] [12.0] (V+y+V<V and V or V) ) ) ) ) ) ;
                                    elseif y>83.0 then
                                      p= (2) ;
                                      y= ( -1572951+ (v[46] [16.0] ( (v[46] [7.0] ( (v[46] [12.0] (V) ) , (16) ) ) +y+y-V,V,y) ) ) ;
                                    elseif y>56.0 and y<125.0 then
                                      J=V;
                                      y=22+ (v[46] [22.0] ( (v[46] [14.0] ( (v[46] [11.0] ( (v[46] [11.0] (y-y-y,y,V) ) ,V,V) ) ,V) ) , (22) ) ) ;
                                      continue;
                                    elseif y<83.0 and y>22.0 then
                                      if v[45] ==v[46]then
                                      else
                                        O=O(t,p) ;
                                      end;
                                      break;
                                    end;
                                  end;
                                  t=W[C] ;
                                  y=53;
                                  while true do
                                    if y>16.0 then
                                      O-=t;
                                      t=W[C] ;
                                      y= ( -37+ (v[46] [11.0] ( (v[46] [14.0] ( (v[46] [22.0] ( (v[46] [12.0] (V) ) -V+y, (3) ) ) ,y,V) ) ,y,y) ) ) ;
                                    else
                                      if v[39] ~=v[5]then
                                      else
                                        (v) [42] ,v[49] =v[2] , (v[37] ) ;
                                      end;
                                      M=M(O,t) ;
                                      break;
                                    end;
                                  end;
                                  y= (48) ;
                                  while true do
                                    if y<79.0 then
                                      l+=M;
                                      y=292+ ( (v[46] [12.0] ( (v[46] [20.0] (V+V, (3) ) ) -V-V) ) -V) ;
                                    elseif not (y>48.0)then
                                    else
                                      b+=l;
                                      break;
                                    end;
                                  end;
                                  (W) [C] = (b) ;
                                  y=44;
                                  while true do
                                    if y==62.0 then
                                      M= (e) ;
                                      break;
                                    elseif y==27.0 then
                                      l= (q[C] ) ;
                                      y=249+ ( ( (v[46] [20.0] ( (v[46] [14.0] ( (v[46] [14.0] ( (v[46] [11.0] (V,V) ) ,V,y) ) ,y,y) ) , (y) ) ) >y and y or y) -V) ;
                                    elseif y~=44.0 then
                                    else
                                      b= (e) ;
                                      y= -187+ ( (v[46] [20.0] ( (v[46] [19.0] ( (y>y and y or y) +y) ) , (10) ) ) +V>=V and V or V) ;
                                      continue;
                                    end;
                                  end;
                                  O=j[C] ;
                                  M=M[O] ;
                                  O=U[C] ;
                                  y=60;
                                  while true do
                                    if y<107.0 then
                                      M= (M<O) ;
                                      y=107+ (v[46] [22.0] ( (v[46] [18.0] ( (v[46] [11.0] ( (v[46] [18.0] (y+y, (9) ) ) +y,V) ) , (17) ) ) , (26) ) ) ;
                                    elseif not (y>60.0)then
                                    else
                                      b[l] =M;
                                      break;
                                    end;
                                  end;
                                else
                                  if V==216 then
                                    e[c[C] ] =e[q[C] ] >=K[C] ;
                                  else
                                    X[U[C] ] = (e[j[C] ] ) ;
                                  end;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                else
                  if V<259 then
                    if v[22] ==v[25]then
                      v[2] ,v[22] = -250, -v[52] ;
                      return ;
                    end;
                    if not (V<240)then
                      if V<249 then
                        if not (V>=244)then
                          if not (V>=242)then
                            if V~=241 then
                              b=c[C] ;
                              l= (d-H-1.0) ;
                              if l<0.0 then
                                l= -1.0;
                              end;
                              M=0.0;
                              for N=b,b+l do
                                e[N] =a[r+M] ;
                                M+=1.0;
                              end;
                              _=b+l;
                            else
                              M*=y;
                              b[l] =M;
                            end;
                          else
                            if V==243 then
                              M+=y;
                            else
                              O= (q[C] ) ;
                            end;
                          end;
                        else
                          if V>=246 then
                            if not (V<247)then
                              if V==248 then
                                s= {
                                  [4] =Z, [3] =x, [5] =s, [1] =E
                                } ;
                                _= (c[C] ) ;
                                b=v[32] (function ( ... )
                                  (v[30] ) ( ) ;
                                  for N,H in ...do
                                    (v[30] ) (true,N,H) ;
                                  end;
                                end) ;
                                (b) (e[_] ,e[_+1.0] ,e[_+2.0] ) ;
                                Z= (b) ;
                                C=q[C] ;
                              else
                                if not (e[q[C] ] <K[C] )then
                                  C= (c[C] ) ;
                                end;
                              end;
                            elseif v[12] ~=v[51]then
                              b=e;
                              l= (q[C] ) ;
                              M= (e) ;
                            end;
                          else
                            if V~=245 then
                              O=q[C] ;
                            else
                              (e) [c[C] ] =e[j[C] ] <=e[q[C] ] ;
                            end;
                          end;
                        end;
                      else
                        if v[35] ==v[7]then
                          while -v[43]do
                            v[40] ,v[42] =v[46] ,v[42] ;
                            (v) [21] =v[40] ;
                          end;
                        else
                          if not (V>=254)then
                            if V>=251 then
                              if V<252 then
                                if v[46] ~=v[5]then
                                  y= (j[C] ) ;
                                  M=M[y] ;
                                end;
                                b[l] = (M) ;
                              else
                                if V~=253 then
                                  (e) [j[C] ] = (e[c[C] ] /e[q[C] ] ) ;
                                else
                                  b=I;
                                end;
                              end;
                            else
                              if V==250 then
                                e[j[C] ] = (e[c[C] ] -P[C] ) ;
                              else
                                for N=b,l,1 do
                                  if v[35] ~=v[25]then
                                  else
                                    if v[40]then
                                      return ;
                                    end;
                                  end;
                                  M=e;
                                  y= (N) ;
                                  N= (nil) ;
                                  M[y] =N;
                                end;
                              end;
                            end;
                          else
                            if v[21] ==v[25]then
                              while v[12]do
                                return ;
                              end;
                              while v[40]do
                                return 157<v[41] ;
                              end;
                            else
                              if V>=256 then
                                if V>=257 then
                                  if V==258 then
                                    (e) [q[C] ] = (e[j[C] ] %e[c[C] ] ) ;
                                  else
                                    if v[21] ==v[12]then
                                    else
                                      _= (b) ;
                                    end;
                                  end;
                                else
                                  e[c[C] ] = (v[44] (e[q[C] ] ,K[C] ) ) ;
                                end;
                              else
                                if v[41] ==v[46]then
                                  if -218~= -83 then
                                  else
                                    return v[38] ;
                                  end;
                                else
                                  if V==255 then
                                    e[q[C] ] =K[C] ..e[c[C] ] ;
                                  else
                                    if v[38] ==v[5]then
                                      return v[40] ;
                                    end;
                                    l= (c[C] ) ;
                                    M=e;
                                    y= (q[C] ) ;
                                  end;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    else
                      if not (V>=231)then
                        if not (V<226)then
                          if V<228 then
                            if V~=227 then
                              b=e;
                              l= (q[C] ) ;
                            else
                              if o==v[2]then
                              else
                                b=e;
                                l= (c[C] ) ;
                              end;
                            end;
                          else
                            if V>=229 then
                              if V~=230 then
                                M+=y;
                                (b) [l] =M;
                              else
                                if not (not (e[c[C] ] <=e[q[C] ] ) )then
                                else
                                  C=j[C] ;
                                end;
                              end;
                            else
                              for N=q[C] ,j[C] ,1 do
                                if v[12] ==v[33]then
                                  while - ( -148)do
                                    return ;
                                  end;
                                end;
                                (e) [N] = (nil) ;
                              end;
                            end;
                          end;
                        else
                          if not (V>=224)then
                            if V~=223 then
                              l= (j[C] ) ;
                              M= (e) ;
                              y= (c[C] ) ;
                            else
                              l=e;
                            end;
                          else
                            if V~=225 then
                              b= (j[C] ) ;
                              l=c[C] ;
                              M=e[b] ;
                              v[3] (e,b+1.0,b+q[C] ,l+1.0,M) ;
                            else
                              e[q[C] ] = (e[c[C] ] ..e[j[C] ] ) ;
                            end;
                          end;
                        end;
                      else
                        if V<235 then
                          if V>=233 then
                            if v[50] ~=v[5]then
                            else
                              return ;
                            end;
                            if V==234 then
                              y=c[C] ;
                              M=M[y] ;
                              y= (e) ;
                            else
                              b= (e) ;
                              l= (j[C] ) ;
                              M= (nil) ;
                            end;
                          else
                            if V==232 then
                              if v[49] ~=v[25]then
                                M=M[y] ;
                              end;
                              y= (P[C] ) ;
                              M%=y;
                            else
                              y= (K[C] ) ;
                              M*=y;
                            end;
                          end;
                        else
                          if V>=237 then
                            if not (V<238)then
                              if v[51] ~=v[5]then
                                if V~=239 then
                                  b= (e[q[C] ] ) ;
                                  l=b[9] ;
                                  M= ( #l) ;
                                  y= (M>0.0 and {
                                  } ) ;
                                  O=v[53] (b,y) ;
                                  (v[24] ) (O,X) ;
                                  (e) [j[C] ] =O;
                                  if not (y)then
                                  else
                                    if v[41] ==v[7]then
                                      return v[7] ;
                                    end;
                                    for N=1.0,M,1 do
                                      b= (l[N] ) ;
                                      O= (b[2] ) ;
                                      t=b[1] ;
                                      if O==0.0 then
                                        if v[42] ==v[12]then
                                          return 34;
                                        elseif v[38] ==v[40]then
                                          return ;
                                        else
                                          if not T then
                                            T= {
                                            } ;
                                          end;
                                        end;
                                        p=T[t] ;
                                        if not (not p)then
                                        else
                                          if v[37] ==v[33]then
                                            v[36] = (v[41] ) ;
                                            while 7^v[51]do
                                              return ;
                                            end;
                                          end;
                                          p= ( {
                                            [2] =e, [1] =t
                                          } ) ;
                                          T[t] =p;
                                        end;
                                        y[N-1.0] = (p) ;
                                      else
                                        if O~=1.0 then
                                          (y) [N-1.0] = (I[t] ) ;
                                        else
                                          if v[35] ~=v[33]then
                                          else
                                            return -164;
                                          end;
                                          y[N-1.0] =e[t] ;
                                        end;
                                      end;
                                    end;
                                  end;
                                else
                                  M= (e) ;
                                  y=c[C] ;
                                end;
                              end;
                            else
                              l=j[C] ;
                              M=U[C] ;
                            end;
                          else
                            if V==236 then
                              if v[7] ==v[35]then
                                while v[49]do
                                  (v) [2] ,v[37] =v[50] <v[46] , (v[41] ) ;
                                  return ;
                                end;
                                return 246 or v[36] ;
                              else
                                if T then
                                  for N,H,X in T do
                                    if not (N>=1.0)then
                                    else
                                      H[2] =H;
                                      (H) [3] =e[N] ;
                                      H[1] =3;
                                      (T) [N] =nil;
                                    end;
                                  end;
                                end;
                              end;
                              return v[22] (e,_,q[C] ) ;
                            else
                              b= (c[C] ) ;
                              _= (b+q[C] -1.0) ;
                              (e) [b] =e[b] (v[22] (e,_,b+1.0) ) ;
                              _= (b) ;
                            end;
                          end;
                        end;
                      end;
                    end;
                  else
                    if V<278 then
                      if v[40] ==v[51]then
                        if not (0)then
                        else
                          v[49] ,v[49] = -v[42] , ( - (226==19) ) ;
                        end;
                      elseif v[41] ==v[40]then
                        if v[12] %v[22]then
                          return v[36] ;
                        end;
                        (v) [25] ,v[42] =v[50] , (168) ;
                      else
                        if V>=268 then
                          if V<273 then
                            if not (V>=270)then
                              if V==269 then
                                e[q[C] ] = (e[c[C] ] >=e[j[C] ] ) ;
                              else
                                M= (e) ;
                                y=_;
                                M=M[y] ;
                              end;
                            else
                              if not (V>=271)then
                                e[j[C] ] = (e[c[C] ] //e[q[C] ] ) ;
                              else
                                if V~=272 then
                                  I[q[C] ] [U[C] ] = (K[C] ) ;
                                else
                                  if v[45] ~=v[46]then
                                  else
                                    (v) [7] ,v[25] =200,v[25] ;
                                  end;
                                  b=q[C] ;
                                  l= (j[C] ) ;
                                  for N=b,l do
                                    M= (e) ;
                                    y=N;
                                    N=nil;
                                    M[y] = (N) ;
                                  end;
                                end;
                              end;
                            end;
                          else
                            if v[21] ==v[12]then
                              while v[50]do
                                (v) [36] = (v[39] ) ;
                              end;
                            end;
                            if not (V<275)then
                              if V<276 then
                                b=q[C] ;
                              else
                                if V==277 then
                                  e[j[C] ] = (P[C] ~=e[c[C] ] ) ;
                                else
                                  e[c[C] ] =e[q[C] ] >K[C] ;
                                end;
                              end;
                            else
                              if V~=274 then
                                e[j[C] ] = (nil) ;
                              else
                                y= (e) ;
                              end;
                            end;
                          end;
                        else
                          if V<263 then
                            if not (V<261)then
                              if v[7] ==v[12]then
                                return ;
                              else
                                if v[25] ==v[52]then
                                  return ;
                                else
                                  if V~=262 then
                                    if not (e[c[C] ] <=P[C] )then
                                    else
                                      C= (j[C] ) ;
                                    end;
                                  else
                                    y=y[O] ;
                                  end;
                                end;
                              end;
                            else
                              if V==260 then
                                _=q[C] ;
                                e[_] ( ) ;
                                _-=1.0;
                              else
                                b=j[C] ;
                                l= (q[C] ) ;
                                M= (e[b] ) ;
                                v[3] (e,b+1.0,_,l+1.0,M) ;
                              end;
                            end;
                          else
                            if v[37] ~=v[25]then
                              if not (V>=265)then
                                if v[51] ==v[25]then
                                  if not ( -7<= -200)then
                                  else
                                    (v) [45] ,v[46] =v[36] ,v[7] ;
                                  end;
                                  (v) [35] = - (104-157) ;
                                else
                                  if V~=264 then
                                    v[46] [c[C] ] = (e[j[C] ] ) ;
                                  else
                                    (e) [q[C] ] =v[46] [c[C] ] ;
                                  end;
                                end;
                              else
                                if v[51] ~=v[7]then
                                  if not (V>=266)then
                                    if not (K[C] <=e[q[C] ] )then
                                      C= (c[C] ) ;
                                    end;
                                  else
                                    if V~=267 then
                                      e[c[C] ] =P[C] <=K[C] ;
                                    else
                                      y=j[C] ;
                                      M=M[y] ;
                                      y=P[C] ;
                                    end;
                                  end;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    else
                      if not (V<287)then
                        if not (V>=292)then
                          if not (V<289)then
                            if not (V<290)then
                              if V==291 then
                                b= (I[q[C] ] ) ;
                                (b[2] [b[1] ] ) [U[C] ] =e[j[C] ] ;
                              else
                                e[q[C] ] = (e[j[C] ] <U[C] ) ;
                              end;
                            else
                              if v[38] ==v[12]then
                                while v[42]do
                                  (v) [25] ,v[41] =v[46] , ( -189) ;
                                end;
                                if not (151)then
                                else
                                  (v) [39] = -v[41] ;
                                  return v[2] ;
                                end;
                              end;
                              if v[39] ==v[40]then
                                if v[40]then
                                  return ;
                                end;
                                return ;
                              end;
                              b=j[C] ;
                              _= (b) ;
                            end;
                          else
                            if V==288 then
                              if v[2] ~=o then
                              elseif not ( -v[37] )then
                              else
                                v[45] ,v[22] =v[2] , (v[39] ) ;
                                return ;
                              end;
                              b= (q[C] ) ;
                              (e) [b] =e[b] (v[22] (e,_,b+1.0) ) ;
                              _= (b) ;
                            else
                              b=c[C] ;
                              _= (b+j[C] -1.0) ;
                              e[b] (v[22] (e,_,b+1.0) ) ;
                              _=b-1.0;
                            end;
                          end;
                        else
                          if V<294 then
                            if V~=293 then
                              (e) [q[C] ] =e[j[C] ] ;
                            else
                              b=q[C] ;
                              (e) [b] =e[b] (e[b+1.0] ) ;
                              _= (b) ;
                            end;
                          else
                            if V<295 then
                              if not (T)then
                              else
                                for N,H,X in T do
                                  if N>=1.0 then
                                    H[2] = (H) ;
                                    (H) [3] =e[N] ;
                                    H[1] =3;
                                    (T) [N] =nil;
                                  end;
                                end;
                              end;
                              return e[q[C] ] ;
                            else
                              if v[22] ~=v[5]then
                              else
                                while v[42]do
                                  (v) [42] = - ( -141) ;
                                  v[36] ,v[41] = -v[7] , -v[42] ;
                                end;
                              end;
                              if V==296 then
                                _= (j[C] ) ;
                                e[_] =e[_] ( ) ;
                              else
                                e[q[C] ] =U[C] <=e[j[C] ] ;
                              end;
                            end;
                          end;
                        end;
                      else
                        if v[41] ==v[33]then
                          (v) [25] ,v[5] = -226*v[41] , (v[12] ) ;
                        else
                          if v[40] ==v[35]then
                            v[43] = (v[5] ^v[41] ) ;
                          else
                            if V<282 then
                              if V>=280 then
                                if V~=281 then
                                  y= (P[C] ) ;
                                  M-=y;
                                  (b) [l] =M;
                                else
                                  if v[5] ==v[42]then
                                  else
                                    e[j[C] ] = (a[r] ) ;
                                  end;
                                end;
                              else
                                if V==279 then
                                  if v[7] ~=v[45]then
                                  else
                                    return ;
                                  end;
                                  y= (e) ;
                                  O=j[C] ;
                                else
                                  b=q[C] ;
                                  _= (b) ;
                                end;
                              end;
                            else
                              if v[41] ~=v[5]then
                              else
                                return ;
                              end;
                              if v[49] ==v[2]then
                                return ;
                              elseif v[39] ==v[2]then
                                while v[43]do
                                  (v) [38] =v[5] ;
                                end;
                                if not (v[40] <=v[46] )then
                                else
                                  v[41] = (247==v[12] ) ;
                                  return ;
                                end;
                              else
                                if V>=284 then
                                  if not (V>=285)then
                                    b=e;
                                    l=c[C] ;
                                    M=K[C] ;
                                  else
                                    if V==286 then
                                      C=c[C] ;
                                    else
                                      (e) [q[C] ] = {
                                      } ;
                                    end;
                                  end;
                                else
                                  if V==283 then
                                    (e) [q[C] ] = (U[C] +e[j[C] ] ) ;
                                  else
                                    M=M( ) ;
                                    b[l] = (M) ;
                                  end;
                                end;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
              C+=1.0;
            until false;
          end;
        else
          if i~=5 then
            o= (function ( ... )
              local N,i,e,r,H,_,C=v[23] (n) ,1.0,1.0, (v[18] ( ) ) ;
              local X,l,Z;
              repeat
                local T= (W[i] ) ;
                if not (T>=6)then
                  if T<3 then
                    if T<1 then
                      if v[35] ==v[40]then
                        while v[50]do
                          return v[51] ;
                        end;
                      end;
                      if v[2] ~=v[38]then
                        N[2.0] = (I[q[i] ] ) ;
                        i+=1.0;
                        (N) [2.0] = #N[2.0] ;
                        i+=1.0;
                        N[3.0] = (r[U[i] ] ) ;
                        i+=1.0;
                        N[3.0] = (N[3.0] [K[i] ] ) ;
                        i+=1.0;
                        (N) [4.0] = (I[c[i] ] ) ;
                        i+=1.0;
                        N[4.0] = #N[4.0] ;
                        i+=1.0;
                        (N) [3.0] =N[3.0] (N[4.0] ) ;
                        e= (3.0) ;
                        i+=1.0;
                        (N) [4.0] =U[i] ;
                        i+=1.0;
                        N[5.0] =I[c[i] ] ;
                        i+=1.0;
                        N[5.0] = ( #N[5.0] ) ;
                        i+=1.0;
                      end;
                      (N) [6.0] = (U[i] ) ;
                      if v[7] ~=v[12]then
                      else
                        while -v[39]do
                          return ;
                        end;
                        while v[35] <= -191 do
                          return ;
                        end;
                      end;
                      i+=1.0;
                      H= ( {
                        [4] =l, [5] =H, [1] =C, [3] =X
                      } ) ;
                      X=N[6.0] ;
                      C=N[5.0] ;
                      l=N[4.0] -X;
                      i=c[i] ;
                    else
                      if T~=2 then
                        if v[45] ==v[2]then
                          return v[36] ;
                        end;
                        (N) [4.0] = (U[i] ) ;
                        i+=1.0;
                        (N) [5.0] = (U[i] ) ;
                        i+=1.0;
                        (N) [6.0] =U[i] ;
                        i+=1.0;
                        H= ( {
                          [4] =l, [5] =H, [1] =C, [3] =X
                        } ) ;
                        X=N[6.0] ;
                        C=N[5.0] ;
                        l= (N[4.0] -X) ;
                        i= (c[i] ) ;
                      else
                        i=q[i] ;
                      end;
                    end;
                  else
                    if not (T<4)then
                      if T~=5 then
                        l= (H[4] ) ;
                        C= (H[1] ) ;
                        X=H[3] ;
                        H=H[5] ;
                      else
                        if v[50] ==v[25]then
                        else
                          N[8.0] =r[U[i] ] ;
                          i+=1.0;
                          (N) [8.0] =N[8.0] [K[i] ] ;
                          i+=1.0;
                        end;
                        (N) [9.0] = (I[q[i] ] ) ;
                        if v[12] ~=v[43]then
                          i+=1.0;
                          Z= (N[9.0] ) ;
                          (N) [10.0] =Z;
                          N[9.0] =Z[U[i] ] ;
                          i+=1.0;
                          N[11.0] =N[7.0] ;
                          i+=1.0;
                          N[9.0] =N[9.0] (N[10.0] ,N[11.0] ) ;
                        end;
                        e= (9.0) ;
                        if v[43] ~=v[7]then
                          i+=1.0;
                        end;
                        (N) [10.0] =I[c[i] ] ;
                        if v[37] ==e then
                          while e do
                            v[21] = (56) ;
                          end;
                        end;
                        if v[52] ==v[40]then
                        else
                          i+=1.0;
                          Z=N[10.0] ;
                          (N) [11.0] = (Z) ;
                          (N) [10.0] = (Z[P[i] ] ) ;
                          i+=1.0;
                          (N) [12.0] =N[7.0] -U[i] ;
                          i+=1.0;
                          (N) [12.0] = (N[12.0] %N[2.0] ) ;
                          i+=1.0;
                          N[12.0] = (N[12.0] +K[i] ) ;
                          i+=1.0;
                          N[10.0] =N[10.0] (N[11.0] ,N[12.0] ) ;
                          e= (10.0) ;
                          i+=1.0;
                          (N) [9.0] =N[9.0] +N[10.0] ;
                          i+=1.0;
                        end;
                        N[9.0] =N[9.0] %K[i] ;
                        if v[25] ~=v[43]then
                        else
                          if v[25]then
                            v[37] = (v[43] ) ;
                          end;
                          if v[41]then
                            return ;
                          end;
                        end;
                        i+=1.0;
                        (N) [8.0] =N[8.0] (N[9.0] ) ;
                        e=8.0;
                        i+=1.0;
                        N[3.0] [N[7.0] ] = (N[8.0] ) ;
                        i+=1.0;
                        i= (q[i] ) ;
                      end;
                    else
                      if v[37] ~=_ then
                        (N) [2.0] =r[U[i] ] ;
                        i+=1.0;
                        (N) [3.0] = (N[1.0] ) ;
                        i+=1.0;
                        N[4.0] = (U[i] ) ;
                        i+=1.0;
                        (N) [2.0] =N[2.0] (N[3.0] ,N[4.0] ) ;
                      end;
                      e= (2.0) ;
                      i+=1.0;
                      if not N[2.0]then
                        i= (j[i] ) ;
                      end;
                    end;
                  end;
                else
                  if not (T<9)then
                    if not (T<10)then
                      if T~=11 then
                        if v[37] ~=v[33]then
                          N[8.0] = (r[U[i] ] ) ;
                          i+=1.0;
                          N[8.0] =N[8.0] [K[i] ] ;
                        end;
                        i+=1.0;
                        (N) [9.0] = (N[3.0] ) ;
                        if _~=v[40]then
                        elseif v[39]then
                          return ;
                        end;
                        i+=1.0;
                        if not (_)then
                        else
                          for H,g in _ do
                            if v[50] ==v[7]then
                              while v[7] <v[42]do
                                v[49] =45;
                              end;
                            else
                              if not (H>=1.0)then
                              else
                                (g) [2] = (g) ;
                                g[3] =N[H] ;
                                (g) [1] = (3) ;
                                _[H] = (nil) ;
                              end;
                            end;
                          end;
                        end;
                        return N[8.0] (N[9.0] ) ;
                      else
                        if v[52] ~=v[5]then
                          (N) [2.0] =I[q[i] ] ;
                        end;
                        i+=1.0;
                        if v[38] ==v[33]then
                        else
                          (N) [3.0] =U[i] ;
                          i+=1.0;
                          (N[2.0] ) (N[3.0] ) ;
                          e=1.0;
                          i+=1.0;
                          N[2.0] =r[U[i] ] ;
                          i+=1.0;
                          N[2.0] = (N[2.0] [K[i] ] ) ;
                          i+=1.0;
                          (N) [3.0] =U[i] ;
                          i+=1.0;
                          N[2.0] (N[3.0] ) ;
                        end;
                        e=1.0;
                        i+=1.0;
                        i=q[i] ;
                      end;
                    else
                      if N[q[i] ] ~=K[i]then
                        i=c[i] ;
                      end;
                    end;
                  else
                    if v[41] ==v[5]then
                      v[46] =v[49] ;
                    else
                      if T<7 then
                        if v[21] ==_ then
                          return ;
                        end;
                        if v[38] ==v[33]then
                        else
                          N[2.0] =r[U[i] ] ;
                          i+=1.0;
                        end;
                        N[3.0] = (N[1.0] ) ;
                        i+=1.0;
                        N[2.0] =N[2.0] (N[3.0] ) ;
                        e=2.0;
                        i+=1.0;
                        if N[2.0] ==K[i]then
                          i= (c[i] ) ;
                        end;
                      else
                        if T==8 then
                          if v[37] ==_ then
                          else
                            Z= ( {
                              ...
                            } ) ;
                          end;
                          for e=1.0,c[i] ,1 do
                            (N) [e] =Z[e] ;
                          end;
                        else
                          if v[7] ~=v[49]then
                            Z=false;
                          end;
                          l+=X;
                          if X<=0.0 then
                            if v[37] ==v[40]then
                            else
                              Z=l>=C;
                            end;
                          else
                            Z=l<=C;
                          end;
                          if v[21] ==v[40]then
                            (v) [40] = (v[42] ) ;
                            while v[38] ==v[43]do
                              return 143^155^56;
                            end;
                          elseif v[2] ==v[42]then
                            return ;
                          else
                            if not (Z)then
                            else
                              (N) [q[i] +3.0] =l;
                              i=c[i] ;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
                i+=1.0;
              until false;
            end) ;
          else
            o=function ( ... )
              local N,i,e,r,H,_=v[23] (n) ,1.0,1.0, (v[18] ( ) ) ;
              repeat
                local n= (W[e] ) ;
                if not (n>=5)then
                  if n>=2 then
                    if not (n<3)then
                      if n~=4 then
                        H= (I[j[e] ] ) ;
                        (N) [1.0] = (H[2] [H[1] ] ) ;
                        e+=1.0;
                        N[1.0] = (N[1.0] +K[e] ) ;
                        e+=1.0;
                        H= (I[c[e] ] ) ;
                        (H[2] ) [H[1] ] =N[1.0] ;
                        e+=1.0;
                        H=I[c[e] ] ;
                        (N) [1.0] =H[2] [H[1] ] ;
                        e+=1.0;
                        (N) [1.0] =N[1.0] %U[e] ;
                        e+=1.0;
                        if N[1.0] ==U[e]then
                        else
                          e= (q[e] ) ;
                        end;
                      elseif v[21] ==_ then
                      else
                        if not (_)then
                        else
                          if v[36] ==v[33]then
                            v[38] =v[37] -191;
                            (v) [22] ,v[45] =v[25] ,180<100 and v[52] ;
                          end;
                          for W,K in _ do
                            if W>=1.0 then
                              K[2] =K;
                              (K) [3] =N[W] ;
                              K[1] = (3) ;
                              _[W] =nil;
                            end;
                          end;
                        end;
                        return ;
                      end;
                    else
                      if N[q[e] ] ~=U[e]then
                      else
                        e= (j[e] ) ;
                      end;
                    end;
                  else
                    if n==1 then
                      if v[49] ~=v[25]then
                        N[1.0] = (I[c[e] ] ) ;
                        e+=1.0;
                        (N) [2.0] =P[e] ;
                        e+=1.0;
                        N[1.0] (N[2.0] ) ;
                        i= (0.0) ;
                        e+=1.0;
                        N[1.0] = (r[U[e] ] ) ;
                        e+=1.0;
                        N[1.0] = (N[1.0] [P[e] ] ) ;
                        e+=1.0;
                        (N) [2.0] = (U[e] ) ;
                        e+=1.0;
                        N[1.0] (N[2.0] ) ;
                      end;
                      i= (0.0) ;
                      if e~=v[22]then
                      else
                        if not (v[50] )then
                        else
                          (v) [25] =1< -200;
                          return v[39] ;
                        end;
                        if v[46]then
                          return -108;
                        end;
                      end;
                      e+=1.0;
                      e= (j[e] ) ;
                    else
                      H=I[j[e] ] ;
                      N[q[e] ] = (H[2] [H[1] ] ) ;
                    end;
                  end;
                else
                  if n<7 then
                    if n~=6 then
                      if v[50] ==v[33]then
                      else
                        N[3.0] = (I[c[e] ] ) ;
                        e+=1.0;
                        N[4.0] = (I[j[e] ] [U[e] ] ) ;
                        e+=1.0;
                        (N) [5.0] = (P[e] ) ;
                        e+=1.0;
                        (N) [6.0] =U[e] ;
                        e+=1.0;
                        i= (6.0) ;
                      end;
                      (N) [3.0] =N[3.0] (v[22] (N,i,4.0) ) ;
                      i= (3.0) ;
                      e+=1.0;
                      if not (N[3.0] )then
                      else
                        e= (c[e] ) ;
                      end;
                    else
                      e=j[e] ;
                    end;
                  else
                    if not (n>=8)then
                      N[q[e] ] = (I[j[e] ] [U[e] ] ) ;
                    else
                      if n==9 then
                        if not (N[j[e] ] )then
                        else
                          e= (c[e] ) ;
                        end;
                      else
                        if v[33] ~=v[40]then
                        else
                          return v[50] ;
                        end;
                        if not (N[j[e] ] <P[e] )then
                        else
                          e= (c[e] ) ;
                        end;
                      end;
                    end;
                  end;
                end;
                e+=1.0;
              until false;
            end;
          end;
        end;
      end;
      return o;
    end) ;
    if not (not G[15579] )then
      S=G[15579] ;
    else
      S=D:Yj(G,S) ;
    end;
    return S;
  end,Dj=function (D,S,v,G,N,I,n,i)
    if G==1 then
      D:cj(i,v,N,I,n) ;
    elseif G==4 then
      (S) [I] =i;
    elseif G==6 then
      (S) [I] = (I+i) ;
    elseif G==5 then
      S[I] = (I-i) ;
    else
      if G==3 then
        local D;
        for S=56,245,114 do
          if S>=170.0 then
            n[34] [D+3.0] =i;
            break;
          else
            D= ( #n[34] ) ;
            n[34] [D+1.0] = (N) ;
            n[34] [D+2.0] = (I) ;
            continue;
          end;
        end;
      end;
    end;
  end,Hq=function (D,D,S)
    S= (D[28768] ) ;
    return S;
  end,fq=bit32.bnot,G=select,dj=function (D,D,S,v,G)
    if v<123.0 then
      S= #D[34] ;
      v= (123) ;
    else
      if v>12.0 then
        (D[34] ) [S+1.0] =G;
        return v,21864,S;
      end;
    end;
    return v,nil,S;
  end,cq=bit32.countrz,R=function (D,D,S)
    D= (S[6055] ) ;
    return D;
  end,hq=function (D,S,v,G,N,I,n,i)
    i=81;
    while true do
      if not (i>=124.0)then
        i=D:xj(i,v,I) ;
      else
        D:Oj(v) ;
        break;
      end;
    end;
    S=nil;
    G= (nil) ;
    i= (119) ;
    while true do
      if not (i<=106.0)then
        S,i=D:jq(I,v,S,i) ;
        continue;
      else
        G= (function ( ... )
          return ( ... ) ( ) ;
        end) ;
        break;
      end;
    end;
    n=S( ) ;
    v[46] [5.0] =D.V;
    N=nil;
    i=90;
    repeat
      if i==28.0 then
        v[46] [14.0] = (D.q.bor) ;
        if not (not I[6548] )then
          i=D:uq(i,I) ;
        else
          i= ( -181+ (D.Vq( (D.cq( (D.Dq( (D.zq( (D.Iq(D.n[3] >=I[10774]and I[11202]or D.n[6] ) ) ,I[13737] ) ) ,D.n[6] ,I[12506] ) ) ) ) , (I[13737] ) ) ) ) ;
          (I) [6548] = (i) ;
        end;
        continue;
      else
        if i==113.0 then
          (v[46] ) [22.0] =D.Eq;
          (v[46] ) [13.0] =D.I;
          if not (not I[22674] )then
            i=D:rq(i,I) ;
          else
            I[7881] = (67+ ( (D.qq( (D.cq( (D.cq(I[19057] -i) ) ) ) +I[13343] , (I[20702] ) ) ) ~=I[28768]and I[13486]or I[12506] ) ) ;
            i= -70628+ (D.bq( (D.cq( (D.dq( (D.Iq(D.n[5] ,I[27695] ,I[27695] ) ) ) ) -I[30777] ) ) +I[2501] , (I[20702] ) ) ) ;
            (I) [22674] =i;
          end;
          continue;
        else
          if i==90.0 then
            N=function ( ... )
              return (D:Pq( ... ) ) ;
            end;
            if v[53] ~=v[46]then
            else
              if -155 or 195^155 then
                return n,N,G,S, -1,i;
              end;
            end;
            if not I[28768]then
              I[26687] = ( -4294967178+ (D.fq( (D.Iq( (I[10774] >=I[21002]and I[21002]or I[6843] ) -I[20931] ) ) -I[30736] <I[11202]and D.n[1]or I[6843] ) ) ) ;
              i= (6+ ( (D.Iq( ( (D.bq( (D.qq(I[19582] , (I[21440] ) ) ) , (I[6055] ) ) ) >=I[29749]and I[13737]or I[22968] ) -I[27695] ,I[19526] ) ) ==I[13343]and I[6625]or I[6625] ) ) ;
              (I) [28768] = (i) ;
            else
              i=D:Hq(I,i) ;
            end;
          else
            if i==75.0 then
              (v[46] ) [7.0] =D.d;
              break;
            end;
          end;
        end;
      end;
    until false;
    i=83;
    return n,N,G,S,nil,i;
  end,Oh=function (D,S,v)
    v= -1642001745+ (D.bq( ( (D.zq( (D.fq(S[19526] +S[23165] ) ) ) ) ~=D.n[6]and D.n[7]or S[22968] ) +S[17476] , (S[21440] ) ) ) ;
    S[24321] =v;
    return v;
  end,Ph=function (D,S,v)
    S[19057] = (1368392867+ ( (D.Vq( (D.fq(v) ) -D.n[4] -D.n[3] +S[13343] , (S[20702] ) ) ) -D.n[5] ) ) ;
    v= -4122370382+ ( (D.Vq( (D.Dq( (D.cq(S[8599] ) ) ,v) ) -S[6055] , (S[27084] ) ) ) -S[677] +D.n[7] ) ;
    (S) [12506] = (v) ;
    return v;
  end,sj=function (D)
    return ;
  end,s=function (D,S,v,G,N)
    G[6] = (unpack) ;
    (G) [7] = {
    } ;
    (G) [8] =nil;
    S= (nil) ;
    G[9] =nil;
    N= (42) ;
    while true do
      if N~=42.0 then
        (G) [9] = (S.create) ;
        break;
      else
        S=D.h;
        if not v[27084]then
          N=D:X(N,v) ;
        else
          N= (v[27084] ) ;
        end;
      end;
    end;
    (G) [10] =0.0;
    (G) [11] =nil;
    (G) [12] = (nil) ;
    return S,N;
  end,ih=function (D,D,S,v,G,N)
    N=v[35] ( ) ;
    S=30;
    G+= ( (N>127.0 and N-128.0 or N) *D) ;
    return N,S,G;
  end,Rj=function (D,D,S)
    local v=40;
    while true do
      if v==40.0 then
        v=103;
        S[46] [1] =S[48] ;
        continue;
      else
        if v==103.0 then
          S[46] [2] =D;
          break;
        end;
      end;
    end;
  end,Nh=function (D,D)
    local S=D[42] ( ) ;
    local v=D[9] (S) ;
    D[20] (v,0.0,R,D[10] ,S) ;
    (D) [10] = (D[10] +S) ;
    return v;
  end,U=function (D,S,v,G)
    local N;
    S= ( {
    } ) ;
    (G) [1] =nil;
    G[2] =nil;
    v= (88) ;
    repeat
      N,v=D:a(v,S,G) ;
      if N==43194 then
        break;
      end;
    until false;
    G[3] =D.r;
    return v,S;
  end,gq=function (D,S,v,G)
    (S[46] ) [12.0] =D.q.countlz;
    S[46] [15.0] =D.z;
    if not (not G[14307] )then
      v=G[14307] ;
    else
      v= -4238344170+ (D.qq( (D.dq( ( (G[723] <D.n[4]and G[27695]or G[6625] ) ~=G[22674]and G[15579]or G[19057] ) >G[28768]and G[13737]or D.n[4] ) ) -G[30736] , (G[6843] ) ) ) ;
      G[14307] =v;
    end;
    return v;
  end,Kj=function (D,D,S,v,G)
    D=S[43] ( ) ;
    G=v%8;
    return D,G;
  end,Lh=function (D,S,v)
    S[30736] = -31+ ( (D.bq( (D.Dq(S[13486] +S[19057] >S[21002]and S[21440]or S[11112] ) ) +v, (S[27084] ) ) ) ==S[27083]and D.n[2]or S[19526] ) ;
    v= ( -2620+ (D.bq( (D.qq( (D.qq( (D.dq( (D.Eq(D.n[5] , (S[20702] ) ) ) ) ) ~=D.n[5]and S[21002]or S[756] , (S[27084] ) ) ) , (S[21440] ) ) ) , (S[6843] ) ) ) ) ;
    S[29749] = (v) ;
    return v;
  end,O=function (D,S,v)
    S= ( -2924701212+ ( ( (D.Dq( (D.Dq(S,D.n[9] ,D.n[4] ) ) ) ) -D.n[2] +v[8599] <=D.n[8]and D.n[3]or S) >=D.n[8]and D.n[3]or v[8599] ) ) ;
    (v) [6625] = (S) ;
    return S;
  end,yj=function (D,D,S)
    S=D[41] ( ) ;
    return S;
  end,cj=function (D,S,v,G,N,I)
    if I[5] ==I[39]then
    else
      if not (I[8] )then
        D:tj(G,N,S,I) ;
      else
        D:ej(S,I,N,v) ;
      end;
    end;
  end,Dq=bit32.bor,Ij=function (D,S,v,G,N,I)
    local n;
    if not (S[8] )then
      (I) [v] = (S[48] [G] ) ;
    else
      local I,i=S[48] [G] ;
      for S=126,331,118 do
        n,i=D:Vj(S,i,v,N,I) ;
        if n~=63903 then
        else
          break;
        end;
      end;
    end;
  end,Eh=function (D,D)
    return D;
  end,u=bit32.lshift,T=math.pi,Bh=function (D,S)
    local v,G,N,I,n=13;
    repeat
      if v>8.0 and v<71.0 then
        v=8;
        I=S[42] ( ) ;
      elseif v>13.0 then
        G,N=D:yh(S,I,n) ;
        if G==5757 then
          break;
        else
          if G== -2 then
            return -2,N;
          end;
        end;
      else
        if v<13.0 then
          n=S[31] (R,S[10] ,I) ;
          v= (71) ;
        end;
      end;
    until false;
    return nil;
  end,jh=function (D,S,v,G)
    (G) [18] =D.o;
    if not v[29426]then
      (v) [13737] = (2919615783+ ( ( (D.fq( (D.fq( (D.zq(S) ) ) ) <=v[13343]and v[8599]or v[20702] ) ) <=v[20760]and D.n[9]or v[6625] ) -D.n[8] ) ) ;
      S= ( -4022381865+ ( (D.bq( (D.Eq( (D.bq(D.n[6] , (v[6843] ) ) ) , (v[21440] ) ) ) -v[21440] >=D.n[4]and D.n[6]or D.n[4] , (v[27084] ) ) ) -v[6843] ) ) ;
      v[29426] = (S) ;
    else
      S= (v[29426] ) ;
    end;
    return S;
  end,qq=bit32.lshift,xh=function (D,S,v,G)
    if G==30.0 then
      G=D:Yh(G,S,v) ;
      return 54635,G;
    else
      S[46] = {
      } ;
      return 27598,G;
    end;
    return nil,G;
  end,vh=function (D,S,v,G)
    if v[21] ==v[5]then
      v[21] ,v[25] =v[2] ^v[5] , -v[12] ;
      v[12] ,v[25] =130 and v[21] ,v[22] ;
    end;
    if not G[16668]then
      S= -1+ ( ( (D.Iq( (D.Dq(D.n[2] <=D.n[6]and G[19526]or G[19057] ,D.n[1] ,G[6843] ) ) ,G[12506] ,G[6843] ) ) +G[20931] <=D.n[2]and G[20760]or D.n[1] ) <=D.n[8]and G[677]or G[756] ) ;
      G[16668] =S;
    else
      S=D:gh(G,S) ;
    end;
    return S;
  end,uq=function (D,D,S)
    D= (S[6548] ) ;
    return D;
  end,Lq=function (D,D,S)
    D=S[23560] ;
    return D;
  end,w=table.create,jj=function (D,S)
    while S[53]do
      D:nj(S) ;
    end;
  end,Uj=function (D,S,v,G,N)
    N= (49) ;
    for I=1.0,S do
      local S=v[42] ( ) ;
      if not (v[28] [S] )then
        local n=S/4.0;
        local i= ( {
          [2] =S%4.0, [1] =n-n%1.0
        } ) ;
        for n=42,91,49 do
          if n>42.0 then
            D:aj(I,G,i) ;
          else
            if n<91.0 then
              (v[28] ) [S] =i;
            end;
          end;
        end;
      else
        G[I] =v[28] [S] ;
      end;
    end;
    return N;
  end,ej=function (D,S,v,G,N)
    local I,n,i;
    for P=67,252,62 do
      n,I,i=D:Gj(n,i,S,P,v) ;
      if I~=63610 then
      else
        break;
      end;
    end;
    (n) [i+1.0] =N;
    I=17;
    while true do
      if I<60.0 then
        I=D:lj(i,G,I,n) ;
      else
        if not (I>17.0)then
        else
          (n) [i+3.0] = (10.0) ;
          break;
        end;
      end;
    end;
  end,Eq=bit32.rshift,z=string.len,lq=function (D,S,v)
    v= -4289331128+ (D.Vq( (D.cq( (D.qq(S[20702] +S[13343] +S[23165] , (S[20702] ) ) ) ) ) -S[26687] , (S[27695] ) ) ) ;
    S[22417] =v;
    return v;
  end,D=nil,C=function (D)
    local S,v,G,N= {
    } ;
    N,G=D:U(G,N,S) ;
    local I;
    N,I=D:x(G,N,I,S) ;
    local n;
    n,N=D:s(n,G,S,N) ;
    N=D:B(n,S,N,G) ;
    N=D:N(S,N,n,G) ;
    D:m(S) ;
    N=D:rh(S,N,n,G) ;
    N=D:hh(G,S,N) ;
    N=D:Gh(S,n,G,N,I) ;
    N=D:fh(S,N,G) ;
    D:bh(S) ;
    N=D:Vh(S,N) ;
    N=D:_h(S,N,G) ;
    D:mh(S) ;
    local I,n,i,P;
    i,P,n,I,v,N=D:hq(I,S,n,P,G,i,N) ;
    if v~= -1 then
    else
      return ;
    end;
    N=D:Gq(G,S,N) ;
    i,v,N=D:tq(S,N,I,G,i,P,n) ;
    if v then
      return D.W(v) ;
    end;
  end,y=function (D,D,S)
    D= (S[6843] ) ;
    return D;
  end,th=function (D,S,v,G)
    (v) [36] =function ( )
      local N,I;
      N,I=D:eh(v) ;
      if N~= -2 then
      else
        return I;
      end;
    end;
    if not G[723]then
      S= (2011191027+ ( (G[17476] -D.n[2] +G[27695] ~=G[8599]and G[6625]or D.n[2] ) -G[21440] -G[12506] -D.n[4] ) ) ;
      G[723] =S;
    else
      S=G[723] ;
    end;
    return S;
  end,wq=function (D,S,v,G)
    v[46] [11.0] =D.f;
    if not (not G[23560] )then
      S=D:Lq(S,G) ;
    else
      S=D:oq(S,G) ;
    end;
    return S;
  end,Zj=function (D,S,v,G,N,I,n,i,P)
    local U;
    if G==1 then
      for c=45,145,50 do
        if c>45.0 then
          if not (S[8] )then
            if i==S[39]then
            else
              (v) [I] =S[48] [n] ;
            end;
          else
            U=D:Ej(I,n,S,P) ;
            if U~= -1 then
            else
              return -1;
            end;
          end;
          break;
        else
          if not (c<95.0)then
          else
            if S[7] ==S[41]then
              if S[7]then
                return -1;
              end;
            end;
            continue;
          end;
        end;
      end;
    elseif G==4 then
      if S[2] ==S[37]then
        while -S[50]do
          D:Tj( ) ;
          return -1;
        end;
        return -1;
      end;
      (N) [I] = (n) ;
    else
      if G==6 then
        for i=68,90,22 do
          if i>68.0 then
            N[I] =I+n;
          else
            if S[21] ==S[25]then
              while S[12]do
                S[5] = (S[33] ) ;
              end;
              S[33] =168;
            end;
            continue;
          end;
        end;
      else
        if G==5 then
          N[I] = (I-n) ;
        else
          if G==3 then
            D:Sj(I,S,n,v) ;
          end;
        end;
      end;
    end;
    return 64214;
  end,_j=function (D,D,S)
    (D) [48] =D[23] (S) ;
  end,Q=function (D,S,v,G)
    v[22] =function (N,I,n)
      n= (n or 1.0) ;
      I=I or #N;
      if not ( (I-n+1.0) >7997.0)then
        return v[6] (N,n,I) ;
      else
        return v[21] (N,I,n) ;
      end;
    end;
    if not (not G[6055] )then
      S=D:R(S,G) ;
    else
      S= ( -4294858701+ ( (D.qq( (D.cq(G[13737] +D.n[6] ) ) -G[27084] -G[756] , (G[20702] ) ) ) -G[13737] ) ) ;
      G[6055] = (S) ;
    end;
    return S;
  end,A=function (D,S,v)
    v= ( -2673358124+ ( ( (D.dq( (D.Eq(S[6843] +S[20760] , (S[6843] ) ) ) ) ) >=D.n[4]and S[756]or S[20931] ) +S[6625] +D.n[9] ) ) ;
    (S) [11112] = (v) ;
    return v;
  end,nh=function (D,D,S)
    D= (S[756] ) ;
    return D;
  end,gj=function (D,D,S,v)
    D=v[43] ( ) ;
    S=v[43] ( ) ;
    return D,S;
  end,dq=bit32.countlz,uh=function (D,S,v,G,N)
    if v==44.0 then
      v=D:Q(v,G,S) ;
    elseif v==65.0 then
      (G) [21] = (function (I,n,i)
        if i>n then
          return ;
        end;
        local P= (n-i+1.0) ;
        if P>=8.0 then
          return I[i] ,I[i+1.0] ,I[i+2.0] ,I[i+3.0] ,I[i+4.0] ,I[i+5.0] ,I[i+6.0] ,I[i+7.0] ,G[21] (I,n,i+8.0) ;
        elseif P>=7.0 then
          if G[2] ~=G[5]then
            return I[i] ,I[i+1.0] ,I[i+2.0] ,I[i+3.0] ,I[i+4.0] ,I[i+5.0] ,I[i+6.0] ,G[21] (I,n,i+7.0) ;
          end;
        elseif P>=6.0 then
          return I[i] ,I[i+1.0] ,I[i+2.0] ,I[i+3.0] ,I[i+4.0] ,I[i+5.0] ,G[21] (I,n,i+6.0) ;
        elseif P>=5.0 then
          return I[i] ,I[i+1.0] ,I[i+2.0] ,I[i+3.0] ,I[i+4.0] ,G[21] (I,n,i+5.0) ;
        elseif P>=4.0 then
          return I[i] ,I[i+1.0] ,I[i+2.0] ,I[i+3.0] ,G[21] (I,n,i+4.0) ;
        elseif P>=3.0 then
          return I[i] ,I[i+1.0] ,I[i+2.0] ,G[21] (I,n,i+3.0) ;
        else
          if P>=2.0 then
            return I[i] ,I[i+1.0] ,G[21] (I,n,i+2.0) ;
          else
            return I[i] ,G[21] (I,n,i+1.0) ;
          end;
        end;
      end) ;
      if not (not S[11112] )then
        v=D:Ch(v,S) ;
      else
        v=D:A(S,v) ;
      end;
    elseif v==27.0 then
      (G) [23] =D.w;
      return 17143,v;
    elseif v==106.0 then
      (G) [20] = (N[D.L] ) ;
      if not (not S[14061] )then
        v= (S[14061] ) ;
      else
        v= ( -1720167954+ (D.bq( (D.Iq( (D.fq( (D.zq(D.n[8] ) ) ) ) ~=S[29426]and S[29426]or D.n[8] ) ) <D.n[3]and D.n[3]or S[6625] , (S[21440] ) ) ) ) ;
        (S) [14061] = (v) ;
      end;
    else
      if v==119.0 then
        G[19] = (N.readf64) ;
        if not S[756]then
          v=D:Mh(S,v) ;
          S[756] = (v) ;
        else
          v=D:nh(v,S) ;
        end;
        return 50154,v;
      else
        if v~=120.0 then
        else
          v=D:jh(v,S,G) ;
        end;
      end;
    end;
    return nil,v;
  end,_h=function (D,S,v,G)
    local N;
    repeat
      if not (v<=50.0)then
        if v>52.0 then
          if not (v>95.0)then
            S[39] =function ( )
              local I,n= (93) ;
              repeat
                if I<=23.0 then
                  return n;
                else
                  if I~=93.0 then
                    I= (23) ;
                    (S) [10] = (S[10] +4.0) ;
                  else
                    n=S[15] (R,S[10] ) ;
                    I= (24) ;
                    continue;
                  end;
                end;
              until false;
            end;
            if not (not G[23165] )then
              v= (G[23165] ) ;
            else
              (G) [22968] = -4294859642+ ( (D.bq( (D.qq( (D.fq(v) ) , (G[27084] ) ) ) +G[19057] +G[11112] , (G[20702] ) ) ) -G[27695] ) ;
              v= (50+ (D.zq(D.n[8] -G[27084] +G[27695] +G[11202] +G[30777] +D.n[2] ,G[13343] ,G[12506] ) ) ) ;
              G[23165] =v;
            end;
            continue;
          else
            S[42] = (function ( )
              local I,n,i,P;
              for U=107,225,5 do
                i,I,P,n=D:Zh(P,i,U,S) ;
                if I==24419 then
                  continue;
                else
                  if I~= -2 then
                  else
                    return n;
                  end;
                end;
              end;
            end) ;
            if not G[938]then
              v=D:Wh(G,v) ;
            else
              v= (G[938] ) ;
            end;
          end;
        else
          (S) [43] = (function ( )
            local I,n,i;
            I,i,n=D:ah(i,S) ;
            if I~= -2 then
            else
              return n;
            end;
            return (D:Uh(i) ) ;
          end) ;
          break;
        end;
      else
        if v~=0.0 then
          S[40] =9007199254740992;
          (S) [41] =function ( )
            local I,n=S[38] ( ) ,S[38] ( ) ;
            for i=50,270,87 do
              if not (i>50.0)then
                if n==0.0 then
                  return (D:Eh(I) ) ;
                elseif not (n>=S[12] )then
                else
                  n-=S[25] ;
                end;
                continue;
              else
                if not (i>=224.0)then
                  continue;
                else
                  return n*S[25] +I;
                end;
              end;
            end;
          end;
          if not (not G[20919] )then
            v=D:Th(G,v) ;
          else
            v=58+ ( (D.Iq( (D.cq( ( (D.Iq(G[13343] ,G[677] ,D.n[9] ) ) >=D.n[3]and D.n[5]or G[30736] ) +D.n[9] ) ) ,G[10774] ) ) -G[11202] ) ;
            (G) [20919] =v;
          end;
        else
          S[38] =function ( )
            local I,n;
            I,n=D:dh(S) ;
            if I~= -2 then
            else
              return n;
            end;
          end;
          if not G[10774]then
            v=D:zh(G,v) ;
          else
            v= (G[10774] ) ;
          end;
        end;
      end;
    until false;
    (S) [44] =nil;
    (S) [45] = (nil) ;
    S[46] = (nil) ;
    v= (30) ;
    while true do
      N,v=D:xh(S,G,v) ;
      if N==27598 then
        break;
      else
        if N==54635 then
          continue;
        end;
      end;
    end;
    S[47] = (nil) ;
    (S) [48] =nil;
    v= (68) ;
    while true do
      if v==83.0 then
        S[48] =D.D;
        break;
      else
        (S) [47] =D.f;
        if not G[11372]then
          v=D:Xh(v,G) ;
        else
          v=D:sh(G,v) ;
        end;
      end;
    end;
    return v;
  end,Gh=function (D,S,v,G,N,I)
    local n;
    S[28] =nil;
    S[29] = (nil) ;
    N=70;
    repeat
      n,N=D:oh(N,I,S,G) ;
      if n==32989 then
        break;
      else
        if n~=12790 then
        else
          continue;
        end;
      end;
    until false;
    (S) [30] =nil;
    S[31] =nil;
    (S) [32] = (nil) ;
    S[33] =nil;
    N=98;
    while true do
      if N==89.0 then
        (S) [31] =v.readstring;
        S[32] =D.c;
        if not G[29749]then
          N=D:Lh(G,N) ;
        else
          N=D:wh(G,N) ;
        end;
      else
        if N==98.0 then
          S[30] =D.t;
          if not (not G[27083] )then
            N=G[27083] ;
          else
            (G) [13486] =50+ (D.zq( ( (D.qq( (D.zq(G[11112] +G[20702] ,G[13343] ,G[29426] ) ) , (G[13737] ) ) ) <G[13737]and G[16668]or G[16668] ) -D.n[5] ,G[13737] ) ) ;
            N= (89+ (D.Eq( (D.Eq( (D.qq(D.n[4] >=G[12506]and G[12506]or D.n[9] , (G[21440] ) ) ) +G[6625] ~=G[20702]and G[16668]or D.n[5] , (G[13737] ) ) ) , (G[13737] ) ) ) ) ;
            (G) [27083] =N;
          end;
        else
          if N~=100.0 then
          else
            D:ph(S) ;
            break;
          end;
        end;
      end;
    end;
    S[34] =nil;
    return N;
  end,ij=function (D,D,S,v,G)
    (S[34] ) [D+2.0] = (G) ;
    v= (37) ;
    return v;
  end,lj=function (D,D,S,v,G)
    G[D+2.0] = (S) ;
    v=60;
    return v;
  end,Ej=function (D,S,v,G,N)
    local I,n,i= (119) ;
    repeat
      if not (I<=65.0)then
        if I~=106.0 then
          n= (G[48] [v] ) ;
          I=106;
        else
          I,i=D:zj(i,I,n) ;
        end;
      else
        if v~=G[7]then
        else
          return -1;
        end;
        break;
      end;
    until false;
    (n) [i+1.0] =N;
    for D=37,163,126 do
      if D==37 then
        n[i+2.0] =S;
      else
        if D==163 then
          n[i+3.0] =4.0;
        end;
      end;
    end;
    return nil;
  end,P=string.char,Qh=function (D,S,v,G)
    v= ( {
      D.D,nil,nil,nil,D.D,nil,nil,nil,D.D,D.D,nil
    } ) ;
    v[8] =S[42] ( ) ;
    G=69;
    return G,v;
  end,bj=function (D,D,S)
    D[S+3.0] =5.0;
  end,gh=function (D,D,S)
    S= (D[16668] ) ;
    return S;
  end,zq=bit32.band,ch=function (D,D,S,v)
    S=D[13] (R,D[10] ) ;
    v= (38) ;
    return v,S;
  end,fh=function (D,S,v,G)
    (S) [35] = (nil) ;
    (S) [36] =nil;
    (S) [37] =nil;
    v= (53) ;
    repeat
      if v<53.0 and v>16.0 then
        v=D:th(v,S,G) ;
      elseif v>53.0 then
        (S) [37] =function ( )
          local N,I;
          N,I=D:Dh(S) ;
          if N== -2 then
            return I;
          end;
        end;
        break;
      elseif v<47.0 then
        (S) [35] =function ( )
          local N,I= (47) ;
          while true do
            if N==66.0 then
              (S) [10] =S[10] +1.0;
              break;
            else
              if N~=47.0 then
              else
                I=S[11] (R,S[10] ) ;
                N=66;
              end;
            end;
          end;
          return I;
        end;
        if not (not G[11202] )then
          v= (G[11202] ) ;
        else
          v=D:qh(G,v) ;
        end;
      else
        if not (v>47.0 and v<66.0)then
        else
          S[34] =D.D;
          if not (not G[27695] )then
            v= (G[27695] ) ;
          else
            v= -3774847851+ ( (D.bq( (D.bq(G[29426] -G[13737] , (G[6843] ) ) ) +D.n[4] +D.n[2] , (G[27084] ) ) ) +G[16668] ) ;
            (G) [27695] = (v) ;
          end;
        end;
      end;
    until false;
    return v;
  end,pq=function (D,S,v)
    v= -37+ (D.Iq( (D.qq( (D.fq(D.n[7] ) ) , (S[23560] ) ) ) -S[12506] +S[19526] >=D.n[2]and S[756]or S[11372] ) ) ;
    (S) [19066] = (v) ;
    return v;
  end,f=bit32.band,H=bit32.bor,Fj=function (D,S,v,G,N)
    if not (S>191.0)then
      if S<=141.0 then
        G=v[38] ( ) ;
      else
        G=D.b;
      end;
    else
      if S>224.0 then
        G=v[49] ( ) ;
      else
        G= (true) ;
      end;
    end;
    N= (41) ;
    return N,G;
  end,q=bit32,_=function (D,D,S)
    D[12] =2.147483648E9;
    D[13] = (S.readi16) ;
  end,Hj=function (D,D,S,v,G,N,I)
    if S==312 then
      (G) [3.0] =D;
      return 25987;
    elseif S==96 then
      G[1.0] =v;
      return 25987;
    elseif S==204 then
      (G) [6.0] =N;
      return 25987;
    else
      if S==420 then
        G[10.0] =I;
      end;
    end;
    return nil;
  end,rj=function (D,D,S,v)
    D=S[23] (v) ;
    return D;
  end,Hh=function (D,S,v,G)
    v[26] =D.G;
    if not S[12506]then
      G=D:Ph(S,G) ;
    else
      G=S[12506] ;
    end;
    return G;
  end,Jh=function (D,D,S,v)
    D=75;
    v=S[42] ( ) ;
    return v,D;
  end,nj=function (D,D)
    D[41] ,D[46] =D[40] , (D[2] ) ;
  end,d=bit32.lrotate,Oj=function (D,S)
    (S) [54] = (function ( )
      local v,G,N,I;
      G,I,N=D:Rh(N,I,G) ;
      local n,i,P,U;
      I,P,U,G,i,N,n=D:Ah(S,U,N,G,I,P,n,i) ;
      local c;
      for q=69,213,12 do
        v,P,c,U,i=D:Mj(i,P,q,c,S,N,U) ;
        if v==19808 then
          break;
        end;
      end;
      local q,W= (S[23] (N) ) ;
      for K=110,180,52 do
        v,W=D:Pj(K,G,N,W,S) ;
        if v==52331 then
          break;
        end;
      end;
      (G) [5.0] =U;
      for K=96,420,108 do
        v=D:Hj(P,K,W,G,q,i) ;
        if v~=25987 then
        else
          continue;
        end;
      end;
      for K=113,144,9 do
        v=D:hj(n,c,G,K) ;
        if v~=46413 then
        else
          break;
        end;
      end;
      for K=1.0,N,1 do
        local N,j,o,e,r,H;
        o,N,r,e,j,H=D:Lj(j,N,o,e,r,S,H) ;
        local _,C,X;
        X,_,C=D:pj(o,r,X,C,_,j,N,H) ;
        j= (o-C) /8;
        for l=126,215,89 do
          if l~=215.0 then
            if S[22] ==S[33]then
              if -217 then
                return 123;
              end;
            end;
            if H~=S[51]then
              (n) [K] =e;
              (P) [K] =j;
              o= (49) ;
              while true do
                if o<=49.0 then
                  if not (o>11.0)then
                    o=110;
                    if H==1 then
                      D:Ij(S,K,X,G,U) ;
                    elseif H==4 then
                      W[K] =X;
                    elseif H==6 then
                      (W) [K] = (K+X) ;
                    else
                      if H==5 then
                        if S[2] ==S[35]then
                        else
                          W[K] =K-X;
                        end;
                      else
                        if H==3 then
                          N=nil;
                          local n= (12) ;
                          repeat
                            n,v,N=D:dj(S,N,n,U) ;
                            if v~=21864 then
                            else
                              break;
                            end;
                          until false;
                          S[34] [N+2.0] = (K) ;
                          (S[34] ) [N+3.0] = (X) ;
                        end;
                      end;
                    end;
                    continue;
                  else
                    o=D:qj(X,W,o,K) ;
                    continue;
                  end;
                else
                  if o~=110.0 then
                    o=D:Wj(_,K,o,q) ;
                  else
                    v=D:Zj(S,c,C,P,K,j,H,G) ;
                    if v==64214 then
                      break;
                    else
                      if v~= -1 then
                      else
                        return ;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          else
            D:Dj(q,G,r,i,K,S,_) ;
          end;
        end;
      end;
      P=nil;
      U= (nil) ;
      I=40;
      repeat
        if I>40.0 and I<92.0 then
          I=D:Jj(I,S,G) ;
          continue;
        elseif I>49.0 and I<103.0 then
          return G;
        elseif I<49.0 and I>26.0 then
          I=103;
          P=S[42] ( ) ;
          U=S[23] (P) ;
        elseif I>92.0 then
          I=26;
          if S[39] ~=S[2]then
            D:kj(G,U) ;
          end;
          continue;
        else
          if I<40.0 then
            I=D:Uj(P,S,U,I) ;
            continue;
          end;
        end;
      until false;
    end) ;
  end,wj=function (D,D,S,v,G,N,I)
    if S<146.0 then
      N= ( (G-D) /8) ;
    else
      if not (S>38.0)then
      else
        v= (I%8) ;
        return 44003,v,N;
      end;
    end;
    return nil,v,N;
  end,n= {
    29500,4071585453,2924701319,2011191002,4190533513,1403293166,4122370508,2919615866,2673357953
  } ,bh=function (D,D)
    D[38] =nil;
    (D) [39] = (nil) ;
    D[40] = (nil) ;
  end,ah=function (D,S,v)
    S=nil;
    local G=28;
    while true do
      if G<75.0 then
        S,G=D:Jh(G,v,S) ;
        continue;
      else
        if G>28.0 then
          if v[7] ~=v[5]then
          else
            if - ( -248)then
              (v) [33] ,v[12] =v[12] , (29) ;
            end;
          end;
          break;
        end;
      end;
    end;
    if not (S>=v[5] )then
    else
      return -2,S, (D:kh(v,S) ) ;
    end;
    return nil,S;
  end,Sh=function (D)
  end,mj=function (D,S,v,G,N)
    local I;
    v= (nil) ;
    local n,i= (80) ;
    repeat
      I,i,n,v=D:Nj(S,G,i,v,n,N) ;
      if I==3832 then
        break;
      else
        if I==54461 then
          continue;
        end;
      end;
    until false;
    return v;
  end,jq=function (D,S,v,G,N)
    G= (function ( )
      local I,n,i;
      i,I,n=D:Mq(v,i,n) ;
      if I~= -1 then
      else
        return ;
      end;
      (v) [48] =nil;
      n=88;
      repeat
        if n==88.0 then
          n=D:nq(n,v) ;
          continue;
        else
          if n==87.0 then
            n= (74) ;
            v[28] =D.D;
          else
            if n==74.0 then
              return i;
            end;
          end;
        end;
      until false;
    end) ;
    if not S[19582]then
      S[2501] = (68+ ( (D.cq( ( (D.cq(S[8599] ) ) -S[20931] <S[21440]and S[13343]or S[13737] ) ==S[20702]and N or D.n[6] ) ) <=S[938]and S[27084]or S[21002] ) ) ;
      N= -3649568620+ (D.bq( (D.Dq( (D.dq( (D.Vq(S[29426] >D.n[4]and S[19057]or S[11202] , (S[6055] ) ) ) +S[8599] ) ) ,D.n[7] ,S[19057] ) ) , (S[20702] ) ) ) ;
      S[19582] =N;
    else
      N=S[19582] ;
    end;
    return G,N;
  end,pj=function (D,S,v,G,N,I,n,i,P)
    local U;
    I= (nil) ;
    N=nil;
    for c=38,188,108 do
      U,N,I=D:wj(v,c,N,i,I,S) ;
      if U==44003 then
        break;
      end;
    end;
    G= (n-P) /8;
    return G,I,N;
  end,Zh=function (D,S,v,G,N)
    if G<=112.0 then
      if G~=107.0 then
        S= (1.0) ;
        return v,24419,S;
      else
        v= (0.0) ;
        return v,24419,S;
      end;
    else
      if G<122.0 then
        repeat
          local G,I= (12) ;
          repeat
            if G>30.0 then
              I,G,v=D:ih(S,G,N,v,I) ;
              D:Sh( ) ;
              continue;
            else
              if G<123.0 and G>12.0 then
                S*=128.0;
                break;
              else
                if G<30.0 then
                  G= (123) ;
                end;
              end;
            end;
          until false;
        until I<128.0;
        return v,24419,S;
      else
        return v, -2,S,v;
      end;
    end;
    return v,nil,S;
  end,Aj=function (D,D,S)
    for v=1.0, #S[34] ,3.0 do
      (S[34] [v] ) [S[34] [v+1.0] ] = (D[S[34] [v+2.0] ] ) ;
    end;
  end,qh=function (D,S,v)
    (S) [30777] = -4294937877+ ( (D.Iq(S[27695] -S[8599] ,S[6843] ) ) +S[20760] -D.n[1] +S[13343] +S[27695] ) ;
    (S) [17476] = ( -4289881861+ ( (D.Dq( (D.Iq(D.n[8] ) ) -S[14061] +S[20702] -D.n[3] ,S[20702] ) ) +S[27083] ) ) ;
    v= -2673357906+ ( (D.dq(D.n[8] ) ) +S[6055] -S[30736] -D.n[7] +D.n[6] <=D.n[5]and D.n[9]or S[756] ) ;
    S[11202] = (v) ;
    return v;
  end,Tj=function (D)
    return ;
  end,h=buffer,o=getfenv,vj=function (D,D,S)
    D=S[43] ( ) ;
    return D;
  end,x=function (D,S,v,G,N)
    G= (nil) ;
    N[4] = (nil) ;
    N[5] =nil;
    v= (17) ;
    while true do
      if v>60.0 then
        N[5] =4503599627370496;
        break;
      else
        if v<107.0 and v>17.0 then
          (N) [4] =D.H;
          if not (not S[6625] )then
            v=S[6625] ;
          else
            v=D:O(v,S) ;
          end;
          continue;
        else
          if not (v<60.0)then
          else
            G=D.P;
            if not S[8599]then
              v=D:Y(v,S) ;
            else
              v=S[8599] ;
            end;
            continue;
          end;
        end;
      end;
    end;
    return v,G;
  end,Ch=function (D,D,S)
    D=S[11112] ;
    return D;
  end,tq=function (D,S,v,G,N,I,n,i)
    v=8;
    while true do
      if v==71.0 then
        return I, {
          S[53] (I,S[33] )
        } ,v;
      else
        if v==8.0 then
          I=S[53] (I,S[33] ) (D,G,D.j,n,i,S[35] ,S[37] ,S[39] ,S[45] ,S[49] ,D.n,S[53] ) ;
          if not N[22417]then
            v=D:lq(N,v) ;
          else
            v=D:eq(N,v) ;
          end;
          continue;
        end;
      end;
    end;
    return I,nil,v;
  end,Uh=function (D,D)
    return D;
  end,e=type,Pj=function (D,S,v,G,N,I)
    if S==162.0 then
      if I[37] ==I[25]then
        D:uj(v,I) ;
      end;
      return 52331,N;
    else
      N=D:rj(N,I,G) ;
    end;
    return nil,N;
  end,Xj=function (D,D)
    D[42] = (209) ;
  end,Wh=function (D,S,v)
    v= (4071585350+ ( ( ( (S[677] ~=S[27084]and S[23165]or S[6625] ) ==S[677]and S[27084]or S[20931] ) ~=S[6625]and S[27695]or S[27084] ) +S[27083] +S[13486] -D.n[2] ) ) ;
    S[938] = (v) ;
    return v;
  end,nq=function (D,D,S)
    D=87;
    S[34] =nil;
    return D;
  end,Th=function (D,D,S)
    S= (D[20919] ) ;
    return S;
  end,Mh=function (D,S,v)
    (S) [20931] = ( -2011161394+ ( (D.Iq( (D.Eq( (D.dq( (D.cq(S[20760] ) ) +D.n[9] ) ) , (S[13737] ) ) ) ,D.n[4] ) ) -D.n[1] ) ) ;
    S[19526] =111+ (D.dq( (D.Vq( (D.fq( (D.dq(S[13737] >=S[677]and S[21002]or D.n[9] ) ) +S[29426] ) ) , (S[27084] ) ) ) ) ) ;
    v= ( -2011190896+ ( ( ( (D.bq( (D.Iq(D.n[3] -D.n[2] ) ) , (S[20702] ) ) ) <S[13343]and S[27084]or D.n[6] ) ~=S[6843]and D.n[8]or S[20702] ) <D.n[6]and S[21002]or D.n[4] ) ) ;
    return v;
  end,N=function (D,S,v,G,N)
    (S) [15] = (nil) ;
    (S) [16] = (nil) ;
    v= (23) ;
    repeat
      if v>23.0 then
        (S) [16] = (G[D.K] ) ;
        break;
      else
        if v>10.0 and v<97.0 then
          (S) [14] =G.readu16;
          if not N[20702]then
            (N) [677] =90+ ( (D.dq( (D.qq(N[6843] -N[20760] , (N[27084] ) ) ) -D.n[3] ) ) -N[27084] +N[6843] ) ;
            (N) [21440] = ( -2924701304+ (D.Iq( (D.bq( (D.cq( (D.cq(v-N[21002] ) ) -D.n[9] ) ) , (N[27084] ) ) ) ,D.n[3] ,N[27084] ) ) ) ;
            v= ( -1621609286+ ( (D.Dq( ( (D.bq(v, (v) ) ) -D.n[6] ==D.n[2]and N[21002]or N[8599] ) -N[6625] ) ) -D.n[9] ) ) ;
            N[20702] =v;
          else
            v= (N[20702] ) ;
          end;
        else
          if not (v<23.0)then
          else
            (S) [15] =G[D.v] ;
            if not N[13343]then
              v= ( -1560023158+ (D.fq( (D.Iq( (D.zq( (D.fq(N[20702] ) ) -D.n[3] ) ) ,D.n[2] ,N[21002] ) ) -N[677] ) ) ) ;
              N[13343] = (v) ;
            else
              v=N[13343] ;
            end;
          end;
        end;
      end;
    until false;
    S[17] =G.readf32;
    (S) [18] =nil;
    return v;
  end,Pq=function (D, ... )
    return ( ... ) [ ... ] ;
  end,Kq=function (D,D,S)
    D= (S[15334] ) ;
    return D;
  end,vq=function (D,S,v,G)
    if S>22.0 then
      S=D:gq(v,S,G) ;
    else
      if not (S<83.0)then
      else
        v[46] [8.0] =D.E.unpack;
        return 29103,S;
      end;
    end;
    return nil,S;
  end,wh=function (D,D,S)
    S= (D[29749] ) ;
    return S;
  end,Ih=function (D,D,S)
    D[10] = (D[10] +4.0) ;
    S= (15) ;
    return S;
  end,lh=function (D,D,S,v)
    v=65;
    S=D[14] (R,D[10] ) ;
    return v,S;
  end,uj=function (D,S,v)
    local G= (32) ;
    repeat
      if G<82.0 then
        (v) [37] = (S>=v[46] ) ;
        G= (82) ;
      else
        if not (G>32.0)then
        else
          D:jj(v) ;
          break;
        end;
      end;
    until false;
  end,J=function (D,D,S)
    S= (D[20760] ) ;
    return S;
  end,Gq=function (D,S,v,G)
    local N;
    repeat
      N,G=D:vq(G,v,S) ;
      if N~=29103 then
      else
        break;
      end;
    until false;
    (v[46] ) [6.0] =D.T;
    v[46] [21.0] =D.i.ceil;
    v[46] [10.0] = (D.i.modf) ;
    (v[46] ) [19.0] =D.fq;
    G=90;
    while true do
      if G>75.0 and G<113.0 then
        (v[46] ) [20.0] = (D.q.rrotate) ;
        if not S[15334]then
          S[8717] = (67+ (D.zq( (D.dq( (D.Dq( (D.cq( (D.zq(S[6843] ,S[677] ) ) ) ) ) ) +S[11202] ) ) ,S[17476] ) ) ) ;
          G= ( -4289527694+ ( (D.Vq( (D.fq( (S[27083] >=S[13343]and S[30777]or S[938] ) ==S[14307]and S[20919]or S[11372] ) ) , (S[27695] ) ) ) +D.n[6] -D.n[6] ) ) ;
          (S) [15334] = (G) ;
        else
          G=D:Kq(G,S) ;
        end;
        continue;
      else
        if G<75.0 and G>28.0 then
          v[46] [16.0] =D.l;
          break;
        elseif G>90.0 then
          G=D:wq(G,v,S) ;
          continue;
        elseif G<46.0 then
          v[46] [9.0] =D.S;
          if not (not S[20423] )then
            G= (S[20423] ) ;
          else
            G= -1713295205+ ( (D.bq( (D.bq( (D.Dq( (S[11202] >S[30736]and D.n[4]or S[19582] ) -S[20702] ,D.n[7] ) ) , (S[14307] ) ) ) , (S[14307] ) ) ) +S[8717] ) ;
            (S) [20423] =G;
          end;
        else
          if not (G<90.0 and G>46.0)then
          else
            (v[46] ) [17.0] =D.Z;
            if not (not S[19066] )then
              G= (S[19066] ) ;
            else
              G=D:pq(S,G) ;
            end;
          end;
        end;
      end;
    end;
    (v[46] ) [18.0] =D.qq;
    return G;
  end,Yh=function (D,S,v,G)
    (v) [44] = (D.q.rshift) ;
    v[45] =function ( )
      local N,I=90;
      while true do
        if N==113.0 then
          v[10] =v[10] +4.0;
          N= (28) ;
        elseif N==28.0 then
          return I;
        else
          if N~=90.0 then
          else
            I=v[17] (R,v[10] ) ;
            N=113;
            continue;
          end;
        end;
      end;
    end;
    if not G[24321]then
      S=D:Oh(G,S) ;
    else
      S= (G[24321] ) ;
    end;
    return S;
  end,r=table.move,Jj=function (D,D,S,v)
    D=92;
    (v) [11] =S[42] ( ) ;
    return D;
  end,oj=function (D,D,S)
    S=D%8;
    return S;
  end,mh=function (D,S)
    (S) [49] =function ( )
      local v=S[19] (R,S[10] ) ;
      for R=107,202,69 do
        if R==107 then
          (S) [10] =S[10] +8.0;
          continue;
        else
          if R~=176 then
          else
            return v;
          end;
        end;
      end;
    end;
    S[50] = (function ( )
      local R,v;
      R,v=D:Bh(S) ;
      if R~= -2 then
      else
        return v;
      end;
    end) ;
    (S) [51] =function ( )
      return (D:Nh(S) ) ;
    end;
    S[52] = (nil) ;
    (S) [53] = (nil) ;
    (S) [54] =nil;
  end
} ) :C( ) ;
