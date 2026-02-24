
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(p.Score) AS TotalPostScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT bh.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    WHERE 
        u.Reputation >= 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.TotalBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.PostRank
FROM 
    UserActivities ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    ua.Reputation DESC, 
    rp.Score DESC;
