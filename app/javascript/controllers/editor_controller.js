import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { layout: Object, saveUrl: String, exportUrl: String }
    static targets = ["overlay"]

    connect() {
        this.pages = this.layoutValue.pages
        this.render()
    }

    render() {
        this.overlayTargets.forEach((overlay, i) => {
            overlay.innerHTML = ""
            this.pages[i].blocks.forEach((b, idx) => {
                const el = document.createElement("div")
                el.className = `block ${b.type}`
                el.style.position = "absolute"
                el.style.left = b.x + "px"
                el.style.top = b.y + "px"
                el.style.width = b.w + "px"
                el.style.height = b.h + "px"
                if (b.type === "text") {
                    el.contentEditable = true
                    el.innerText = b.text
                } else if (b.type === "image") {
                    const img = document.createElement("img")
                    img.src = b.url || `/rails/active_storage/blobs/redirect/${b.blob_id}`
                    img.style.width = "100%"
                    img.style.height = "100%"
                    el.appendChild(img)
                }
                overlay.appendChild(el)
            })
        })
    }

    save() {
        fetch(this.saveUrlValue, {
            method: "PATCH",
            headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrf() },
            body: JSON.stringify({ layout_json: { pages: this.pages } })
        })
    }

    export() {
        window.location.href = this.exportUrlValue
    }

    csrf() {
        return document.querySelector("meta[name=csrf-token]").content
    }
}
