WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.Reputation
    HAVING 
        u.Reputation > 1000 OR COUNT(b.Id) > 3
),
PostAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.Score,
        ut.Reputation AS UserReputation,
        pt.Name AS PostTypeName,
        STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags tg ON p.Tags LIKE CONCAT('%', tg.TagName, '%')
    LEFT JOIN 
        UserReputation ut ON u.Id = ut.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CommentCount, rp.Score, ut.Reputation, pt.Name
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.Score,
    pa.UserReputation,
    pa.PostTypeName,
    pa.Tags,
    CASE 
        WHEN pa.CommentCount > 10 AND pa.Score > 50 THEN 'Highly Engaging'
        WHEN pa.CommentCount > 5 THEN 'Moderately Engaging'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostAnalysis pa
JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    pa.UserReputation IS NOT NULL
ORDER BY 
    pa.Score DESC, pa.CommentCount DESC
LIMIT 100;