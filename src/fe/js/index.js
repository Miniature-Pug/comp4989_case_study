const Pages = class {
    constructor(pages) {
        this.pages = pages || {}
    }

    setPage(id, href, name, backlinks) {
        this.pages[id] = {"name": name, "href": href, "backlinks": backlinks}
    }

    getPages() {
        return this.pages
    }
}

async function getBackLinksFromUrl(url) {
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }

      const text = await response.text();
      const parser = new DOMParser();
      const doc = parser.parseFromString(text, 'text/html');

      const links = Array.from(doc.querySelectorAll('.backlinks_list')).map((item) => item.id);

      return links;
    } catch (error) {
      console.error('Error:', error);
      return [];
    }
}

const pages = new Pages()

async function prepIndex() {
    const unrankedContainer = document.getElementById("unranked_container")
    const unrankedPageListItems = unrankedContainer.getElementsByClassName("unranked_page_list")

    for (const item of unrankedPageListItems) {
        const id = item.id
        const anchor = item.querySelector("a")
        const href = anchor.getAttribute("href")
        const text = anchor.textContent
        const backlinks = await getBackLinksFromUrl(href);
        pages.setPage(id, href, text, backlinks)
    }
    let p = pages.getPages()
    console.log(p)
}

prepIndex()