WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(tag)
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerName,
    r.Score,
    r.ViewCount,
    pv.UpVotes,
    pv.DownVotes,
    pt.Tags,
    r.Rank
FROM 
    RankedPosts r
LEFT JOIN 
    PostVotes pv ON r.PostId = pv.PostId
LEFT JOIN 
    PostTags pt ON r.PostId = pt.PostId
WHERE 
    r.Rank <= 5
ORDER BY 
    r.PostId;