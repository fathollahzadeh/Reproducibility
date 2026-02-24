
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
TopContributors AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.TotalBounty,
        us.BadgeCount,
        rp.PostId,
        rp.Title,
        rp.RankScore,
        rp.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY rp.RankScore) AS UserPostRank
    FROM 
        UserStats us
    JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
)
SELECT 
    t.UserId,
    u.DisplayName,
    t.Title,
    t.RankScore,
    t.CommentCount,
    t.TotalBounty,
    t.BadgeCount
FROM 
    TopContributors t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.UserPostRank = 1
ORDER BY 
    t.TotalBounty DESC
LIMIT 10;
