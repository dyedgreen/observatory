// Observatory - Unobtrusive web analytics

(() => {
  "use strict";

  const PageViewTimeout: number = 60*1000;
  const CookieEndurance: number = 60*30*1000;
  const DoNotTrack: boolean     = navigator.hasOwnProperty("doNotTrack") && navigator["doNotTrack"] === "1";
  const ObservatoryHost: any    = document.getElementById("observatory-script")["src"].match(`(https?:\/\/.+)\/static\/scripts\/telescope\.js`)[1];

  // Write do not track status to page
  if (document.getElementById("observatory-dnt-info")) {
    document.getElementById("observatory-dnt-info").innerHTML = DoNotTrack ?
      "You request to not be tracked. Observatory respects that." :
      "The pages you visit are recorded by Observatory.";
  }
  console.log("This website uses Observatory to track view statistics. Learn more at https://github.com/dyedgreen/observatory");

  // Honor do not track
  if (DoNotTrack) return;

  const Cookie = {
    get: (name: string): any => {
      let c = document.cookie.match(`(?:(?:^|.*; *)${name} *= *([^;]*).*$)|^.*$`)[1];
      return c ? JSON.parse(decodeURIComponent(c)) : undefined;
    },
    set: (name: string, value: any, options: Object={"path":"/", "max-age":CookieEndurance}) => {
      let v = encodeURIComponent(JSON.stringify(value));
      let o = Object.keys(options).reduce((s, key) => `${s}; ${key}=${options[key]}`, "");
      document.cookie = `${name}=${v}${o}`;
    },
  };

  const Api = {
    req: (method: string, path: string, data: Object, cb: Function) => {
      let req = new XMLHttpRequest();
      req.open(method, `${ObservatoryHost}/api${path}`, true);
      req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
      req.onload = () => {
        let {error, data} = JSON.parse(req.responseText);
        cb(error, data);
      };
      req.send(Object.keys(data).reduce((s, key) => `${s}&${key}=${encodeURIComponent(data[key])}`, ""));
    },
    get: (path: string, data: Object, cb: Function) => { Api.req("GET", path, data, cb) },
    post: (path: string, data: Object, cb: Function) => { Api.req("POST", path, data, cb) },
  };

  let state = Cookie.get("observatory") || {
    views: {},
    visit: null,
    referrer: "",
  };
  function store() { Cookie.set("observatory", state); }

  // Determine view parameters
  const Referrer: string = location.hostname.indexOf(document.referrer) === -1 ? document.referrer : "";
  const Host: string     = location.hostname;
  const Path: string     = location.pathname;

  if (Referrer !== state.referrer && Referrer !== "") {
    // New referrer counts as new visit
    state.view = {};
    state.visit = null;
    state.referrer = Referrer;
  }

  // Determine if the current visit counts as new
  if (state.views[Path] && state.views[Path] < Date.now() - PageViewTimeout) {
    Api.post("/visit/create", {
      visit: state.visit,
      referrer: Referrer,
      host: Host,
      path: Path
    }, (err, data) => {
      if (!err) state.visit = data;
      store();
    });
  }
  state.views[Path] = Date.now();

  // Store final state
  store();

})();
