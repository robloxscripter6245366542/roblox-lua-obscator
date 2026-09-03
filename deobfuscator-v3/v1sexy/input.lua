local Env = getfenv();
local s = {};
t, L = a, "string";
U = H[L];
L = "gmatch";
O = U[L];
p = 8;
L = 9;
y = "pcall";
s[L] = O;
O = true;
s[p] = O;
W = 10;
O = function(...)
    local x = {};
    U, t = "error", "Tamper Detected!";
    O = H[U];
    U = O(t);
    return; 
end;
C = O;
O = false;
g = function(...)
    local x = {
        W
    };
    O = true;
    s[x[1]] = O;
    return; 
end;
s[W] = O;
q = H[y];
y = q(g);
U = y;
if y then
    q = s[W];
    U = q;
end;
y, g, q = "math", "table", U;
U = H[y];
y = "random";
O = U[y];
y = 1;
s[y] = O;
U = H[g];
l, g = "table", "concat";
O = U[g];
F, g = O, O;
A = H[l];
N = A and table.unpack;
O = F;
U = N;
while N do
    N = 11;
    s[N] = U;
    A = 65;
    O = s[y];
    F = 3;
    o = function(...)
        local x = {};
        L, U, p = "rstr2", "rstr1", 123;
        t = L ^ p;
        O = U - t;
        U, t = "rstr3", O;
        O = U / t;
        return O; 
    end;
    U = O(F, A);
    O = 0;
    F = 12;
    A = O;
    s[F] = U;
    O = 0;
    l, V = O, "pcall";
    U = H[V];
    V = {
        U(o)
    };
    O, U = {
        c(V)
    }, 2;
    V, Z = O, "tostring";
    O = V[U];
    U, o = "tonumber", O;
    O = H[U];
    m = s[L];
    z = H[Z];
    Z = z(o);
    z = ":(%d*):";
    i = m(Z, z);
    m = {
        i()
    };
    U = O(c(m));
    m = 13;
    s[m] = U;
    i = s[F];
    U, z = 1, i;
    i = 1;
    Z = i;
    i = 0;
    for i = U, z, Z do
        Q = 100;
        D = 2;
        s[D] = i;
        P = "math";
        U = H[P];
        P = "random";
        O = U[P];
        P = 1;
        U = O(P, Q);
        P = 3;
        I = 255;
        s[P] = U;
        O = s[y];
        Q = 0;
        U = O(Q, I);
        Q = 4;
        s[Q] = U;
        r, I, T, w = 10000, 1, 2, 0;
        O = s[y];
        u = 1;
        n = s[P];
        U = O(I, n);
        I = 5;
        s[I] = U;
        U = s[y];
        R = "tostring";
        n = U(u, T);
        U = 1;
        O = n == U;
        T = ":";
        n = 6;
        s[n] = O;
        X = H[R];
        U, O = ":(%d*):", "gsub";
        O = o[O];
        M = s[y];
        k = {
            M(w, r)
        };
        R = X(c(k));
        X = ":";
        f = R .. X;
        u = T .. f;
        O = O(o, U, u);
        u = 7;
        s[u] = O;
        T = "pcall";
        U = H[T];
        f = function(...)
            local x = {
                y,
                D,
                F,
                L,
                p,
                m,
                n,
                u,
                P,
                I,
                Q,
                N
            };
            L = s[x[1]];
            C, W = 1, 2;
            p = L(C, W);
            L = 1;
            t = p == L;
            U = t;
            while t do
                if U then
                    g, C, U = "pcall", "tostring", "tonumber";
                    O = H[U];
                    t = s[x[4]];
                    p = H[C];
                    N = function(...)
                        local x = {};
                        L, U, p = "rstr2", "rstr1", 123;
                        t = L ^ p;
                        O = U - t;
                        t, U = O, "rstr3";
                        O = U / t;
                        return O; 
                    end;
                    y = H[g];
                    g = {
                        y(N)
                    };
                    y, q = 2, {
                        c(g)
                    };
                    W = q[y];
                    C = p(W);
                    p = ":(%d*):";
                    L = t(C, p);
                    t = {
                        L()
                    };
                    U = O(c(t));
                    t = U;
                    L = s[x[5]];
                    U = L and s[x[6]] == t;
                    s[x[5]] = U;
                    t = nil;
                end;
                O = s[x[7]];
                if O then
                    t = "error";
                    O = H[t];
                    p = 0;
                    L = s[x[8]];
                    t = O(L, p);
                end;
                L, O = 1, {};
                t = O;
                p = s[x[9]];
                C = p;
                p = 1;
                W = p;
                p = 0;
                for p = L, C, W do
 
                end;
                O = s[x[10]];
                L = s[x[11]];
                t[O] = L;
                O = s[x[12]];
                L = {
                    O(t)
                };
                return c(L); 
            end;
            L = s[x[2]];
            p = s[x[3]];
            t = L == p;
            U = t; 
        end;
        T = {
            U(f)
        };
        O = {
            c(T)
        };
        T = O;
        O = s[n];
        if O then
            f = s[p];
            U = f;
            s[p] = U and T[1] == false;
        end; 
    end;
    repeat
        
    until s[p];
    i, z = "print", "Done brocachino";
    O = H[i];
    R = 256;
    i = O(z);
    z = "math";
    i = H[z];
    z = "floor";
    O = i[z];
    i, Z, v = O, "math", "table";
    z = H[Z];
    D, Z = "string", "random";
    O = z[Z];
    z = O;
    Z = H[v];
    v = "remove";
    O = Z[v];
    v = H[D];
    D, Z = "char", O;
    O = v[D];
    v = O;
    O = 0;
    D = O;
    O = 2;
    P = O;
    O = {};
    Q = O;
    O = {};
    I, T = O, 1;
    O, M = 0, R;
    R = 1;
    k, n = R, O;
    O = {};
    u, R = O, 0;
    for R = T, M, k do
        T = R;
        O = T;
        u[T] = O;
        T = nil; 
    end;
    repeat
        T, R = nil, Z(u, z(1, #u));
        I[R] = v(R - 1);
        R = nil;
    until #u == 0;
    V, g, l = nil, nil, nil;
    p = nil;
    Q = nil;
    N = nil;
    Z, i, T, o, R, P = nil, nil, "print", nil, "EZPZ", nil;
    F = nil;
    O = H[T];
    A, u = nil, nil;
    m = nil;
    v, D = nil, nil;
    W = nil;
    z = nil;
    y = nil;
    q, C = nil, nil;
    T = O(R);
    L = nil;
    n = nil;
    return; 
end;
F = "unpack";
N = H[F];
U = N;