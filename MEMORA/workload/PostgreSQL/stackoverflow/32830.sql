WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(v.BountyAmount) AS TotalBountyGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
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
)
SELECT 
    up.UserId,
    up.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    up.QuestionsAsked,
    up.CommentsMade,
    up.TotalBountyGiven,
    rp.Title,
    rp.Score,
    rp.RankByScore,
    rph.Comment AS RecentComment,
    rph.CreationDate AS RecentActivityDate,
    rph.PostHistoryTypeName
FROM 
    UserActivity up
LEFT JOIN 
    UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.QuestionsAsked > 0 AND rp.RankByScore <= 5
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    (ub.BadgeCount IS NULL OR ub.BadgeCount > 0) 
ORDER BY 
    up.TotalBountyGiven DESC,
    up.QuestionsAsked DESC,
    rp.Score DESC;