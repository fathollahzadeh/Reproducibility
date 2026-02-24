
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
),
FinalOutput AS (
    SELECT 
        up.UserId,
        up.BadgeCount,
        up.BadgeNames,
        rp.Title,
        rp.CreationDate,
        rp.Upvotes,
        rp.Downvotes,
        RANK() OVER (PARTITION BY up.UserId ORDER BY rp.Upvotes DESC) AS RankBasedOnUpvotes
    FROM 
        UserBadges up
    JOIN 
        RecentPosts rp ON up.UserId = rp.OwnerUserId
    WHERE 
        up.BadgeCount > 0
)
SELECT 
    UserId,
    BadgeCount,
    BadgeNames,
    COUNT(Title) AS PostCount,
    SUM(Upvotes) AS TotalUpvotes,
    SUM(Downvotes) AS TotalDownvotes,
    MIN(CreationDate) AS FirstPostDate,
    MAX(CreationDate) AS LastPostDate,
    MAX(RankBasedOnUpvotes) AS MaxRankBasedOnUpvotes
FROM 
    FinalOutput
GROUP BY 
    UserId, BadgeCount, BadgeNames
ORDER BY 
    TotalUpvotes DESC
LIMIT 10;
