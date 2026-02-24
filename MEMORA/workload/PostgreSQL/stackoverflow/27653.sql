
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
    ORDER BY 
        VoteCount DESC, 
        CommentCount DESC
    LIMIT 10
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 month'  
        AND ph.PostId IN (SELECT PostId FROM RankedPosts)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    ra.HistoryDate,
    ra.ChangeType,
    ra.UserDisplayName,
    ra.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC, 
    ra.HistoryDate DESC;
