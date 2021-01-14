variable "api_gateway_key" {
  description = "Key for API Gateway"
  type        = string
}
variable "api_gateway_rest_api" {
  description = "Name of API gateway Rest API"
  type        = string
}
variable "stage_name" {
  type        = string
  default     = ""
  description = "The name of the stage. If the specified stage already exists, it will be updated to point to the new deployment. If the stage does not exist, a new one will be created and point to this deployment."
}
variable "domain_name" {
    type = string
    default = ""
}
variable "cert_description" {
    type = string
    default = ""
}
variable "path_parts" {
  type        = list
  default     = []
  description = "The last path segment of this API resource."
}
variable "http_methods" {
  type        = list
  default     = []
  description = "The HTTP Method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY)."
}
variable "authorizations" {
  type        = list
  default     = []
  description = "The type of authorization used for the method (NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS)."
}
variable "integration_types" {
  type        = list
  default     = []
  description = "The integration input's type. Valid values are HTTP (for HTTP backends), MOCK (not calling any real backend), AWS (for AWS services), AWS_PROXY (for Lambda proxy integration) and HTTP_PROXY (for HTTP proxy integration). An HTTP or HTTP_PROXY integration with a connection_type of VPC_LINK is referred to as a private integration and uses a VpcLink to connect API Gateway to a network load balancer of a VPC."
}
variable "variables" {
  type        = map
  default     = {}
  description = "A map that defines variables for the stage. ex: 'answer' = '42'"
}
variable "custom_domain_enabled" {
  type = bool  
  default = false
}
variable "regional_aws_acm_certificate_arn" {
  default = ""
}
variable "aws_route53_zone_id" {
  default = -1
}
variable "response_types" {
  type        = list
  default     = []
  description = "The response type of the associated GatewayResponse."
}
variable "gateway_status_codes" {
  type        = list
  default     = []
  description = "The HTTP status code of the Gateway Response."
}
variable "gateway_response_templates" {
  type        = list
  default     = []
  description = "A map specifying the parameters (paths, query strings and headers) of the Gateway Response."
}
variable "gateway_response_parameters" {
  type        = list
  default     = []
  description = "A map specifying the templates used to transform the response body."
}
variable "cache_key_parameters" {
  type        = list
  default     = []
  description = "A list of cache key parameters for the integration."
}
