WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        (u.UpVotes - u.DownVotes) AS VoteBalance,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
RecentPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON pl.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        pl.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.Views,
    up.VoteBalance,
    up.BadgeCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    rpl.RelatedPostCount
FROM 
    UserStats up
JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId
LEFT JOIN 
    RecentPostLinks rpl ON pp.PostId = rpl.PostId
WHERE 
    up.Reputation > 1000
    AND pp.PostRank <= 3
    AND (rpl.RelatedPostCount IS NULL OR rpl.RelatedPostCount > 2)
ORDER BY 
    up.Reputation DESC, pp.CreationDate DESC
LIMIT 10;