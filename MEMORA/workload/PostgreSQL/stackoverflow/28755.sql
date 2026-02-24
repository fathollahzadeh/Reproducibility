WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT SUBSTRING(t.TagName FROM 1 FOR 25)) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosedOrReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, u.DisplayName
),
RankedPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        Tags,
        CommentCount,
        ClosedOrReopenedCount,
        RANK() OVER (ORDER BY LastActivityDate DESC) AS ActivityRank
    FROM 
        ProcessedPosts
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Tags,
    rp.CommentCount,
    rp.ClosedOrReopenedCount,
    CASE 
        WHEN rp.ClosedOrReopenedCount > 0 THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS Status
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 10 AND
    rp.ActivityRank <= 100 
ORDER BY 
    rp.ActivityRank;