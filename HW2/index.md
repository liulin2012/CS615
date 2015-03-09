#CS615-HW2 : Software packaging
##lin liu 10397798

###Set the environment
* use root privilege to install some tools

```
# sudo yum install @development-tools
# sudo yum install fedora-packager
# sudo yum install python-devel
```

* create new user

```
# sudo /usr/sbin/useradd makerpm
# sudo usermod -a -G mock makerpm
# sudo passwd makerpm
```

* login in and build the directory tree


```
# su - makerpm
$ rpmdev-setuptree
```

###Build a package


* get the source from the [github](https://github.com/aws/aws-cli) and put it in the ~/rpmbuild/SOURCE directory

```
curl "https://github.com/aws/aws-cli/archive/1.7.12.tar.gz" -o "aws-cli-1.7.12.tar.gz"
```

* edit the .spec file in ~/rpmbuild/SPEC,I have reference the http://download.opensuse.org/update/13.2/src/aws-cli-1.7.1-2.8.1.src.rpm 

```
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
```


* Use rpmbuild with options to test each phase in spec file.

```
rpmbuild -bp
Execute %prep.
rpmbuild -bc
Execute %prep, %build.
rpmbuild -bi
Execute %prep, %build, %install, %check.
rpmbuild -ba
Execute %prep, %build, %install, %check, package, perform all the stages.
Test with rpmlint
Check minor errors in spec file.
```


###Test

* create a new fedora instance and copy the rpm package to the new instance

```
# sudo yum localinstall awscli-1.7.12-1.0.noarch.rpm 
```

![Imgur](http://i.imgur.com/U80UFDk.png)
	
* test the result

```
aws help
aws --version
```

![Imgur](http://i.imgur.com/8r3NfUH.png)

###Reference

* [How to create an RPM package](https://fedoraproject.org/wiki/How_to_create_an_RPM_package)
* [How to create a GNU Hello RPM package](https://fedoraproject.org/wiki/How_to_create_a_GNU_Hello_RPM_package)
* [src.rpm](http://download.opensuse.org/update/13.2/src/aws-cli-1.7.1-2.8.1.src.rpm )

	



