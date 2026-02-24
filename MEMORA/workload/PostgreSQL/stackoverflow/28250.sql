WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tagId ON tagId IS NOT NULL
    LEFT JOIN
        Tags t ON t.Id::varchar = tagId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS InitialEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosureDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.CommentCount,
    pv.UpVotes,
    pv.DownVotes,
    hd.InitialEditDate,
    hd.LastEditDate,
    hd.ClosureDate,
    hd.ClosureDate IS NOT NULL AS IsClosed,
    STRING_AGG(DISTINCT tag, ', ') AS AllTags
FROM 
    RankedPosts rp
JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
JOIN 
    PostHistoryDetails hd ON rp.PostId = hd.PostId
CROSS JOIN LATERAL 
    unnest(rp.Tags) AS tag
WHERE 
    rp.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.LastActivityDate, 
    rp.Score, rp.CommentCount, pv.UpVotes, pv.DownVotes, 
    hd.InitialEditDate, hd.LastEditDate, hd.ClosureDate
ORDER BY 
    rp.Score DESC, rp.LastActivityDate DESC
LIMIT 50;