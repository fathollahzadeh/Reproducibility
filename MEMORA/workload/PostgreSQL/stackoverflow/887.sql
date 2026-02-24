
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(bp.BadgeCount), 0) AS TotalBadges,
        COALESCE(SUM(rp.UpVoteCount - rp.DownVoteCount), 0) AS PostScore
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            b.UserId, 
            COUNT(b.Id) AS BadgeCount 
        FROM 
            Badges b 
        GROUP BY 
            b.UserId
    ) bp ON u.Id = bp.UserId
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalBadges,
    us.PostScore,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = us.UserId AND p.CreationDate < DATE('2024-10-01') - INTERVAL '1 year') AS OldPostCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     INNER JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%') 
     WHERE p.OwnerUserId = us.UserId) AS TagList
FROM 
    UserStats us
WHERE 
    us.TotalBadges > 3
ORDER BY 
    us.PostScore DESC, 
    us.Reputation DESC
LIMIT 10;
