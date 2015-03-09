Name:           aws-cli
Version:        1.7.12
Release:        1%{?dist}
Summary:        Amazon Web Services Command Line Interface
License:        Apache-2.0
Group:          Applications/System
Url:            https://github.com/aws/aws-cli
Source0:        %{name}-%{version}.tar.gz
Requires:       python
Requires:       python-pip
BuildRequires:  python
BuildRequires:  python-devel
BuildRequires:  python-setuptools
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services. With just one tool to download and configure, you can control multiple AWS services from the command line and automate
them through scripts.

%prep
%setup -q

%build
python setup.py build

%install
python setup.py install --prefix=%{_prefix} --root=%{buildroot} --install-scripts=%{_bindir}
# No DOS crap
rm %{buildroot}/%{_bindir}/aws.cmd
chmod a+x %{buildroot}/%{python_sitelib}/awscli/paramfile.py

%post
pip install botocore
pip install rsa
pip install bcdoc
pip install colorama
pip install docutils

%files
%defattr(-,root,root,-)
%doc CHANGELOG.rst LICENSE.txt README.rst
%dir %{python_sitelib}/awscli
%dir %{python_sitelib}/awscli-%{version}-py%{python_version}.egg-info
%{_bindir}/*
%{python_sitelib}/awscli/*
%{python_sitelib}/*egg-info/*
