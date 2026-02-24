WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerDisplayName
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pt.PostId,
    pt.Title,
    pt.Body,
    pt.CreationDate,
    pt.OwnerDisplayName,
    pt.Tags,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COALESCE(pv.AcceptedVotes, 0) AS AcceptedVotes,
    ph.LastEditedDate,
    ph.HistoryTypes
FROM 
    PostTags pt
LEFT JOIN 
    PostVotes pv ON pt.PostId = pv.PostId
LEFT JOIN 
    PostHistorySummary ph ON pt.PostId = ph.PostId
WHERE 
    pt.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'  
ORDER BY 
    pt.CreationDate DESC;