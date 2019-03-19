# Observatory

Unobtrusive Analytics for the Web

---

Observatory allows you to track basic actions on your website and shared short-urls, while
respecting your users privacy.

## Adding a website to Observatory
To start collecting data from a page, three things need to be done.

1. The host name of the page needs to be white-listed under the settings tab.
2. All pages that should be tracked need to include the meta tag:
   ```html
   <meta name="observatory" content="[host name consent token]">
   ```
   (The consent token can be found in the host white-list under the settings tab.)
3. Include the `telescope` script in every page that should be tracked:
   ```html
   <script id="observatory-script" src="https://your.host.com/static/scripts/telescope.js" async></script>
   ```

Optionally, the following id can be given to any element. (But only to one element.) The inner html
of this node will be replaced with information about the users current DoNotTrack setting.
```html
<p id="observatory-dnt-info"></p>
```
