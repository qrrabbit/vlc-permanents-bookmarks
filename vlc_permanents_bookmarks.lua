-------------- Global variables ---------------------------------------
local mediaFile = {}
local input = nil
local Bookmarks = {}
local selectedBookmarkId = nil
local bookmarkFilePath = nil
-- UI
local dialog_UI = nil
local bookmarks_dialog = {}
local dialog_title = "VLC Permanents Bookmarks"
------------------------------------------------------------------------

-- VLC defined callback functions --------------------------------------
-- Script descriptor, called when the extensions are scanned
function descriptor()
    return {
        title = dialog_title,
        version = "1.0.1",
        author = "Bucchio",
        url = 'https://github.com/JacopoBucchioni/vlc-permanents-bookmarks',
        shortdesc = "Bookmarks",
        description = "Save bookmarks for your media files and store them permanently.",
        capabilities = {"menu", "input-listener"}
    }
end

-- First function to be called when the extension is activated
function activate()
    vlc.msg.dbg("[Activate extension] Welcome! Start saving your bookmarks!")
    local ok, err = pcall(check_config)
    if not ok then
        vlc.msg.err("[Activate extension] Configuration check failed: " .. tostring(err))
        return false
    end
    vlc.msg.dbg("[Activate extension] Configuration check passed")
    show_gui()
    return true
end

-- Called when the extension dialog is closed
function close()
    vlc.deactivate()
end

-- Called when the extension is deactivated
function deactivate()
    vlc.msg.dbg("[Deactivate extension] Bye bye!")
    if dialog_UI then
        dialog_UI:hide()
    end
end

-- Called on mouseover on the extension in View menu
function menu()
    return {"Show dialog"}
end

-- trigger function on menu() function call
function trigger_menu(dlg_id)
    show_gui()
end

-- related to capabilities={"input-listener"} in descriptor()
-- triggered by Start/Stop media input event
function input_changed() -- ~ !important: deve essere qualcosa di veloce
    vlc.msg.dbg("[Input changed] Resetting bookmark system state")
    if dialog_UI then
        dialog_UI:hide()
    end

    -- Reset all global variables
    input = nil
    mediaFile = {}
    Bookmarks = {}
    selectedBookmarkId = nil
    bookmarkFilePath = nil
    
    vlc.msg.dbg("[Input changed] State reset complete")
end

-- triggered by available media input meta data?
function meta_changed()
    -- return
end
-- End VLC defined callback functions ----------------------------------

-- // Bookmarks init function
function load_bookmarks()
    -- mediaFile.metaTitle = vlc.input.item():name()
    local item = vlc.input.item()
    if not item then
        vlc.msg.warn("No input item available")
        return false
    end
    
    mediaFile.uri = item:uri()
    if not mediaFile.uri then
        vlc.msg.warn("No URI available for input item")
        return false
    end
    
    if mediaFile.uri then
        local filePath = vlc.strings.make_path(mediaFile.uri)
        if not filePath then
            filePath = vlc.strings.decode_uri(mediaFile.uri)
            local match = string.match(filePath, "^.*[" .. slash .. "]([^" .. slash .. "]-).?[%a%d]*$")
            if match then
                filePath = match
            end
        else
            mediaFile.dir, mediaFile.name = string.match(filePath,
                "^(.*[" .. slash .. "])([^" .. slash .. "]-).?[%a%d]*$")
        end
        if not mediaFile.name then
            mediaFile.name = filePath
        end
        -- vlc.msg.dbg("Video Meta Title: " .. mediaFile.metaTitle)
        vlc.msg.dbg("Video URI: " .. mediaFile.uri)
        vlc.msg.dbg("fileName: " .. mediaFile.name)
        vlc.msg.dbg("fileDir: " .. tostring(mediaFile.dir))

        local hashSuccess = getFileHash()
        if hashSuccess and mediaFile.hash then
            bookmarkFilePath = bookmarksDir .. slash .. mediaFile.hash
            vlc.msg.dbg("Bookmark file path: " .. bookmarkFilePath)
            
            -- Check if bookmark file exists
            local file = io.open(bookmarkFilePath, "r")
            if file then
                file:close()
                vlc.msg.dbg("Bookmark file exists, loading...")
            else
                vlc.msg.dbg("Bookmark file does not exist, will be created")
            end
            
            Bookmarks = table_load(bookmarkFilePath)
            vlc.msg.dbg("Loaded bookmarks table, type: " .. type(Bookmarks))
            vlc.msg.dbg("Loaded bookmarks count: " .. tostring(#Bookmarks))
            
            -- Validate loaded bookmarks
            for idx, b in pairs(Bookmarks) do
                if not (b and b.label and b.formattedTime) then
                    vlc.msg.warn("Invalid bookmark data loaded at index " .. tostring(idx))
                end
            end
            
            input = vlc.object.input()
            if not input then
                vlc.msg.warn("Failed to get input object")
                return false
            end
            vlc.msg.dbg("Successfully initialized bookmarks system")
            collectgarbage()
            return true
        else
            vlc.msg.warn("Failed to calculate file hash")
            return false
        end
    end
    return false
end

function getFileHash()
    -- Calculate media hash
    local data_start = ""
    local data_end = ""
    local size
    local chunk_size = 65536
    local ok
    local err

    -- Get data for hash calculation
    vlc.msg.dbg("init read hash data from stream")
    local stream = vlc.stream(mediaFile.uri)
    if not stream then
        vlc.msg.warn("Failed to open stream for: " .. mediaFile.uri)
        return false
    end
    
    data_start = stream:read(chunk_size)
    if not data_start or #data_start == 0 then
        vlc.msg.warn("Failed to read data from start of stream")
        return false
    end
    
    ok, size = pcall(stream.getsize, stream)
    if not ok or not size or size <= 0 then
        vlc.msg.warn("Failed to get stream size: " .. tostring(size))
        return false
    end
    mediaFile.bytesize = size
    vlc.msg.dbg("File bytesize: " .. mediaFile.bytesize)
    
    -- For small files, don't try to seek to the end
    if size <= chunk_size then
        data_end = ""
    else
        ok, err = pcall(stream.seek, stream, size - chunk_size)
        if not ok then
            vlc.msg.warn("Failed to seek the stream: " .. tostring(err))
            return false
        end
        data_end = stream:read(chunk_size)
        if not data_end then
            data_end = ""
        end
    end
    vlc.msg.dbg("finish Read hash data from stream")

    -- Hash calculation
    local lo = size
    local hi = 0
    local o, a, b, c, d, e, f, g, h
    local hash_data = data_start .. data_end
    local max_size = 4294967296
    local overflow

    for i = 1, #hash_data, 8 do
        a, b, c, d, e, f, g, h = hash_data:byte(i, i + 7)
        a = a or 0
        b = b or 0
        c = c or 0
        d = d or 0
        e = e or 0
        f = f or 0
        g = g or 0
        h = h or 0
        
        lo = lo + a + b * 256 + c * 65536 + d * 16777216
        hi = hi + e + f * 256 + g * 65536 + h * 16777216

        if lo > max_size then
            overflow = math.floor(lo / max_size)
            lo = lo - (overflow * max_size)
            hi = hi + overflow
        end

        if hi > max_size then
            overflow = math.floor(hi / max_size)
            hi = hi - (overflow * max_size)
        end
    end

    mediaFile.hash = string.format("%08x%08x", hi, lo)
    vlc.msg.dbg("File hash: " .. mediaFile.hash)
    collectgarbage()
    return true
end

-- // system check and extension config
function check_config()
    slash = package.config:sub(1, 1)

    bookmarksDir = vlc.config.userdatadir()
    local res, err = vlc.io.mkdir(bookmarksDir, "0700")
    if res ~= 0 and err ~= vlc.errno.EEXIST then
        vlc.msg.warn("Failed to create " .. bookmarksDir)
        return false
    end
    local subdirs = {"lua", "extensions", "userdata", "bookmarks"}
    for _, dir in ipairs(subdirs) do
        res, err = vlc.io.mkdir(bookmarksDir .. slash .. dir, "0700")
        if res ~= 0 and err ~= vlc.errno.EEXIST then
            vlc.msg.warn("Failed to create " .. bookmarksDir .. slash .. dir)
            return false
        end
        bookmarksDir = bookmarksDir .. slash .. dir
    end

    if bookmarksDir then
        vlc.msg.dbg("Bookmarks directory: " .. bookmarksDir)
    end

    collectgarbage()
    return true
end

-- // The Save Function
function table_save(t, filePath)
    local function exportstring(s)
        return string.format("%q", s)
    end

    local charS, charE = "   ", "\n"
    local file, err = io.open(filePath, "wb")
    if err then
        return err
    end

    -- initiate variables for save procedure
    local tables, lookup = {t}, {
        [t] = 1
    }
    file:write("return {" .. charE)

    for idx, t in ipairs(tables) do
        file:write("-- Table: {" .. idx .. "}" .. charE)
        file:write("{" .. charE)
        local thandled = {}

        for i, v in ipairs(t) do
            thandled[i] = true
            local stype = type(v)
            -- only handle value
            if stype == "table" then
                if not lookup[v] then
                    table.insert(tables, v)
                    lookup[v] = #tables
                end
                file:write(charS .. "{" .. lookup[v] .. "}," .. charE)
            elseif stype == "string" then
                file:write(charS .. exportstring(v) .. "," .. charE)
            elseif stype == "number" then
                file:write(charS .. tostring(v) .. "," .. charE)
            end
        end

        for i, v in pairs(t) do
            -- escape handled values
            if (not thandled[i]) then

                local str = ""
                local stype = type(i)
                -- handle index
                if stype == "table" then
                    if not lookup[i] then
                        table.insert(tables, i)
                        lookup[i] = #tables
                    end
                    str = charS .. "[{" .. lookup[i] .. "}]="
                elseif stype == "string" then
                    str = charS .. "[" .. exportstring(i) .. "]="
                elseif stype == "number" then
                    str = charS .. "[" .. tostring(i) .. "]="
                end

                if str ~= "" then
                    stype = type(v)
                    -- handle value
                    if stype == "table" then
                        if not lookup[v] then
                            table.insert(tables, v)
                            lookup[v] = #tables
                        end
                        file:write(str .. "{" .. lookup[v] .. "}," .. charE)
                    elseif stype == "string" then
                        file:write(str .. exportstring(v) .. "," .. charE)
                    elseif stype == "number" then
                        file:write(str .. tostring(v) .. "," .. charE)
                    end
                end
            end
        end
        file:write("}," .. charE)
    end
    file:write("}")
    file:close()
end

-- // The Load Function
function table_load(filePath)
    local ftables, err = loadfile(filePath)
    if err then
        return {}, err
    end
    local tables = ftables()
    for idx = 1, #tables do
        local tolinki = {}
        for i, v in pairs(tables[idx]) do
            if type(v) == "table" then
                tables[idx][i] = tables[v[1]]
            end
            if type(i) == "table" and tables[i[1]] then
                table.insert(tolinki, {i, tables[i[1]]})
            end
        end
        -- link indices
        for _, v in ipairs(tolinki) do
            tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
        end
    end
    return tables[1]
end

-- // The Binary Insert Function
function table_binInsert(t, value, fcomp)
    local fcomp_default = function(a, b)
        return a < b
    end
    -- Initialise compare function
    local fcomp = fcomp or fcomp_default
    --  Initialise numbers
    local iStart, iEnd, iMid, iState = 1, #t, 1, 0
    -- Get insert position
    while iStart <= iEnd do
        -- calculate middle
        iMid = math.floor((iStart + iEnd) / 2)
        -- compare
        if fcomp(value, t[iMid]) then
            iEnd, iState = iMid - 1, 0
        else
            iStart, iState = iMid + 1, 1
        end
    end
    -- table.insert( t,(iMid+iState),value )
    return (iMid + iState)
end

function table_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- // get number rappresenting time in microseconds and return a string with formatted time hh:mm:ss.millis
function getFormattedTime(micros)
    local millis = math.floor(micros / 1000)
    local seconds = math.floor((millis / 1000) % 60)
    local minutes = math.floor((millis / 60000) % 60)
    local hours = math.floor((millis / 3600000) % 24)
    millis = math.floor(millis % 1000)
    return string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, millis)
end

-- GUI Setup and buttons callbacks ----------------------------------------
-- Create the main bookmarks dialog
function main_dialog()
    dialog_UI = vlc.dialog(dialog_title)

    -- Create text input and Add button
    bookmarks_dialog['text_input'] = dialog_UI:add_text_input('Bookmark (' .. (#Bookmarks + 1) .. ')', 1, 1, 1, 1)
    bookmarks_dialog['add_button'] = dialog_UI:add_button("Add", addBookmark, 1, 2, 1, 1)
    
    -- Bookmarks list
    bookmarks_dialog['bookmarks_list'] = dialog_UI:add_list(1, 3, 1, 1)

    -- Action buttons
    dialog_UI:add_button("Go", goToBookmark, 1, 4, 1, 1)
    dialog_UI:add_button("Rename", editBookmark, 1, 5, 1, 1)  
    dialog_UI:add_button("Remove", removeBookmark, 1, 6, 1, 1)
    dialog_UI:add_button("Close", vlc.deactivate, 1, 7, 1, 1)

    -- Footer message and tip
    bookmarks_dialog['footer_message'] = dialog_UI:add_label('', 1, 8, 1, 1)
    dialog_UI:add_label("💡 Tip: 'Go' plays bookmark and closes dialog", 1, 9, 1, 1)

    showBookmarks()
    dialog_UI:show()
end

function showBookmarks()    
    if not bookmarks_dialog['bookmarks_list'] then
        vlc.msg.warn("bookmarks_list UI element not found")
        return
    end
    
    -- Clear the list and count items
    bookmarks_dialog['bookmarks_list']:clear()
    local itemsAdded = 0
    
    -- Find max index to iterate properly
    local maxIdx = 0
    for idx, _ in pairs(Bookmarks) do
        if idx > maxIdx then maxIdx = idx end
    end
    
    -- Add bookmarks in sequential order
    for i = 1, maxIdx do
        local b = Bookmarks[i]
        if b and b.formattedTime and b.label then
            local text = tostring(b.formattedTime) .. " " .. tostring(b.label)
            
            local success = pcall(function()
                bookmarks_dialog['bookmarks_list']:add_value(text, i)
            end)
            
            if success then
                itemsAdded = itemsAdded + 1
            else
                vlc.msg.warn("Failed to add bookmark: [" .. tostring(i) .. "] " .. text)
            end
        end
    end
    
    -- Update footer message
    if bookmarks_dialog['footer_message'] then
        if itemsAdded > 0 then
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Loaded " .. itemsAdded .. " bookmarks. Select and use 'Go' to play."))
        else
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("No bookmarks saved yet. Type bookmark name and click Add!"))
        end
    end
end

-- Buttons callbacks -------------------------------------------------------------



function addBookmark()
    dlt_footer()
    
    -- Check if essential variables are initialized
    if not input then
        vlc.msg.warn("Input object not available. Cannot add bookmark.")
        if bookmarks_dialog['footer_message'] then
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: Media not properly loaded"))
        end
        return
    end
    
    if not bookmarkFilePath then
        vlc.msg.warn("Bookmark file path not set. Cannot save bookmark.")
        if bookmarks_dialog['footer_message'] then
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: Bookmark system not initialized"))
        end
        return
    end
    
    if not Bookmarks then
        vlc.msg.warn("Bookmarks table not initialized")
        Bookmarks = {}
    end
    
    if bookmarks_dialog['text_input'] then
        local label = bookmarks_dialog['text_input']:get_text()
        if string.len(label) > 0 then
            if selectedBookmarkId ~= nil then
                -- rename an existing bookmark
                if Bookmarks[selectedBookmarkId] then
                    Bookmarks[selectedBookmarkId].label = label
                    selectedBookmarkId = nil
                else
                    vlc.msg.warn("Selected bookmark ID is invalid")
                    bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: Invalid bookmark selection"))
                    return
                end
            else
                -- add a new bookmark
                local currentTime = vlc.var.get(input, "time")
                if not currentTime or currentTime < 0 then
                    vlc.msg.warn("Could not get current playback time")
                    bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: Could not get current time"))
                    return
                end
                
                local b = {}
                b.time = currentTime
                b.label = label
                b.formattedTime = getFormattedTime(b.time)
                
                -- Check if bookmark at same time already exists
                local existingIndex = nil
                for idx, existingBookmark in pairs(Bookmarks) do
                    if existingBookmark.formattedTime == b.formattedTime then
                        existingIndex = idx
                        break
                    end
                end
                
                if existingIndex then
                    -- Update existing bookmark label
                    Bookmarks[existingIndex].label = b.label
                    bookmarks_dialog['footer_message']:set_text(setMessageStyle("Updated bookmark at " .. b.formattedTime))
                else
                    -- Add new bookmark
                    local i = table_binInsert(Bookmarks, b, function(a, b)
                        return a.time <= b.time
                    end)
                    table.insert(Bookmarks, i, b)
                    bookmarks_dialog['footer_message']:set_text(setMessageStyle("Added bookmark: " .. b.label))
                end
            end
            
            -- Save bookmarks to file
            local saveResult = table_save(Bookmarks, bookmarkFilePath)
            if saveResult then
                vlc.msg.warn("Error saving bookmarks: " .. tostring(saveResult))
                bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: Could not save bookmark"))
                return
            end
            
            showBookmarks()
            bookmarks_dialog['text_input']:set_text('Bookmark (' .. (#Bookmarks + 1) .. ')')
        else
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please enter your bookmark title"))
        end
    else
        vlc.msg.warn("Text input element not found")
        if bookmarks_dialog['footer_message'] then
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Error: UI not properly initialized"))
        end
    end
end

function goToBookmark()
    dlt_footer()
    if bookmarks_dialog['bookmarks_list'] then
        local selection = bookmarks_dialog['bookmarks_list']:get_selection()
        selectedBookmarkId = nil
        if next(selection) then
            if table_length(selection) == 1 then
                for idx, _ in pairs(selection) do
                    vlc.var.set(input, "time", Bookmarks[idx].time)
                    vlc.deactivate()
                    return
                end
            else
                bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please select only one item"))
            end
        else
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please select a item"))
        end
    end
end

function editBookmark()
    dlt_footer()
    if bookmarks_dialog['bookmarks_list'] then
        local selection = bookmarks_dialog['bookmarks_list']:get_selection()
        selectedBookmarkId = nil
        if next(selection) then
            if table_length(selection) == 1 then
                for idx, _ in pairs(selection) do
                    bookmarks_dialog['text_input']:set_text(Bookmarks[idx].label)
                    selectedBookmarkId = idx
                    return
                end
            else
                bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please select only one item"))
            end
        else
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please select a item"))
        end
    end
end

-- Store the last selected index for consecutive removals
local lastSelectedForRemoval = nil







function removeBookmark()
    dlt_footer()
    if bookmarks_dialog['bookmarks_list'] then
        local selection = bookmarks_dialog['bookmarks_list']:get_selection()
        local itemToRemove = nil
        
        -- Check if we have a real selection
        if next(selection) then
            -- Use actual selection
            for idx, _ in pairs(selection) do
                itemToRemove = idx
                break  -- Take first selected item
            end
            lastSelectedForRemoval = itemToRemove
        elseif lastSelectedForRemoval and lastSelectedForRemoval <= #Bookmarks then
            -- Use stored index from previous removal (for consecutive removes)
            itemToRemove = lastSelectedForRemoval
        end
        
        if itemToRemove and Bookmarks[itemToRemove] then
            local removedLabel = Bookmarks[itemToRemove].label
            table.remove(Bookmarks, itemToRemove)
            table_save(Bookmarks, bookmarkFilePath)
            
            -- Update stored index for next removal
            if #Bookmarks > 0 then
                lastSelectedForRemoval = math.min(itemToRemove, #Bookmarks)
            else
                lastSelectedForRemoval = nil
            end
            
            showBookmarks()
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Removed: " .. removedLabel .. ". Next item ready for removal."))
        else
            lastSelectedForRemoval = nil
            bookmarks_dialog['footer_message']:set_text(setMessageStyle("Please select an item to remove"))
        end
    end
end
-- End buttons callbacks -------------------------------------------------

function setMessageStyle(str)
    return "<p style='font-size: 12px; margin-left: 4px;'>" .. str .. "</p>"
end

function dlt_footer()
    if bookmarks_dialog['footer_message'] then
        bookmarks_dialog['footer_message']:set_text('')
    end
end

function close_dlg()
    if dialog_UI ~= nil then
        dialog_UI:hide()
    end
    dialog_UI = nil
    bookmarks_dialog = nil
    bookmarks_dialog = {}
    collectgarbage()
end

function show_gui()
    close_dlg()
    local item = vlc.input.item()
    if item then
        -- Check if we need to load bookmarks
        if not input or not bookmarkFilePath then
            local loadSuccess = load_bookmarks()
            if not loadSuccess then
                vlc.msg.warn("Failed to load bookmarks system")
                error_dialog("Failed to initialize bookmark system. Please check that the media file is accessible.")
                return
            end
        end
        main_dialog()
    else
        noinput_dialog()
    end
    collectgarbage()
end

function noinput_dialog()
    dialog_UI = vlc.dialog(dialog_title)
    dialog_UI:add_label(
        "<p style='font-size: 12px; text-align: center;'>Please open a media file before running this extension</p>")
    dialog_UI:show()
end

function error_dialog(message)
    dialog_UI = vlc.dialog(dialog_title)
    dialog_UI:add_label(
        "<p style='font-size: 12px; text-align: center; color: red;'>" .. message .. "</p>")
    dialog_UI:add_button("Close", vlc.deactivate, 1, 2, 1, 1)
    dialog_UI:show()
end
