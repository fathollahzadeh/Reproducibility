
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag(tagname) 
        ON tag.tagname IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.tagname
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId, u.DisplayName
),

MostCommented AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
    ORDER BY 
        CommentCount DESC
),

LatestEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName AS Editor,
        ph.Text AS EditComment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),

PostMetrics AS (
    SELECT 
        m.PostId,
        m.Title,
        m.CommentCount,
        m.OwnerDisplayName,
        l.EditDate,
        l.Editor,
        l.EditComment,
        m.Tags
    FROM 
        MostCommented m
    LEFT JOIN 
        LatestEdits l ON m.PostId = l.PostId
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CommentCount,
    pm.OwnerDisplayName,
    pm.EditDate,
    pm.Editor,
    pm.EditComment,
    pm.Tags
FROM 
    PostMetrics pm
ORDER BY 
    pm.CommentCount DESC,
    pm.EditDate DESC;
