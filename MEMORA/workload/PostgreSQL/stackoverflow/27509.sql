
WITH CTE_CreatedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, u.DisplayName, p.Tags
),
CTE_LastEdits AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 9) 
    GROUP BY 
        p.Id
),
CTE_TopTags AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts, 
        UNNEST(string_to_array(Tags, ',')) AS value
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    cp.PostId, 
    cp.Title, 
    cp.CreationDate, 
    cp.OwnerDisplayName, 
    cp.AnswerCount, 
    cp.CommentCount, 
    cp.VoteCount, 
    le.LastEditDate,
    tt.Tag AS TopTag,
    tt.TagCount
FROM 
    CTE_CreatedPosts cp
JOIN 
    CTE_LastEdits le ON cp.PostId = le.PostId
JOIN 
    CTE_TopTags tt ON tt.Tag = ANY(string_to_array(cp.Tags, ','))
WHERE 
    cp.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
ORDER BY 
    cp.VoteCount DESC, 
    cp.CreationDate DESC;
