
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    up.DisplayName AS UserName,
    up.PostsCount,
    up.CommentsCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    pp.Title,
    pp.Score,
    pp.Rank,
    ts.TagName,
    ts.PostCount,
    ts.AvgViewCount,
    CASE 
        WHEN up.NetVotes > 0 THEN 'Positive'
        WHEN up.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    UserStats up
LEFT JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId AND pp.Rank <= 5
LEFT JOIN 
    TagSummary ts ON ts.PostCount > 10 
WHERE 
    up.PostsCount > 20
ORDER BY 
    up.GoldBadges DESC, up.NetVotes DESC, ts.AvgViewCount DESC
LIMIT 50;
