WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS AnswerId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.AnswerId
    WHERE 
        p.PostTypeId = 1
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY UserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ' | ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    ub.BadgeCount,
    ub.BadgeNames,
    COALESCE(ph.HistoryComments, 'No recent changes') AS RecentHistory
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.PostId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank = 1 AND 
    (ub.BadgeCount > 3 OR ub.BadgeNames IS NOT NULL)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 50;