
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year') 
        AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.VoteTypeId) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 month')
    GROUP BY 
        v.PostId
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        rv.LastVoteDate
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN 
        UserStatistics us ON u.Id = us.UserId
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.Score,
    cs.ViewCount,
    cs.CommentCount,
    cs.OwnerDisplayName,
    cs.OwnerReputation,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.RecentVoteCount,
    cs.LastVoteDate,
    CASE 
        WHEN cs.OwnerReputation = (SELECT MAX(Reputation) FROM Users) THEN 'Top Reputation'
        ELSE 'Normal User'
    END AS UserCategory,
    CASE 
        WHEN cs.RecentVoteCount > 10 THEN 'Highly Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    CombinedStats cs
WHERE 
    cs.ViewCount > 100
    AND cs.CommentCount > 5
ORDER BY 
    cs.Score DESC, 
    cs.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
