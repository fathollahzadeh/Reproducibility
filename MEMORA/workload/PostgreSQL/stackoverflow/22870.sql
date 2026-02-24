WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS UserPostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS Count
        FROM 
            Badges
        GROUP BY UserId
    ) b ON u.Id = b.UserId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.BadgeCount,
        CASE 
            WHEN rp.UserPostRank = 1 THEN 'Top Post'
            ELSE 'Other Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.UserPostCount > 5
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalMetrics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.Reputation,
        ps.BadgeCount,
        rc.CommentCount,
        rc.LastCommentDate,
        CASE 
            WHEN rc.CommentCount IS NULL THEN 'No Comments'
            ELSE 
                CASE 
                    WHEN rc.CommentCount > 5 THEN 'Highly Discussed'
                    ELSE 'Moderately Discussed'
                END
        END AS DiscussionLevel
    FROM 
        PostStatistics ps
    LEFT JOIN 
        RecentComments rc ON ps.PostId = rc.PostId
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.Score,
    fm.ViewCount,
    fm.Reputation,
    fm.BadgeCount,
    fm.CommentCount,
    fm.LastCommentDate,
    fm.DiscussionLevel,
    CASE 
        WHEN fm.Reputation > 1000 THEN 'High Reputation'
        WHEN fm.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN fm.LastCommentDate IS NULL THEN 'Comments Not Available'
        ELSE 
            CASE 
                WHEN fm.LastCommentDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Recent Activity'
                ELSE 'Older Activity'
            END
    END AS ActivityRecency
FROM 
    FinalMetrics fm
ORDER BY 
    fm.Score DESC, 
    fm.ViewCount DESC
LIMIT 100;