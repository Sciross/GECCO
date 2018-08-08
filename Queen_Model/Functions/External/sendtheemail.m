function sendtheemail(addressee,subject,body);

setpref('Internet','E_mail','rossdmw@gmail.com');
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username','rossdmw@gmail.com');
setpref('Internet','SMTP_Password','tlzvxswqzuoxbfye');

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

sendmail(addressee,subject,body);

end
