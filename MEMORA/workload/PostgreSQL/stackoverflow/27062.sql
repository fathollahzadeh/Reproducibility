
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '> <')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.Score, 
        rp.OwnerDisplayName, 
        rp.AnswerCount, 
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.AnswerCount > 0 
        AND rp.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
)
SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.CreationDate,
    f.Score,
    f.OwnerDisplayName,
    f.AnswerCount,
    f.TagList,
    ph.UserDisplayName AS LastEditedBy,
    ph.CreationDate AS LastEditDate,
    COUNT(c.Id) AS CommentCount
FROM 
    FilteredPosts f
LEFT JOIN 
    PostHistory ph ON ph.PostId = f.PostId AND ph.PostHistoryTypeId = 24
LEFT JOIN 
    Comments c ON c.PostId = f.PostId
GROUP BY 
    f.PostId, f.Title, f.Body, f.CreationDate, f.Score, f.OwnerDisplayName, f.AnswerCount, f.TagList, ph.UserDisplayName, ph.CreationDate
ORDER BY 
    f.Score DESC, f.CreationDate DESC 
LIMIT 50;
