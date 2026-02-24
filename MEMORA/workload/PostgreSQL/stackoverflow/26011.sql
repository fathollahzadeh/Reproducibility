
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ARRAY_LENGTH(string_to_array(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><'), 1) AS TagCount,
        COALESCE(COUNT(c.Id) FILTER (WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, p.Score
),
FilteredPosts AS (
    SELECT 
        r.*,
        CASE 
            WHEN r.RankByScore <= 3 THEN 'Top Post'
            WHEN r.TagCount > 5 THEN 'Popular Tag'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts r
    WHERE 
        r.CommentCount > 10 
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.Score,
    fp.CommentCount,
    pht.EditCount,
    pht.LastEditDate,
    fp.PostCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistorySummary pht ON fp.PostId = pht.PostId
ORDER BY 
    fp.CreationDate DESC;
