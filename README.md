![](https://cloud.githubusercontent.com/assets/110953/7877439/6a69d03e-0590-11e5-9fac-c614246606de.png)
## Traffic Seed App

## Getting Started

To take advantage of Traffic Seed App you need to:

1. Get a copy of the code.
2. Install the dependencies if you don't already have them.
3. Modify the application to your liking.
4. Add UAA Support.
5. Deploy your code to Predix, Cloud Foundry.

### Get the code

Get the code from the following git location:
[Download](https://github.com/CurrentByGE/TrafficSeedApp)

### Install dependencies

#### Quick-start (for experienced users)

With Node.js installed, , run the following one liner from the root of your seed app download:

```sh
npm install -g gulp bower && npm install && bower install
```

#### Prerequisites (for everyone)

The full starter kit requires the following major dependencies:

- Node.js, used to run JavaScript tools from the command line.
- npm, the node package manager, installed with Node.js and used to install Node.js packages.
- gulp, a Node.js-based build tool.
- bower, a Node.js-based package manager used to install front-end packages (like Polymer).

**To install dependencies:**

1)  Check your Node.js version.

```sh
node --version
```

The version should be at or above 0.12.x.

2)  If you don't have Node.js installed, or you have a lower version, go to [nodejs.org](https://nodejs.org) and click on the big green Install button.

3)  Install `gulp` and `bower` globally.

```sh
npm install -g gulp bower
```

This lets you run `gulp` and `bower` from the command line.

4)  Once the node, bower and gulp are installed, run the below commands to add the node_modules and bower_components dependencies.

```sh
npm install
bower install
```

This installs all the element sets and tools required to build and serve apps.

### Browser Support
The traffic seed app is currently supported in Google Chrome 40.x.x and above.

### Development workflow

#### Serve / watch (Local Testing)

```sh
gulp serve
```

This outputs an IP address you can use to locally test and another that can be used on devices connected to your network.

#### Build (Create a dist version)

```sh
gulp
```

Build and optimize the current project, ready for deployment. This includes linting as well as image, script, stylesheet and HTML optimization and minification.

### Predix Platform and Cloud Foundry
Traffic Seed App is using Predix Platform and Cloud Foundry to push the application to cloud. If you do not have account created in Predix, please click [here](https://www.predix.io/) to create one.

For more information on using Predix platform and Cloud Foundry, check [this](https://predix-io.run.asv-pr.ice.predix.io/resources) website.

## Setup services for your own development
Once you're ready to actually start developing, you'll need to setup your own [UAA service](https://predix-io.run.asv-pr.ice.predix.io/docs/?b=#X9M7hYj6). For ease of use, use the [Predix Starter Kit](https://predix-starter.run.aws-usw02-pr.ice.predix.io/) to create users, groups and password.

### Service Reference
Once the UAA setup is done, you will have to get the service reference to be used in manifest.yml. To get the details of available microservices from Cloud Foundry, follow the steps on [this](https://www.predix.io/docs/?r=250183#XpKGAdQ7-Q0CoIStl) link.

#### ie-traffic service
For Traffic Seed App, the ie-traffic microservice is used which can be found in cf marketplace as mentioned in section 'Service Reference'. For more information on usage of the microservice, please visit the following urls:

  1. [Intelligent Environments Overview](https://currentbyge.github.io/GE_Current_Documentation/#c_about_intelligent_environments.html)
  2. [General APIs](https://currentbyge.github.io/GE_Current_Documentation/#c_overview_of_general_apis.html)

  3. [Intelligent Cities APIs](https://currentbyge.github.io/GE_Current_Documentation/#c_overview_of_intelligent_cities_apis.html)

### Redis
Create a Redis instance, which is used by nginx for storing your session.
```
cf cs redis <plan> <instance_name>
```

### Update manifest.yml
You'll need to change these fields (pulled from [VCAP_SERVICES](https://www.predix.io/docs#X9M7hYj6)) in your manifest.yml before pushing to the cloud.
```
  - name: traffic-seed-app # change this to your application name
    services:
            - your_redis_instance # change this to your redis service instance name
            - your_view_service_instance # change this to your view service instance name
    env:
      UAA_CLIENT_CREDENTIALS: "Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=" # change it to your client_id:client_secret base 64 encoded string
      RESOURCE_URL: https://your-servive-url.run.aws-usw02-pr.ice.predix.io # change to your api resource url which can be found in Cloud Foundry marketplace
      UAA_URI: https://your-uaa-uri.predix-uaa.run.aws-usw02-pr.ice.predix.io # change to your UAA uri shown in VCAP services
      UAA_CLIENT_ID: client_id # change it to your client id
      ASSET_ZONE_ID: zone_id # change to your zone id shown in VCAP services
```

### Update nginx.conf
You need to make sure that nginx.conf (in the root folder which gets copied into dist) has references to the RESOURCE_URL and ASSET_ZONE_ID which is whatever you specified in 'Update manifest.yml' section.
```
# for example,
set $user_token "";
location /services/ {
  # Code executed for all on /service
  access_by_lua_file '<%=ENV["APP_ROOT"]%>/nginx/scripts/set_access_token.lua';
  proxy_set_header Authorization $user_token;
  proxy_set_header Predix-Zone-Id <%=ENV["ASSET_ZONE_ID"]%>; # it uses the ASSET_ZONE_ID you have set in 'Update manifest.yml' section
  proxy_set_header accept application/hal+json;
  rewrite  /services/(.*) /$1 break;
  proxy_pass "<%=ENV["RESOURCE_URL"]%>"; # it uses the RESOURCE_URL you have set in 'Update manifest.yml' section
}
```

## Deployment to Predix, Cloud Foundry

Once gulp is used to Build and optimize the current project, it becomes ready for deployment.

Please go on the below link to get detailed information about predix.io and Cloud Foundry deployment.
[Deployment to Predix, Cloud Foundry](https://www.predix.io/docs#Uva9INX3)

### Push to the cloud.
User the below cloud foundry command to push the app to cloud.
```
cf push
```

### Accessing the Application

Once the cf push is successful, it will output the similar result as below:
```
Showing health and status for app <traffic-seed-app> in org your-organization-name / space <your-space> as user.id@ge.com...
OK

requested state: started
instances: 1/1
usage: 64M x 1 instances
urls: traffic-seed-app.run.aws-usw02-pr.ice.predix.io
last uploaded: Tue May 4 21:32:28 UTC 2016
stack: <stack name>
buildpack: <predix_openreg_buildpack>

     state     since                    cpu    memory         disk           details   
#0   running   2016-05-04 02:32:54 PM   0.0%   32.7M of 64M   137.6M of 1G     
```

Use the 'urls: traffic-seed-app.run.aws-usw02-pr.ice.predix.io' part from above output as the application login url by appending /login at the end.
So, based on above result, the url to access application will be:
```
https://traffic-seed-app.run.aws-usw02-pr.ice.predix.io/login
```
In your case it will be
```
https://<your-app-name>.run.aws-usw02-pr.ice.predix.io/login
```
It will take you to the predix login page where you have to use the user id and password created from [UAA service](https://predix-io.run.asv-pr.ice.predix.io/docs/?b=#X9M7hYj6) step. Once you login, it will take you to Traffic Seed App page.

## Application Theming & Styling

Polymer 1.0 introduces a shim for CSS custom properties. We take advantage of this in `app/styles/app-theme.html` to provide theming for your application. You can also find our presets for Material Design breakpoints in this file.

[Read more](https://www.polymer-project.org/1.0/docs/devguide/styling.html) about CSS custom properties.

### Styling
1. ***main.css*** - to define styles that can be applied outside of Polymer's custom CSS properties implementation. Some of the use-cases include defining styles that you want to be applied for a splash screen, styles for your application 'shell' before it gets upgraded using Polymer or critical style blocks that you want parsed before your elements are.
2. ***app-theme.html*** - to provide theming for your application. You can also find our presets for Material Design breakpoints in this file.
3. ***shared-styles.html*** - to shared styles between elements and index.html.
4. ***element styles only*** - styles specific to element. These styles should be inside the `<style></style>` inside `template`.

  ```HTML
  <dom-module id="my-list">
    <template>
      <style>
        :host {
          display: block;
          background-color: yellow;
        }
      </style>
      <ul>
        <template is="dom-repeat" items="{{items}}">
          <li><span class="paper-font-body1">{{item}}</span></li>
        </template>
      </ul>
    </template>
  </dom-module>
  ```

These style files are located in the [styles folder](app/styles/).

## Unit Testing

Web apps built with Polymer Starter Kit come configured with support for [Web Component Tester](https://github.com/Polymer/web-component-tester) - Polymer's preferred tool for authoring and running unit tests. This makes testing your element based applications a pleasant experience.

[Read more](https://github.com/Polymer/web-component-tester#html-suites) about using Web Component tester.

## Dependency Management

Polymer uses [Bower](http://bower.io) for package management. This makes it easy to keep your elements up to date and versioned. For tooling, we use npm to manage Node.js-based dependencies.

## Service Worker

Polymer Starter Kit offers an optional offline experience thanks to Service Worker and the [Platinum Service Worker elements](https://github.com/PolymerElements/platinum-sw). New to Service Worker? Read the following [introduction](http://www.html5rocks.com/en/tutorials/service-worker/introduction/) to understand how it works.

Our optional offline setup should work well for relatively simple applications. For more complex apps, we recommend learning how Service Worker works so that you can make the most of the Platinum Service Worker element abstractions.

### Enable Service Worker support?

To enable Service Worker support for Polymer Starter Kit project use these 3 steps:

1. Uncomment Service Worker code in index.html
  ```HTML
  <!-- Uncomment next block to enable Service Worker support (1/2) -->
  <!--
  <paper-toast id="caching-complete"
               duration="6000"
               text="Caching complete! This app will work offline.">
  </paper-toast>

  <platinum-sw-register auto-register
                        clients-claim
                        skip-waiting
                        on-service-worker-installed="displayInstalledToast">
    <platinum-sw-cache default-cache-strategy="networkFirst"
                       precache-file="precache.json">
    </platinum-sw-cache>
  </platinum-sw-register>
  -->
  ```
2. Uncomment Service Worker code in elements.html

  ```HTML
  <!-- Uncomment next block to enable Service Worker Support (2/2) -->
  <!--
  <link rel="import" href="../bower_components/platinum-sw/platinum-sw-cache.html">
  <link rel="import" href="../bower_components/platinum-sw/platinum-sw-register.html">
  -->
  ```
3. Uncomment 'cache-config' in the `runSequence()` section of the 'default' gulp task, like below:
[(gulpfile.js)](https://github.com/PolymerElements/polymer-starter-kit/blob/master/gulpfile.js)

  ```JavaScript
  // Build Production Files, the Default Task
  gulp.task('default', ['clean'], function (cb) {
    runSequence(
      ['copy', 'styles'],
      'elements',
      ['jshint', 'images', 'fonts', 'html'],
      'cache-config',
      cb);
  });
  ```

#### Filing bugs in the right place

If you experience an issue with Service Worker support in your application, check the origin of the issue and use the appropriate issue tracker:

* [sw-toolbox](https://github.com/GoogleChrome/sw-toolbox/issues)
* [platinum-sw](https://github.com/PolymerElements/platinum-sw/issues)
* [platinum-push-notifications-manager](https://github.com/PolymerElements/push-notification-manager/)
* For all other issues, feel free to file them [here](https://github.com/polymerelements/polymer-starter-kit/issues).

#### I get an error message about "Only secure origins are allowed"

Service Workers are only available to "secure origins" (HTTPS sites, basically) in line with a policy to prefer secure origins for powerful new features. However http://localhost is also considered a secure origin, so if you can, developing on localhost is an easy way to avoid this error. For production, your site will need to support HTTPS.

#### How do I debug Service Worker?

If you need to debug the event listener wire-up use `chrome://serviceworker-internals`.

#### What are those buttons on chrome://serviceworker-internals?

This page shows your registered workers and provides some basic operations.

* Unregister: Unregisters the worker.
* Start: Starts the worker. This would happen automatically when you navigate to a page in the worker's scope.
* Stop: Stops the worker.
* Sync: Dispatches a 'sync' event to the worker. If you don't handle this event, nothing will happen.
* Push: Dispatches a 'push' event to the worker. If you don't handle this event, nothing will happen.
* Inspect: Opens the worker in the Inspector.

#### Development flow

In order to guarantee that the latest version of your Service Worker script is being used, follow these instructions:

* After you made changes to your service worker script, close all but one of the tabs pointing to your web application
* Hit shift-reload to bypass the service worker as to ensure that the remaining tab isn't under the control of a service worker
* Hit reload to let the newer version of the Service Worker control the page.

If you find anything to still be stale, you can also try navigating to `chrome:serviceworker-internals` (in Chrome), finding the relevant Service Worker entry for your application and clicking 'Unregister' before refreshing your app. This will (of course) only clear it from the local development machine. If you have already deployed to production then further work will be necessary to remove it from your user's machines.

#### Disable Service Worker support after you enabled it

If for any reason you need to disable Service Worker support after previously enabling it, you can remove it from your Polymer Starter Kit project using these 4 steps:

1. Remove references to the platinum-sw elements from your application [index](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/index.html).
2. Remove the two Platinum Service Worker elements (platinum-sw/..) in [app/elements/elements.html](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/elements/elements.html)
3. Remove 'precache' from the list in the 'default' gulp task ([gulpfile.js](https://github.com/PolymerElements/polymer-starter-kit/blob/master/gulpfile.js))
4. Navigate to `chrome://serviceworker-internals` and unregister any Service Workers registered by Polymer Starter Kit for your app just in case there's a copy of it cached.

## Yeoman support

[generator-polymer](https://github.com/yeoman/generator-polymer/releases) now includes support for Polymer Starter Kit out of the box.

## Frequently Asked Questions

### Where do I customise my application theme?

Theming can be achieved using [CSS Custom properties](https://www.polymer-project.org/1.0/docs/devguide/styling.html#xscope-styling-details) via [app/styles/app-theme.html](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/styles/app-theme.html).
You can also use `app/styles/main.css` for pure CSS stylesheets (e.g for global styles), however note that Custom properties will not work there under the shim.

A [Polycast](https://www.youtube.com/watch?v=omASiF85JzI) is also available that walks through theming using Polymer 1.0.

### Where do I configure routes in my application?

This can be done via [`app/elements/routing.html`](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/elements/routing.html). We use Page.js for routing and new routes
can be defined in this import. We then toggle which `<iron-pages>` page to display based on the [selected](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/index.html#L105) route.

### Why are we using Page.js rather than a declarative router like `<more-routing>`?

`<more-routing>` (in our opinion) is good, but lacks imperative hooks for getting full control
over the routing in your application. This is one place where a pure JS router shines. We may
at some point switch back to a declarative router when our hook requirements are tackled. That
said, it should be trivial to switch to `<more-routing>` or another declarative router in your
own local setup.

### Where can I find the application layouts from your Google I/O 2015 talk?

App layouts live in a separate repository called [app-layout-templates](https://github.com/PolymerElements/app-layout-templates).
You can select a template and copy over the relevant parts you would like to reuse to Polymer Starter Kit.

You will probably need to change paths to where your Iron and Paper dependencies can be found to get everything working.
This can be done by adding them to the [`elements.html`](https://github.com/PolymerElements/polymer-starter-kit/blob/master/app/elements/elements.html) import.

### Something has failed during installation. How do I fix this?

Our most commonly reported issue is around system permissions for installing Node.js dependencies.
We recommend following the [fixing npm permissions](https://github.com/sindresorhus/guides/blob/master/npm-global-without-sudo.md)
guide to address any messages around administrator permissions being required. If you use `sudo`
to work around these issues, this guide may also be useful for avoiding that.

If you run into an exception that mentions five optional dependencies failing (or an `EEXIST` error), you
may have run into an npm [bug](https://github.com/npm/npm/issues/6309). We recommend updating to npm 2.11.0+
to work around this. You can do this by opening a Command Prompt/terminal and running `npm install npm@2.11.0 -g`. If you are on Windows,
Node.js (and npm) may have been installed into `C:\Program Files\`. Updating npm by running `npm install npm@2.11.0 -g` will install npm
into `%AppData%\npm`, but your system will still use the npm version. You can avoid this by deleting your older npm from `C:\Program Files\nodejs`
as described [here](https://github.com/npm/npm/issues/6309#issuecomment-67549380).

If the issue is to do with a failure somewhere else, you might find that due to a network issue
a dependency failed to correctly install. We recommend running `npm cache clean` and deleting the `node_modules` directory followed by
`npm install` to see if this corrects the problem. If not, please check the [issue tracker](https://github.com/PolymerElements/polymer-starter-kit/issues) in case
there is a workaround or fix already posted.

### How do I add new JavaScript files to Starter Kit so they're picked up by the build process?

At the bottom of `app/index.html`, you will find a build block that can be used to include additional
scripts for your app. Build blocks are just normal script tags that are wrapped in a HTML
comment that indicates where to concatenate and minify their final contents to.

Below, we've added in `script2.js` and `script3.js` to this block. The line
`<!-- build:js scripts/app.js -->` specifies that these scripts will be squashed into `scripts/app.js`
during a build.

```html
<!-- build:js scripts/app.js -->
<script src="scripts/app.js"></script>
<script src="scripts/script2.js"></script>
<script src="scripts/script3.js"></script>
<!-- endbuild-->
```

If you are not using the build-blocks, but still wish for additional files (e.g scripts or stylesheets) to be included in the final `dist` directory, you will need to either copy these files as part of the gulpfile.js build process (see the `copy` task for how to automate this) or manually copy the files.

### I'm finding the installation/tooling here overwhelming. What should I do?

Don't worry! We've got your covered. Polymer Starter Kit tries to offer everything you need to build and optimize your apps for production, which is why we include the tooling we do. We realise however that our tooling setup may not be for everyone.

If you find that you just want the simplest setup possible, we recommend using Polymer Starter Kit light, which is available from the [Releases](https://github.com/PolymerElements/polymer-starter-kit/releases) page. This takes next to no time to setup.

## Contributing

Polymer Starter Kit is a new project and is an ongoing effort by the Web Component community. We welcome your bug reports, PRs for improvements, docs and anything you think would improve the experience for other Polymer developers.
