
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '> <')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pt.TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        LATERAL UNNEST(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '> <')) AS pt(TagName) ON TRUE
    WHERE 
        pt.TagName IN (SELECT TagName FROM PopularTags)
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, pt.TagName
)
SELECT 
    ps.OwnerDisplayName,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TagName,
    ps.CommentCount,
    RANK() OVER (PARTITION BY ps.TagName ORDER BY ps.Score DESC) AS ScoreRank
FROM 
    PostStatistics ps
ORDER BY 
    ps.TagName, ScoreRank;
