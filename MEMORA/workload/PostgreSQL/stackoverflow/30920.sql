WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        pt.Name AS PostType,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
MaxComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RepRank
    FROM 
        Users u
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostsStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(mc.CommentCount, 0) AS TotalComments,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        pp.HistoryRank,
        p.Score,
        p.ViewCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        MaxComments mc ON p.Id = mc.PostId
    JOIN 
        RecursivePostHistory pp ON p.Id = pp.PostId
    LEFT JOIN 
        UserBadges ub ON p.OwnerUserId = ub.UserId
    WHERE 
        pp.HistoryRank = 1
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.TotalComments,
        ps.UserBadgeCount,
        ps.Score,
        ps.ViewCount,
        DENSE_RANK() OVER (ORDER BY ps.Score DESC) AS PostRank
    FROM 
        PostsStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.TotalComments,
    tp.UserBadgeCount,
    tp.Score,
    CASE 
        WHEN tp.ViewCount > 1000 THEN 'High Views'
        WHEN tp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Views'
        ELSE 'Low Views'
    END AS ViewCategory,
    CASE 
        WHEN tr.RepRank <= 10 THEN 'Top Reputation'
        ELSE 'Regular' 
    END AS OwnerReputationCategory
FROM 
    TopPosts tp
LEFT JOIN 
    UserReputation tr ON tp.UserBadgeCount = tr.UserId
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.Score DESC, 
    tp.TotalComments DESC;