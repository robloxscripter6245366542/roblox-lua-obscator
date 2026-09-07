import { contextBridge, ipcRenderer } from "electron";

contextBridge.exposeInMainWorld("nova", {
  onEvent: (cb: (data: any) => void) => {
    ipcRenderer.on("nova:event", (_e, data) => cb(data));
  },
  getSettings: () => ipcRenderer.invoke("settings:get"),
  setKey: (key: string) => ipcRenderer.invoke("settings:setKey", key),
  setModel: (m: string) => ipcRenderer.invoke("settings:setModel", m),
  setBaseUrl: (u: string) => ipcRenderer.invoke("settings:setBaseUrl", u),
  setApproval: (on: boolean) => ipcRenderer.invoke("settings:setApproval", on),
  pickFolder: () => ipcRenderer.invoke("settings:pickFolder"),
  send: (text: string) => ipcRenderer.send("agent:send", text),
  reset: () => ipcRenderer.send("agent:reset"),
});
