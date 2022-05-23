![Huginn](https://raw.github.com/huginn/huginn/master/media/huginn-logo.png "Your agents are standing by.")

-----

## Huginn

Huginn is a system for building agents that perform automated tasks for you online.  They can read the web, watch for events, and take actions on your behalf. Huginn's Agents create and consume events, propagating them along a directed graph.  Think of it as a hackable version of IFTTT or Zapier on your own server. You always know who has your data.  You do.

![the origin of the name](https://raw.githubusercontent.com/huginn/huginn/master/doc/imgs/the-name.png)

# Huginn: Lite
This repository is break from the main repository. We implement here only core functionalities, with 21 basic agents that don't rely on anything but standard libs:

* Data Fetching
  * HTTP Status: Make a HTTP call, and return the Status header
  * Post: Make a HTTP call and return response
  * Website: Parse and extract data from a website

* Data Manipulation
  * Liquid Output: Generate a String from a Liquid Template
  * JSON Parse: Parse a JSON
  * CSV: Manipulate CSV

* Triggers
  * Webhook: Call an event when receiving an HTTP call
  * Manual Trigger: A button trigger that dispatch an event
  * Scheduler: Trigger an event every X time.

* Flow manipulations
  * Commander: Command another agent to run
  * Trigger: Trigger an event if a specific value is there
  * Attribute difference: If you want to check a value change in your events (percentage of a value)
  * Change Detector: If you want to check a change in your event (status change for example)
  * Peak Detector: When a peak is reached, trigger an event
  * De-Duplication: Check the event haven't been sent before and relay it if it is new.
  * JavaScript: Run a javascript with mini_racer gem to process an event.

* Buffers
  * Data Output: Will buffer a RSS/JSON feed and output it as an ordered feed.
  * Delay: Buffer an amount of events, and trigger them with a delay
  * Digest: Buffer an amount of events, and trigger them when the max amount of event is reached
  * Email Digest: Buffer an amount of events, and send an email with the feed.

* MISC
  * Email: Send an email with the Rails SMTP's credentials


# What is wrong with Huginn?

* Huginn implements a core, and way too-many agents
   * Gems deps are hell to update and keep agents from working well. So it slow down gem updates.
   * Every Huginn version should be compatible with all the agent, even some agents might be unused.
   * Docker images are always huge, as it needs a lot of system deps.
* Huginn fastest way to deploy is on Heroku
   * Heroku heavily rely on Amazon services 👹
 
 **How do we fix that?** Breaking the main repo and make it lean again.
 
* Remove MySQL support (no sense to support multiple DB provider)
* Support only Docker, and provides non-heroku deployments alternatives _as examples_.
* Improve support with additional gem in Gemfile, to be easy to add many huginn_agents.

=> Deployment and running instances can be as small as possible, with only what we need from now, and not a lot of waste.

### Collaborate

We would love to, but we are not ready yet for contributions. Check the main repository instead



## Getting Started

### Docker

We support only docker installation.

Installation guide will come soon

## Using Huginn Agent gems

Huginn Agents can now be written as external gems and be added to your Huginn installation with the `ADDITIONAL_GEMS` environment variable. See the `Additional Agent gems` section of `.env.example` for more information.

If you'd like to write your own Huginn Agent Gem, please see [huginn_agent](https://github.com/huginn/huginn_agent).

Our general intention is to encourage Agents to be written as Gems, while continuing to improve core with Huginn-Lite repository.



## License
Huginn-Lite is provided under the [MIT License](LICENSE).


Huginn-Lite is a fork from [Huginn](https://github.com/huginn/lite). Huginn was originally created by [@cantino](https://github.com/cantino) in 2013. 