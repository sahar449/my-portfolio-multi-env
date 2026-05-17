# Changelog

## 0.1.0 (2026-05-17)


### Features

* add actionlint workflow to lint all GitHub Actions workflows ([b3ce35a](https://github.com/sahar449/my-portfolio-multi-env/commit/b3ce35a2b18f69695fb0401c74ffcebaf88ec716))
* add pyproject.toml and switch release-please to python mode ([827f6f9](https://github.com/sahar449/my-portfolio-multi-env/commit/827f6f9d60d33cce20fdda25526c32b44224102a))
* add release-please workflow for automated versioning ([3918427](https://github.com/sahar449/my-portfolio-multi-env/commit/391842731a3ee7ddbf7a91615fd03c4d40f23f33))
* auto-trigger CD pipeline after infra apply completes ([29a8126](https://github.com/sahar449/my-portfolio-multi-env/commit/29a8126ca918771e96c31c0bca4c19b43a6fca71))
* auto-trigger infra on push to main, add destroy-all workflow ([8ad180f](https://github.com/sahar449/my-portfolio-multi-env/commit/8ad180fc2e7d3b5cafe809b204ec55560b364a21))
* grant admin user EKS access after cluster creation ([c7d81ee](https://github.com/sahar449/my-portfolio-multi-env/commit/c7d81eec412171d3d2141ef11c1c4606a7542dbd))
* rename destroy-all → apply-or-destroy-all, add parallel apply for all envs ([b43f9dd](https://github.com/sahar449/my-portfolio-multi-env/commit/b43f9ddaa9b102e9b0f807241728eab2d5e62863))


### Bug Fixes

* add conftest.py to add service dir to sys.path for unit tests ([9ee6e0b](https://github.com/sahar449/my-portfolio-multi-env/commit/9ee6e0bf1eae8240f650d543495566a5f7371304))
* add environment: staging to ci-staging jobs to access environment secrets ([40b9658](https://github.com/sahar449/my-portfolio-multi-env/commit/40b9658b8d8c3e978881226b3bf91962198ff207))
* add FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 to test workflow ([b5f9e18](https://github.com/sahar449/my-portfolio-multi-env/commit/b5f9e188e60c89ab0cb6b39269d7ba078767e933))
* add workflow_dispatch to staging-ci and fix if condition for manual runs ([3a6f533](https://github.com/sahar449/my-portfolio-multi-env/commit/3a6f5337021eb26916b82cfac8a9f4daa7397eb4))
* make destroy-all resilient — continue if ArgoCD/resources not found ([6f60eb5](https://github.com/sahar449/my-portfolio-multi-env/commit/6f60eb50013560432ed94995a67bd1d80862ea16))
* make RDS instance identifier and security group name unique per environment ([4757d51](https://github.com/sahar449/my-portfolio-multi-env/commit/4757d515df7d20bd002af01a60d2a80a52dcc7de))
* move FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 to top-level env in staging-ci ([a610419](https://github.com/sahar449/my-portfolio-multi-env/commit/a610419317443cbef54771ffbffac2f6992d9fd3))
* patch Trivy CVEs + add E2E tests to staging CD ([55821b4](https://github.com/sahar449/my-portfolio-multi-env/commit/55821b46fefbb16a57d17d160dab64ea9c0475fb))
* prevent duplicate IAM/RDS resource creation across environments ([ed7664f](https://github.com/sahar449/my-portfolio-multi-env/commit/ed7664fc9a5202f9f30183df3fb81d523d3806eb))
* proper destroy order in destroy-all — delete ArgoCD apps first ([d90f6e1](https://github.com/sahar449/my-portfolio-multi-env/commit/d90f6e1e9015b694522105356ce27396a5e80f49))
* remove environment protection from infra workflows ([c739020](https://github.com/sahar449/my-portfolio-multi-env/commit/c739020d3f8874454b8121341e7b51ac7566558d))
* resolve actionlint warnings across workflows ([5acaa74](https://github.com/sahar449/my-portfolio-multi-env/commit/5acaa7481cde7b2c3db9d55b56a170ea023d445b))
* run unit tests from service directory to resolve import error ([9decf14](https://github.com/sahar449/my-portfolio-multi-env/commit/9decf146120b4fc53e59b79f4ed8fd1c38b4f582))
* skip PR creation when dev and staging are already in sync ([f6bba62](https://github.com/sahar449/my-portfolio-multi-env/commit/f6bba6293cb4322cdadedf4c789dafc197c5946b))
* sync conftest.py to dev ([c7d103b](https://github.com/sahar449/my-portfolio-multi-env/commit/c7d103be801949cb5a5275b3c0adf5845240724a))
* sync dev-ci PR skip logic to dev ([eb79b7b](https://github.com/sahar449/my-portfolio-multi-env/commit/eb79b7bbea050ddf082b4b13b380f9094b52ff05))
* sync unit test files to dev branch ([8b1f55c](https://github.com/sahar449/my-portfolio-multi-env/commit/8b1f55ca9d47326f6b683fa5dbaeeb06dcb20aa2))
* sync unit test working-directory fix to dev ([8a6f000](https://github.com/sahar449/my-portfolio-multi-env/commit/8a6f00023f18c467d229004be7c19ecfa0279d08))
* use os.path.abspath in conftest.py for reliable sys.path resolution ([b7d0287](https://github.com/sahar449/my-portfolio-multi-env/commit/b7d0287ca682dc1feaa502b26c6be4499827097a))
* use os.path.abspath in conftest.py for reliable sys.path resolution ([b877586](https://github.com/sahar449/my-portfolio-multi-env/commit/b87758670e44e5997dd077c0586e6bddc16b89cf))
* wait for ArgoCD LB hostname + opt into Node.js 24 across all workflows ([47af7f1](https://github.com/sahar449/my-portfolio-multi-env/commit/47af7f17e23429121c16824ea924136675b4f5af))


### Reverts

* remove access_config from EKS module to prevent forced cluster recreation ([7e29d67](https://github.com/sahar449/my-portfolio-multi-env/commit/7e29d679df520bf7b15f4de3e355c49fe0ff9ff3))
