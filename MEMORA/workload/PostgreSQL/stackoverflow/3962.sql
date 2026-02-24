
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(t.TagName, ''), 'No Tag') AS TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT Id, unnest(string_to_array(Tags, '><')) AS TagName FROM Posts WHERE Tags IS NOT NULL) t ON p.Id = t.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, t.TagName
), RecentVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagName,
    rp.CommentCount,
    COALESCE(rv.NetVotes, 0) AS NetVotes,
    CASE 
        WHEN rp.Score > 100 AND COALESCE(rv.NetVotes, 0) > 5 THEN 'Highly Engaging'
        WHEN rp.Score <= 100 AND COALESCE(rv.NetVotes, 0) <= 5 THEN 'Moderately Engaging'
        ELSE 'Needs More Attention' 
    END AS EngagementStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
