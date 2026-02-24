
WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 AND v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTH' THEN 1 ELSE 0 END), 0) AS RecentUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 AND v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTH' THEN 1 ELSE 0 END), 0) AS RecentDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostLinksData AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount,
        MAX(pl.CreationDate) AS LastLinkDate
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
CombinedData AS (
    SELECT 
        ra.PostId,
        ra.Title,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        pl.RelatedPostsCount,
        pl.LastLinkDate
    FROM 
        RecentActivity ra
    JOIN 
        UserStats us ON us.UserId = ra.OwnerUserId
    LEFT JOIN 
        PostLinksData pl ON pl.PostId = ra.PostId
    WHERE 
        ra.ActivityRank = 1
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.OwnerDisplayName,
    cd.OwnerReputation,
    COALESCE(cd.RelatedPostsCount, 0) AS RelatedCount,
    CASE WHEN cd.LastLinkDate IS NULL THEN 'No links' ELSE 'Links available' END AS LinkStatus
FROM 
    CombinedData cd
ORDER BY 
    cd.OwnerReputation DESC,
    cd.LastLinkDate DESC NULLS LAST;
