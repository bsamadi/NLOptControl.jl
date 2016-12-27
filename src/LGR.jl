"""
τ,ω,I,D = LGR(10);
--------------------------------------------------------------------------\n
Last modifed on December 23, 2016 by Huckleberry Febbo\n
Original Author: Jiechao Liu, University of Michigan\n
Original Function Name: LGR_Nodes.m  |  Source: OCOA_150312\n
--------------------------------------------------------------------------\n
# Input Arguments
* `N::Integer`:  number of colocation points
# Output Arguments
* `D::Array{Float64,2}`: Radau Psueudospectral Differention Matrix
     * N X (N + 1) non-square matrix
     * Has one more column than row because the of the Lagrange Polynomial associated with the non-collocated point at τ₀ = -1
     * non-singular
     * integration is exact for polynomials of degree 2N - 2 [more info here](http://users.clas.ufl.edu/hager/papers/Control/unified.pdf)

LGR points:

 * roots of: ``P{N-1}(τ)+P_{N}(τ)``
 * exact for polynomials with: ``degree <= 2N-2``
"""
function LGR(N::Int64)
  # The Legendre Vandermonde Matrix
  P	= zeros(N,N+1);
  # row i: x(i)
  # col j: P_{j-1}(x(i))

  # initial guess
  xn	= - cos(2*pi*(0:(N-1))/(2*(N-1)+1))'; # new x

  # any number larger than 1 to initialize the while() loop
  xo	= 2; # old x

  # Newton-Raphson method
  while maximum(abs(xn - xo)) > eps()*10
      xo = xn;
      Pvec = [0:N];       # initialize the P matrix
      for idx = 1:N+1
        P[1,idx]    	= (-1)^Pvec[1][idx];
      end
      P[2:N,1] 	= 1;
      P[2:N,2]  	= xn[2:N];
      # use Bonnet�s recursion formula to complete the P matrix
      for i = 2:N
          P[2:N,i+1] = ((2*i-1)*xn[2:N].*P[2:N, i] - (i-1)*P[2:N, i-1])/ i;
      end
      FCN         =    P[2:N, N+1] + P[2:N, N];
      DER         = N*(P[2:N, N+1] - P[2:N, N])./(xo[2:N] - 1);
      xn[2:N]  	= xo[2:N] - FCN ./ DER;
  end
  TAU = xn;

  # The LGR Weights
  WEIGHT = Array(Float64,1, N)
  WEIGHT[1]    	= 2/N^2;
  #WEIGHT[2:N]     = (1-TAU[2:N])./(N*P[2:N,N]).^2; #TODO seems like an error here --> report it
  WEIGHT[2:N] = 1./((1-TAU[2:N]).*(lepoly(N,TAU[2:N],true)[1]).^2);
  # The Barycentric weights used to calculate the differentiation matrix
  temp = append!(TAU[1:N],1.0);
  M               = length(temp);
  Y               = repmat(temp,1,M);
  YDIFF           = Y - Y' + eye(M);
  BW              = repmat(1./prod(YDIFF,1),M,1);
  # TODO check above with this http://jiao.ams.sunysb.edu/teaching/ams527_spring15/lectures/BarycentricLagrange.pdf



  # The LGR differentiation matrix N x (N + 1)
  DMAT           	= BW./(BW'.*YDIFF');
  DMAT[1:M+1:M*M]	= sum(1./YDIFF, 1) - 1;
  DMAT           	= DMAT[1:N,:];

  # The LGR integration matrix
  IMAT         	= inv(DMAT[:,2:N+1]);

  τ = [TAU[1:N]; 1];  # append +1 on the end
  ω = WEIGHT[1:N];
  I = IMAT;
  D = DMAT;
  return τ,ω,I,D
end