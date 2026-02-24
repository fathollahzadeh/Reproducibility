WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum,
        COALESCE(u.DisplayName, 'Community User') AS UserDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year' AND
        b.Class = 1 
    GROUP BY 
        b.UserId
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(rp.RowNum, 0) AS Rank,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    LEFT JOIN 
        UserBadges ub ON p.OwnerUserId = ub.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.Score > 0 AND 
        NOT EXISTS (SELECT 1 FROM RecentClosedPosts rcp WHERE rcp.PostId = p.Id) 
    GROUP BY 
        p.Id, p.Title, p.Score, rp.RowNum, ub.BadgeCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.Rank,
        ps.UserBadgeCount,
        CASE 
            WHEN ps.Rank = 1 THEN 'Top Post'
            WHEN ps.Rank BETWEEN 2 AND 5 THEN 'Hot Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        CASE 
            WHEN ps.UserBadgeCount > 0 THEN CONCAT('User has ', ps.UserBadgeCount, ' gold badges: ', ub.BadgeNames)
            ELSE 'User has no gold badges.'
        END AS UserBadgeInfo
    FROM 
        PostStatistics ps
    LEFT JOIN 
        UserBadges ub ON ps.UserBadgeCount = ub.BadgeCount
    WHERE 
        ps.Rank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.Rank,
    tp.PostCategory,
    tp.UserBadgeInfo,
    tp.UserBadgeCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.Rank;