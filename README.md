# OnionRV
OS Miyoo Mini+
<p>&nbsp;</p>

# <img alt="Onion" src="https://user-images.githubusercontent.com/44569252/179510333-40793fbc-f2a3-4269-8ab9-569b191d423f.png" width="196px">

*Усовершенствованная операционная система для вашего Miyoo Mini и Mini+, включающая в себя тонко настроенную эмуляцию с более чем 100 встроенными эмуляторами, автоматическое сохранение и возобновление работы, множество возможностей настройки и многое другое. Производительная, надежная и простая ретро-игра прямо у вас в кармане.*

<p>&nbsp;</p>

## Сборка OnionOS

Обновление репозиторий и установка пакетов
```bash
sudo su
apt update
apt list --upgradable
apt install git
apt install make
snap install docker
```

Загрузка исходного кода

```bash
git clone https://github.com/belmix/OnionRV.git
```

Компиляция

```bash
cd OnionRV/
make git-submodules
sudo chmod 666 /var/run/docker.sock
make with-toolchain or make with-toolchain CMD=dev
```

Готово!
