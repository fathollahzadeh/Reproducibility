WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Location,
    us.TotalPosts,
    rs.PostId,
    rs.Title,
    rs.CreationDate,
    rs.Score,
    rs.ViewCount,
    rs.CommentCount,
    rs.UpVotes,
    rs.DownVotes,
    CASE 
        WHEN us.Reputation >= 1000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel,
    EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = us.UserId 
        AND p.Score > 0
    ) AS HasPositivePosts
FROM 
    UserStatistics us
JOIN 
    RankedPosts rs ON us.UserId = rs.PostId
WHERE 
    us.TotalPosts > 0
AND 
    (us.Reputation > 500 OR rs.CommentCount > 5)
ORDER BY 
    us.Reputation DESC, rs.Score DESC
LIMIT 100;