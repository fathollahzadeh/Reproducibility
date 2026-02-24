WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRanking,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS PostHistoryTypes
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS Author,
    up.PostId,
    up.Title,
    up.ViewCount,
    up.UserRanking,
    ub.BadgeCount,
    ub.MaxBadgeClass,
    pht.PostHistoryTypes,
    (up.UpVotes - up.DownVotes) AS NetVotes,
    CASE 
        WHEN up.UserRanking < 5 THEN 'New Contributor'
        WHEN ub.BadgeCount > 10 AND ub.MaxBadgeClass = 1 THEN 'Influencer'
        ELSE 'Regular User'
    END AS UserType
FROM 
    RankedPosts up
JOIN 
    Users u ON up.PostId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryTags pht ON up.PostId = pht.PostId
WHERE 
    pht.PostHistoryTypes IS NOT NULL
ORDER BY 
    NetVotes DESC,
    up.CreationDate ASC
LIMIT 50;