
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 0 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.LastActivityDate
),

HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.CommentCount,
        rp.TagList,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5'
            ELSE 'Others'
        END AS PostRanking
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    hsp.Title,
    hsp.OwnerDisplayName,
    hsp.CreationDate,
    hsp.CommentCount,
    STRING_AGG(tag.tagname, ', ') AS Tags,
    CASE 
        WHEN hsp.CommentCount > 5 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    HighScorePosts hsp
JOIN 
    UNNEST(hsp.TagList) AS tag(tagname) ON true
GROUP BY 
    hsp.Title, hsp.OwnerDisplayName, hsp.CreationDate, hsp.CommentCount
ORDER BY 
    hsp.CommentCount DESC, hsp.CreationDate DESC
LIMIT 10;
