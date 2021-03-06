context("webtests")
test_that("login",{
  expect_s4_class(movebankLogin("asdf","asdf"),"MovebankLogin")
  expect_silent(a<-movebankLogin("asdf","asdf"))
  
  expect_error(movebankLogin("asdf",234))
  expect_error(movebankLogin("asdf",factor("a")))
  expect_error(movebankLogin("asdf",login=234))
  
  })
test_that('false login',{
		  skip_on_os('solaris')
  l<-movebankLogin("asdf","asdf")  
  expect_error(getMovebankStudies(l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankData("BCI Ocelot",login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankStudy("BCI Ocelot",login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankAnimals("BCI Ocelot",login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankSensors("BCI Ocelot",login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankSensors(123413,login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankData(123413,login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankData(123413, animalName=c("Mancha","Yara"), login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankSensorsAttributes(123413, login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  expect_error(getMovebankSensorsAttributes("BCI Ocelot", login=l),"It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available."       )
  })
