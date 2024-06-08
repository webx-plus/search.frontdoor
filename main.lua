local query = get(".query");
local btn = get("search-button")
local rndmbtn = get("random-button")
local items = get("item", true);
local itemName = get("item-name", true);
local itemUrl = get("item-url", true);
local itemIp = get("item-ip", true);
local nextbtn = get('next-button');
local previousbtn = get('previous-button');
local currentPage = get('cur-page');
local totalPage = get('total-page');

local page = 0;
local totalPages = 3;
local limit = 6;
local queried = "";
local dns = "https://webxdns.votemanager.xyz/domain/";

function main()
    clearItems();
end

-- Declare functions
------------------------------------
-- Get URL of an item
function getURL(item)
    return (item["name"] .. "." .. item["tld"]);
end

-- Convert character to hexadecimal
local char_to_hex = function(c)
    return string.format("%%%02X", string.byte(c))
end

-- URL encode the given string
local function urlencode(url)
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

-- Arrays from the fetch function are converted to userdata, userdata is not iterable on it's own.
-- Therefore we create our own iterable function.
local function userdata_iter(ud)
    local index = 0
    local size = #ud
    return function()
        index = index + 1
        if index <= size then
            return index, ud[index]
        end
    end
end

-- Fetch domains from the DNS using the given query.
function fetchDomains(_query, _page)
    local response = fetch({
        url = dns .. "?search=" .. urlencode(_query) .. "&page=" .. _page .. "&limit=" .. limit,
        method = "GET",
        headers = { ["Content-Type"] = "application/json" }
    });
    return response["data"];
end

-- Fetch number of pages for query
function fetchTotalPages(_query)
    local response = fetch({
        url = dns .. "?search=" .. urlencode(_query),
        method = "GET",
        headers = { ["Content-Type"] = "application/json" }
    });
    local allPages = response["data"];
    return math.ceil(#allPages / limit);
end

-- Fetch a random item from the dns.
function fetchRandomItem()
    local response = fetch({
        url = dns .. "?search=",
        method = "GET",
        headers = { ["Content-Type"] = "application/json" }
    });
    local allItems = response["data"];
    return allItems[math.random(#allItems)];
end

-- Clears all items from the results.
function clearItems()
    local nameEl = get('random-item-name');
    nameEl.set_content('');

    for index, item in pairs(items) do
        --item.set_opacity(0);
        local itemEl = items[index];
        local nameEl = itemName[index];
        local ipEl = itemIp[index];
        local urlEl = itemUrl[index];
        nameEl.set_content('');
        ipEl.set_content('');
        urlEl.set_content('');
        urlEl.set_href('');
    end
end

-- Displays the given item at the given index in the results.
function displayItem(index, item)
    local itemEl = items[index];
    local nameEl = itemName[index];
    local ipEl = itemIp[index];
    local urlEl = itemUrl[index];

    local url = "buss://" .. getURL(item);
    nameEl.set_content(item["name"]);
    nameEl.set_href(url);
    ipEl.set_content(item["target"]);
    urlEl.set_content(url);
    urlEl.set_href(url);
end

-- Displays an array of items in the results.
function displayItems(arr)
    clearItems();
    for index, item in userdata_iter(arr) do
        displayItem(index, item);
    end
end

function updatePages(nr)
    totalPage.set_content(totalPages);
    currentPage.set_content(nr + 1);
    displayItems(fetchDomains(queried, nr));
end

-- Retrieve the contents of the input and apply the query.
function applyQuery()
    queried = query.get_content();
    totalPages = fetchTotalPages(queried);
    page = 0;
    updatePages(page);
end

function nextPage()
    if (page + 1) > (totalPages - 1) then
        return;
    end
    updatePages(math.min(page + 1, totalPages - 1));
    page = math.min(page + 1, totalPages - 1);
end

function previousPage()
    if (page - 1) < 0 then
        return;
    end
    updatePages(math.max(page - 1, 0));
    page = math.max(page - 1, 0);
end

-- Event Listeners
nextbtn.on_click(nextPage);
previousbtn.on_click(previousPage);
query.on_submit(applyQuery);
btn.on_click(applyQuery);
rndmbtn.on_click(function()
    clearItems();
    local itemEl = get('random-item');
    local nameEl = get('random-item-name');
    local ipEl = get('random-item-ip');
    local urlEl = get('random-item-url');

    local item = fetchRandomItem();
    local url = "buss://" .. getURL(item);
    nameEl.set_content(item["name"]);
    nameEl.set_href(url);
    ipEl.set_content(item["target"]);
    urlEl.set_content(url);
    urlEl.set_href(url);
end)

-- Run main thread
main();
