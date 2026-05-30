-- string.char(40,99,41,32,83,83,32,69,120,101,99,117,116,111,114,32,32,124,32,32,85,110,97,117,116,104,111,114,105,122,101,100,32,99,111,112,121,105,110,103,32,111,114,32,114,101,100,105,115,116,114,105,98,117,116,105,111,110,32,105,115,32,112,114,111,104,105,98,105,116,101,100,46)
-- string.char(83,111,117,114,99,101,58,32,103,105,116,104,117,98,46,99,111,109,47,114,111,98,108,111,120,115,99,114,105,112,116,101,114,54,50,52,53,51,54,54,53,52,50,47,114,111,98,108,111,120,45,108,117,97,45,111,98,115,99,97,116,111,114)

local _c=string.char;local _fc=string.find;local _sb=string.sub
local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load

local _K1={206,213,48,207,226,217,100,115,54,29,216,87,202,161,140,123}
local _K2={158,101,128,223,178,105,180,131,6,173,40,103,154,49,220,139}
local _K3={110,245,208,239,130,249,4,147,214,61,120,119,106,193,44,155}
local _K4={62,133,32,255,82,137,84,163,166,205,200,135,58,81,124,171}

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
_P=_P..'4/gQ8t/kWU4LIOVq95yxRqNYveKPVIm+O5AVWqcM4bZTyO3Sv8Q5rusARUpX/BGmA7gdwm+0aZ6b'
_P=_P..'8PW6B2xBlvPoDcXP9ERTeFiAApmBySPbJtWL/TuUo+Qtu0e6fLPvG5mxnaK7a/yiTgwFC7EmthOl'
_P=_P..'ALk3/TfLw77o5lY9XMahsUWjh6pEBV98+DCrzOlB1hH0r/UMwKMtjUQI+1Wv/xycvois8ym+9h03'
_P=_P..'FQy0X/hf8UXfJeAgy5zt6OtPMEmF+vVfrYSsFxBXab15ptTtcbNIoOKPVIm+O5AVWqcM4bZTyO3S'
_P=_P..'v8Q5rusARUpX/BGmA7gdwm+0aZ6b8PW6B2xBlvPoDfLf5FlOCyDlavecsUajWL3VuAXb4GfBCDj1'
_P=_P..'WvCrMZCinaLEJOO1XBQbQqdZ9V3xSZA8oX2prODlp9jF/ElaVRCch6sSGlV4q3coNQyZCuViSzKL'
_P=_P..'IAPkOaiFDrE+H+4XRG9gbYRxQr2a4+ojuBvcEaAdxgm2NyYvXAfYxfxJWlXSW2I78PPUiVi1XiFu'
_P=_P..'7x6HFF9Q/TRhki3K8xrTSAuMYVANFnnmB1bf7PeIVax5qgXCa9JrwCNEWUhlrtGeP043pE8ATeSR'
_P=_P..'op06w0pDGPt88QA9JulWF4ZPvOd4pVxp+nUyewIbkBM0qfiV/kHOD75ntH+wHdRBMk0qE7qz6Css'
_P=_P..'QbAtdlmG57b/TNcoNQyZCuWKs90K1e8m/UQG41Su+E7I8IjjlGGpkVgMJA+zWvJd4AjdAuU12sO/'
_P=_P..'u6UTWxDErbRc77CKRFMWPfh394HrGvMAupjXHefmdNtBBP8Z/tkLhbyG4Zhw9rJuDBgYoEv+HKwq'
_P=_P..'kz3qNc+GmIHUGnFci+7oEKiDtAFJcXisBK/T+hL9AKj95xrR8U/DWBLuYrn5GJyziqDQDv+5Xhkb'
_P=_P..'SpV/ux6lAN9ytHTEx6CtvX00CPirp0amgbxMUWJqvTKk8ukJ6AzjupBAvokrgAiFDrE+H+7Vh47r'
_P=_P..'jST1uU9YOwWiTfdu6UGGN/t0i9GiuuxJcRXF7rRco8K8HBZVaKw4uNKgW/AKoI3HB+fmdNtBBP8Y'
_P=_P..'/Gn6dTJ7AhuQEzSp+JX+Qc4Pvme0f7Ad1EEyTSoTurPoKyxBsC12WYbnthe0OKnA4FvSNYq53RuU'
_P=_P..'3CaQCFa2Ee25XtW0gIjZJLP2cShXV+F891/8RY0hpxjMxayk11YwBc683xDvwvkNFRZRiHe+yekV'
_P=_P..'vgfyutMClOZoySJHuhH8/w+Gu8H1mG3n/g1WRkPLSfVaj0mZcuc714aBmKdOORnF7qJRvYzxRih4'
_P=_P..'eKAiufysNfFFzLDRCNjTasxRAugRve0akKLPs8sk4PgfUUxKs0nvS/dO3zfnMKms4OWn2MX8SVpV'
_P=_P..'EJ+OuB0WRFqtPupDGPt88QA9JulWF4ZPvOd4pVxp+nUyewIbkBM0qfiV/kHOD75ntH+wHdRBMk0q'
_P=_P..'E7qz6CssQbAtdlmG57b/TNcoNQyZCuViSzKLIAPkOaiFDrE+H+4XRG9gbYRxQr2a4+ojuBvcEaAd'
_P=_P..'xgm2NyYvXAfYxfxJWlXSW2I78PPUiVi1XiFu7x6HFF9Q/TRhki3K8xrTSAuMYVANFnnmB1bf7PeI'
_P=_P..'Vax5qgXCa9JrwCNEWUhlrtGeP043pE8ATeSRop06w0pDGPuUCe+80wWU00HYQUenEZDbVKKxhva/'
_P=_P..'a+GVVREbDukOy1LkWZogziHKhOHotg94dsKo9V6glvk0NEN0+COixOJb6QTysZpL781j1V0UxxGS'
_P=_P..'5E6lvI77nHbUo1RWVUP6DOlb8VWNPKkxzcLHwqoXcS7Oo7pGqsKqEBJaePgQn+isHewK7f/CG9H1'
_P=_P..'b8JdFLpYsuELlqSG7ZcO/7leGRtKrkD/HrgArxX8PZngpKbjfDgO2LqWWKaOvUxRaUKLBJXk1D7d'
_P=_P..'Ot/9m2Pd5SbCRAO6RbTuANW/g+bDQPalSQoYE+kFu1vrRPVYpHmDRFlIZa7RXOehtFSmjL5EHVlp'
_P=_P..'sTGjwu0P9wru/1D9NGGSLcrzGtNIC4xhUA0WeeYHVt/s94hVrHmqBcJr0mvAI0RZSGWu0Z4/Tjek'
_P=_P..'TwBN5JGinTrDSkMY+3zxAD0m6VYXhk+853ilXGn6dTJ7AhuQEzSp+JX+Qc4Pvme0f7Ad1EEyTSoT'
_P=_P..'urPoKyxBsC12WYbntv9M1yg1DJkK5WJLMosgA+Q5qIUOsT4f7hdEb2BthHFCvZrj6iO4G9wRoB3G'
_P=_P..'CbY3Jse45Fs9EIOooF6slrALHR400nfqgawc/wjl5fUMwNBj314O+VT0qT2BsZ32nHbUo1RaXlCS'
_P=_P..'Se996lKaeqsHxsiphuhOOBrCrbREpo23Rl88Pfh36oGsW74e1LbGBdG+JONNH+9C/M4WkLOa9pZ2'
_P=_P..'sfodLBIStRG5cupBmzvnM42I4+qrGhUJ2a+hWaCM5FcOHxe9Oa6IhnGzSKA9JulWF4aNew/7Q7nv'
_P=_P..'TpuxgueKdPK1WFiV/kHOD75ntH+wHdRBMk0qE7qz6CssQbAtdlmG57b/TNcoNQyZCuViSzKLIAPk'
_P=_P..'OaiFDrE+H+4XRG9gbYRxQr2a4+ojuBvcEaAdxgm2NyYvXAfYxfxJWlXSW2I78PPUiVi1XiFu7x6H'
_P=_P..'FF9Q/TRhki3K8xrTSAuMYVANFnnmB1bf7PeIVax5qgXCa9JrwCNEWUhlrtGeP043pE8ATeSRop06'
_P=_P..'w0pDGPt88QA9JulWF4anRAj5ULCrPLSHz7/ZJvuiSQgEUO4D6V/yDpg7/TzWxLi74kgyE8W6sF67'
_P=_P..'zLoLHhlvtzWmzvQI/Rfpr8YMxrU0mR1UrAfpv1zaooDglWvr+1ENFkeuTuhd5FSQIKY3z8e4rOIV'
_P=_P..'IhnYvbxfoc+MIANdKvd1wKvTPLA604ySVJT4DI0IR7pjndxO1fDPosQkwZdqVH1K4Qy7ctUA33Kp'
_P=_P..'dIOb7YTXFltci+71YIiXsERTFj3ld5rm+RKyb6D/kknk72fUTRXpEeGrPpmxlueLd7/cHVhXSpN/'
_P=_P..'ux6lAN9ytHTx9eHCpxpxXP6HhhDvwvlEThZIkQTmq6xbvkXUjJJJlKMmjRVHzmLwgRP/2sKv2eYH'
_P=_P..'Vt/s90qMQ/9L6UXfPuY1x8O/6GWu0Z4/TjekTwBN5JGinTrDSkMY+3zxAD0m6VYXhk+853ilXGn6'
_P=_P..'dTJ7AhuQEzSp+JX+Qc4Pvme0f7Ad1EEyTSoTurPoKyxBsC12WYbntv9M1yg1DJkK5WJLMosgA+Q5'
_P=_P..'qIUOsT4f7hdEb2BthHFCvZrj6iO4G9wRoB3GCbY3Ji9cB9jF/ElaVdJbYjvw89SJWLVeIW7vHocU'
_P=_P..'X1D9NGGSLcrzGtNIC4xhUA0WeeYHVt/s94hVrHmqBSrSf6kB0MO+6OtVMBjYuqdZoYX5CwEWcbc2'
_P=_P..'roFu+wpF97DAAsejacMII/9dqOpC1YOW7Jh04LMRWDwYr0C3HsNMiir8J4+GqLzkFFsQxK20XO+9'
_P=_P..'tQBTCz20OKvF/w/sDO64kgbGo2rCSQOQO7DkDZS8z+SMavCiVBcZSq1D+lrIT5t6+TXXzuTCpxpx'
_P=_P..'XMehtlGjwrYPQRo9qyWpgbFb7gbhs95B0+JryAYv7kWszAuB/M/lmGn2+h0qNj3vAutf8UjTcv0m'
_P=_P..'1sPkwqcacVzCqPVeoJb5CxgEPaw/r8+GW75FoP+SSZT0Z99GT7hqku4WgKOyorFQx4YdHhYDrRa7'
_P=_P..'HKsOjzP9PI2I7+hlusVcieD7RKCRrRYaWHrwJLjCpVKlRfK6xhzG7QyNCEe6VLLvZNXwz6KVa/C3'
_P=_P..'UVgRBO0M+FulHd8N5TCL1b+rrjBxXIvuvFbvjLYQU1Bz+COixOJxvkWg/5JJlKNxzFoJshOHxQuN'
_P=_P..'pZzf2Uf8u00RGw/hSvpX6RrfcKd608e5oKkUc1xJTkEQ7cz3EBxFaao+pMakGPtMqeSSG9H3c99G'
_P=_P..'bboR/KsLm7Tlotkks7pSGxYG4UPwDakAjTepaYPWrqnrVnkaxeffEO/C+Q0VFnO3I+rO50i+Eei6'
_P=_P..'3GOUoyaNCEe6EavqHJv4zdm3YeujTiVXOLRC71foRd806D3PnO3qqRQhHd+m+x7twjvk5xY/9nm+'
_P=_P..'zv8P7AzuuJob0aovpwhHuhG55Qr/tYHm8w6++x2a4+ojuBsexk+NN6k4ysS/qfVTNA+L5rpCq4er'
_P=_P..'RB5XaawyuNKlW3zxAD0m6VYXhk+853ilXGn6dTJ7AhuQEzSp+JX+Qc4Pvme0f7Ad1EEyTSoTurPo'
_P=_P..'KyxBsC12WYbntv9M1yg1DJkK5WJLMosgA+Q5qIUOsT4f7hdEb2BthHFCvZrj6iO4G9wRoB3GCbY3'
_P=_P..'Ji9cB9jF/ElaVdJbYjvw89SJWLVeIW7vHocUX7gF2+Ji4EcDshOw4gzapIfnlGG9ukgZVUPhDLsT'
_P=_P..'qACsAacXj4aem6luF1CLnYYem7HrSFNlTvYRiI2sKM1LxpGeSefQKOtrbfZeve8jmrTHoJVt8flI'
_P=_P..'EVkGtE25F6UA33KpdI6L7ZvUFBcOxuGZUqPNmxAdGVS2J+Xi4xWxNuOtnQHb9SnORxX0VK6kHYGi'
_P=_P..'gOmcK+O3WVcbA7JY0xHpSYwm33vRybqK5kh+CNzEuV+uhpQLFx4/tD6oju4J9wHnupwFweIkhAhH'
_P=_P..'txz82D3bkp3rnWP2+h0rJESxRfVZx1KWNu4xj4aem6lZMBDHjKdZq4W8bh9ZfLwapcWkWfIM4vDF'
_P=_P..'ANrnadoGC+9Q/qJO1f3CoqpXvYF0Nlg+g23JEdZpuxemFuzilOSnaQJSxauiZK6A9UQgZTOrP6XW'
_P=_P..'3Br5AIrVn0SUYZItyvMaEYjqDNW9gOaMaPalHZrj6iO4G9wRoB3GCbY3Ji9cB9jF/ElaVdJbYjvw'
_P=_P..'89SJWLVeIW7vHocUX1D9NGGSLcrzGtNIC4xhUA0WeeYHVt/s94hVrHmqBcJr0mvAI0RZSGWu0Z4/'
_P=_P..'TjekTwBN5JGinTrDSkMY+3zxAD0m6VYXhk+853ilXGn6dTJ7AhuQEzSp+JX+Qc4Pvme0f7Ad1EEy'
_P=_P..'TSoTurPoKyxBsC12WYbntv9M1yg1DJkK5WJLMosgA+Q5qIUOsT4f7hdEb2BthJm6UhkTJ65Isxzx'
_P=_P..'QZ0hpjHbw669819/EN6v9xnFjrYFF3tyvH/o1e0Z7UrzusAf0fEowV0GuBjW5wGUtKLtnSyxolwa'
_P=_P..'BEWyTfVa50+HfOUhwoTkwutVMBjmobEY7Za4BgAZcLk7vcD+HrAJ9b6QQL7vacxMKvVV9KkalLKc'
_P=_P..'rZ1h/LRbDQQJ70DuX6cJ9T7mNcfroqyvGCUdyb36U6eHug8WRDO0IquDpVu+Ra3ykgjY8GmNRAj7'
_P=_P..'Va+rCpSkjq2MavD4UQ0WRuFI+krkD4wn5zeNyripqxo1Hd+v+l22kLAFFxhxrTbAzeMa+ijvu5pL'
_P=_P..'wOJk3gcU+UO1+xqG/oP3mCa63FEXFg6MQ/8Wp1SeMPp7xsi75utPMF6CxN8d4sI78PPUiVh3jMji'
_P=_P..'GvIM87qSiyAD5DmohQ6xPh/uF0RvYG2EcUK9muPqI7gb3BGgHcYJtjcmL1wH2MX8SVpV0ltiO/Dz'
_P=_P..'1IlYtV4hbu8ehxRfUP00YZItyvMa00gLjGFQDRZ55gdW3+z3iFWseaoFwmvSa8AjRFlIZa7Rnj9O'
_P=_P..'N6RPAE3kkaKdOsNKQxj7fPEAPSbpVheGT7zneKVcafp1MnsCG5ATNKn4lf5Bzg++Z7R/sB3UQTJN'
_P=_P..'KhO6s+grLEGwLXZZhue2/0zXKDUMmQrlYksyiyAD5DmobfNX/NQp24+80dd3+7lKKBYNpAy7HqVU'
_P=_P..'lzfndPzh45fUaX8Pw6GiYK6FvExCHz34d+rE4h+UDOb/7S6a3FX+Bg70WKjIBpCzhOeLJOe+WBZX'
_P=_P..'NYYCxG3WDpY84CDgzqir7F8jVILu9VWhhtNuA1V8tDvix/kV/RHpsNxBnYkmjQhH/VCx7lSytZvR'
_P=_P..'nHblv14dX0iSWPpM8UWNFfw9gY/3m+JOEhPZq/0SnIe3AD1ZabExo8LtD/cK7v2eY5SjJo0IR7oR'
_P=_P..'p98HgbyKv9tK9q5IC1cvuUn4S/FPjXCldPfDtby6GB0TyqqwVO8ARfdRGj2cIrjA+BLxC73tz0C+'
_P=_P..'5mjJAW2QVLLvR9Xwwq/ZYf2yHQgUC61AkTTsRt885iCD+aKjp045GcXuolG9jPFGKHh4oCK5/Kwo'
_P=_P..'yiTSi+c5lMZU/2c1oBH+pUCBv5z2i239sRUnEhizBbIe4E6bWA=='

local _fn,_er=_ld(_xd(_bd(_P),_K))
if not _fn then
    warn(string.char(91,83,83,32,69,120,101,99,117,116,111,114,93,32,76,111,97,100,32,101,114,114,111,114,58,32)..tostring(_er))
else
    _fn()
end
