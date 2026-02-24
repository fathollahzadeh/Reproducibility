WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS RankByScore,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.Id
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerUserId,
    rp.OwnerDisplayName,
    rp.Tags,
    rp.RankByScore,
    tp.Tag AS MostUsedTag,
    us.DisplayName AS UserDisplayName,
    us.Reputation,
    us.PostCount,
    us.PositivePosts,
    us.NegativePosts,
    us.BadgesEarned
FROM 
    RankedPosts rp
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
JOIN 
    TagPopularity tp ON rp.Tags LIKE '%' || tp.Tag || '%'
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;