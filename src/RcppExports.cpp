// This file was generated by Rcpp::compileAttributes
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// llBGBvarRcpp
NumericVector llBGBvarRcpp(NumericMatrix sigm, NumericMatrix paraOrth);
RcppExport SEXP move_llBGBvarRcpp(SEXP sigmSEXP, SEXP paraOrthSEXP) {
BEGIN_RCPP
    Rcpp::RObject __result;
    Rcpp::RNGScope __rngScope;
    Rcpp::traits::input_parameter< NumericMatrix >::type sigm(sigmSEXP);
    Rcpp::traits::input_parameter< NumericMatrix >::type paraOrth(paraOrthSEXP);
    __result = Rcpp::wrap(llBGBvarRcpp(sigm, paraOrth));
    return __result;
END_RCPP
}
