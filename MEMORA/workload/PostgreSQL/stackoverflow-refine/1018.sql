WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as RankPerUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostsWithBadges AS (
    SELECT 
        up.UserId,
        up.Upvotes,
        up.Downvotes,
        up.BadgeCount,
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.RankPerUser
    FROM 
        UserStats up
    JOIN 
        RankedPosts rp ON up.UserId = rp.OwnerUserId
)
SELECT 
    pb.UserId,
    u.DisplayName,
    pb.Title,
    pb.Score,
    pb.Upvotes,
    pb.Downvotes,
    pb.BadgeCount,
    CASE 
        WHEN pb.RankPerUser = 1 THEN 'Top Post' 
        WHEN pb.RankPerUser <= 3 THEN 'High Ranking Post' 
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    PostsWithBadges pb
JOIN 
    Users u ON pb.UserId = u.Id
WHERE 
    pb.Upvotes - pb.Downvotes > 5 
    AND EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = pb.UserId 
        AND p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months'
    )
ORDER BY 
    pb.Score DESC, 
    pb.BadgeCount DESC;