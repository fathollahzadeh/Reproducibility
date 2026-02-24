
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(value), ',') AS Tags
    FROM 
        Posts p,
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS value
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
PostHistoryWithTagCounts AS (
    SELECT 
        pt.PostId,
        COUNT(ph.Id) AS EditCount,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END), 0) AS CloseStatus,
        MAX(pt.Tags) AS AllTags
    FROM 
        PostHistory ph
    JOIN 
        PostTags pt ON ph.PostId = pt.PostId
    GROUP BY 
        pt.PostId
),
Summary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.CommentCount,
        rp.ViewCount,
        rp.Score,
        ptwi.EditCount,
        ptwi.CloseStatus,
        ptwi.AllTags,
        rp.UserPostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryWithTagCounts ptwi ON rp.PostId = ptwi.PostId
)
SELECT 
    *,
    CASE 
        WHEN CloseStatus = 1 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN UserPostRank = 1 THEN 'Most Recent'
        ELSE CAST(UserPostRank AS VARCHAR)
    END AS RankStatus
FROM 
    Summary
WHERE 
    AnswerCount > 0
ORDER BY 
    CreationDate DESC
LIMIT 100;
