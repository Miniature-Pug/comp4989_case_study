const Pages = class {
    constructor(pages) {
        this.pages = pages || {}
    }

    setPage(id, href, name, backlinks) {
        this.pages[id] = {
            "name": name,
            "href": href,
            "backlinks": backlinks
        }
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
    console.log(JSON.stringify(pages))

    document.getElementById("rank").addEventListener("click", async () => {
        try {
            const response = await fetch('https://c6kap9d23f.execute-api.us-east-1.amazonaws.com/serverless_lambda/rank', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    "Access-Control-Allow-Origin": "*"
                },
                body: JSON.stringify(pages),
            });

            if (!response.ok) {
                throw new Error(`Request failed with status ${response.status}`);
            }

            const data = await response.json();
            console.log('Response:', data);
            const sortedData = Object.entries(data)
                .map(([key, value]) => ({
                    key,
                    value
                }))
                .sort((a, b) => b.value - a.value);
            console.log('Sorted Response:', sortedData);
            // Get the container and list elements
            const rankedContainer = document.getElementById('ranked_container');
            const sortedList = document.getElementById('sorted-list');

            // Clear the previous list items if any
            sortedList.innerHTML = '';

            // Iterate over the sorted data and create list items to display
            let p = pages.getPages()
            sortedData.forEach(item => {
                const listItem = document.createElement('li');
                const anchor = document.createElement('a');
                anchor.textContent = `${item.key}: ${item.value}`;
                anchor.href = p[item.key]["href"]
                listItem.appendChild(anchor);
                sortedList.appendChild(listItem);
            });

            // Display the container
            rankedContainer.style.display = 'block';
        } catch (error) {
            console.error('Error:', error);
        }
    });
}

prepIndex()