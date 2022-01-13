# IoT-Sauna-Notifications

## Motivation

I have a sauna and I use it often. However, I have a problem with overheating it as my focus
gets very involved in doing something and I forget when I turned the sauna on or just forget
to check the clock. Using timers is an extra action step and often I’m lazy about setting one
up. Many people have the same issue. Some people continuously physically go and check
the temperature of their sauna.

Thus, the purpose of this Internet of Things (IoT) project is to offer a more efficient and
automatic solution to finding out the temperature in the sauna and knowing exactly when it’s
high enough to enter.

The goal was to have a temperature sensor and a low cost, low power usage system capable
of transmitting the temperature data in the sauna. On the receiving end there is a mobile
application in which the user can set their desired temperature at which they wish to enter
the sauna.


## Design and Architecture


#### _Figure 1: Overall architecture_
![Overall architecture](https://raw.githubusercontent.com/VilleKylmamaa/IoT-Sauna-Notifications/main/readme_images/overall-architecture.jpg)

There are two main issues about having electronics in the sauna environment – heat and
humidity. The temperature sensor needs to be placed high, close to the ceiling, where the
heat and the moisture is the highest. The heat can go even over 100°C with the absolute
maximum usually being around 110°C to 120°C. Some electronics and batteries can’t
operate at temperatures this high. The humidity is also very high in a sauna where water is
thrown on the rocks producing steam. This can cause for example short circuits and
corrosion.

For the heat, every component in the system needs to have a high enough operating
temperature. For the moisture, the electronics should have a conformal coating and the
whole system should be enclosed in plastic or some other fitting material. Such enclosure
to protect from humidity has been achieved for example in the RuuviTag product [1], so it is
a proven concept.

Users generally wish to switch batteries as rarely as possible and the enclosing might make
changing the batteries harder. For these reasons, the battery life of the system should be
maximized. Luckily, given that the temperature in the sauna rises slowly, the transmission
of the data doesn’t need to be very frequent. Transmitting just the temperature is also a very
small amount of data. This means that the extremely low power usage Bluetooth Low Energy
(BLE) can be used for this project.

Furthermore, the user should always be home when the sauna is on, provided that they are
following proper safety guidelines. This means that there is little reason for another entity in
the architecture in-between the microcontroller and the mobile device. Thus, the overall
architecture is simply just the microcontroller and the temperature sensor in the sauna
which, using BLE, will connect straight to the mobile device.

On the mobile application the main functionalities are to be able to view the current
temperature and to choose a temperature at which the application will send a push
notification. There is also a graph which visualizes the temperature data and the chosen
notification temperature.



## Implementation

For the temperature sensor, I used AM2302 DHT22 because of its availability and still low
cost. It can also measure humidity, and thus lower cost would be possible with another
sensor that measures just temperature. It gives accurate readings from -40°C to +80°C.
While the temperature in sauna can go higher, most users prefer entering sauna in-between
+40°C to +80°C, and the accuracy isn’t very critical over 80°C even when you’re looking for
slightly hotter sauna. A cheaper DHT11 model exists but it is advertised as good for only
0°C to +50°C temperatures which isn’t enough for a sauna.

For the microcontroller, I used ESP32 because of its low price, low power usage, BLE
capabilities, and operating temperature of -40°C to +125°C.

As discussed in the previous section, I chose BLE due to its low power consumption and
because a very small amount of data is transferred with low frequency.

I decided to program the mobile application using Flutter. Flutter
is an open-source software development kit developed by
Google which natively compiles for multiple platforms from a
single codebase. The platforms being Android, iOS, Web, Linux,
Windows, Mac and Google Fuchsia. Flutter achieves near native
performance and if a simple application like this was a few
percentage points worse than the exact same app programmed
natively, it would be unnoticeable to the user. Thus, Flutter is a
great tool to quickly produce simple applications like this for
multiple platforms.

#### _Figure 2: Mobile application screen_
![Mobile application screen](https://github.com/VilleKylmamaa/IoT-Sauna-Notifications/blob/main/readme_images/mobile-application-screenshot.jpg)

The mobile application (figure 2, on the right) shows the current
temperature in the sauna, it has a slider with which the user
chooses the notification temperature, and a graph to visualize
the temperature data. There is also a horizontal line in the graph
which shows the chosen temperature notification threshold.

However, I didn’t implement the encasing for the system in the sauna. This was mainly
because I was unsure about how to do it right and I wanted to keep my components for
testing out other projects. I also focused my extra effort elsewhere, the mobile application
and alternative solutions.

#### _Figure 3: Test Setup_
![Mobile application screen](https://raw.githubusercontent.com/VilleKylmamaa/IoT-Sauna-Notifications/main/readme_images/test-setup.jpg)

Instead, I had the ESP32 outside the bathroom and only the AM2302 DHT22 sensor in the
sauna. I connected them with some long wiring and powered the ESP32 with a phone
charger to avoid having to use batteries. This was sufficient for all the testing the project
required.

Here is a link to a short video showcasing the functionality:
https://www.youtube.com/watch?v=S2CG0rvZlv0



## Evaluation of the Work

I’m very pleased that I could quickly learn and develop an application with Flutter with zero
prior experience. I didn’t find it easy however. The connection for the BLE, the push
notifications and the graph were surprisingly difficult to get to work properly.

The biggest deficiency in the implementation is obviously the lack of encasing for the sensor,
ESP32 and battery. In addition to the reasons mentioned in the Implementation section, I
also considered the focus of the course to be on other aspects of the project. Especially the
connectivity since that is mainly what makes IoT special. I directed my extra effort on testing
out all the connectivity options the ESP32 is capable of: Wi-Fi, Bluetooth (classic) and BLE.
The BLE was the hardest one to get working with Flutter as there is comparatively less
documentation and fewer similar projects made as with the two other options.

For the Wi-Fi version, I also implemented a different kind of client: a Telegram bot. Telegram
is a cloud-based mobile and desktop app for which there exists bot support, including an
official bot API.

#### _Figure 4: Telegram bot client_
![Mobile application screen](https://github.com/VilleKylmamaa/IoT-Sauna-Notifications/blob/main/readme_images/telegram-bot.jpg)

This Telegram bot was only possible with Wi-Fi. This is because the device needs to be able
to send HTTP requests to the bot API which isn’t feasible with Bluetooth without another
device sending the HTTP requests.

This implementation has the advantage that the mobile device doesn’t have to be connected
to the ESP32 at all and there is no need to create a new application. You will also receive
messages from it no matter how far away from home you are.

However, this Telegram bot isn’t the best solution because Wi-Fi has much higher power
usage than BLE and you shouldn’t need to know the temperature in your sauna if you’re not
home. Another downside is that it’s not a reasonable solution for receiving continuous data
about the temperature because it would continuously spam the user with Telegram
messages. For this reason, it should only send a message when the desired temperature
has been reached, and perhaps send a summary of recent temperature data when the user
gives a command to the bot. Regardless, I chose the BLE implementation as the main
solution.

One of the main limitation of the BLE design I would consider to be the range. Its max range is
around 100 meters in a free field but I have heard accounts from people with big houses
where the range might not reach everywhere with similar products.

