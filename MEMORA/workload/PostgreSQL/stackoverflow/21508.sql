WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC NULLS LAST) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score >= 0
),
HighScoringPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE NULL
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS HistCreationDate,
        p.Title AS PostTitle,
        ph.UserDisplayName,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND ph.PostHistoryTypeId IN (10, 11, 12, 13) 
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
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Score,
    hsp.CommentCount,
    hsp.UpvoteCount,
    hsp.ScoreCategory,
    COALESCE(phd.ActionType, 'No Actions') AS MostRecentAction,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
    CASE 
        WHEN hsp.CommentCount = 0 THEN 'No Comments'
        WHEN hsp.UpvoteCount < 5 THEN 'Low Engagement'
        ELSE 'Engaged Post'
    END AS EngagementLevel
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    PostHistoryDetails phd ON hsp.PostId = phd.PostId
LEFT JOIN 
    Users u ON hsp.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    hsp.ScoreCategory IS NOT NULL
ORDER BY 
    hsp.CreationDate DESC NULLS LAST 
LIMIT 50;