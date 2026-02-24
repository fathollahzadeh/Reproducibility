
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class IN (1, 2, 3) 
    GROUP BY 
        u.Id, b.Class
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) 
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UserRank,
        ub.BadgeCount,
        CASE
            WHEN rph.HistoryCreationDate IS NOT NULL THEN 
                EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - rph.HistoryCreationDate)) / 3600 
            ELSE NULL
        END AS HoursSinceLastEdit
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UserRank,
    ps.BadgeCount,
    ps.HoursSinceLastEdit,
    CASE 
        WHEN ps.HoursSinceLastEdit < 24 THEN 'Recently Edited'
        WHEN ps.HoursSinceLastEdit IS NULL THEN 'Never Edited'
        ELSE 'Edited Long Ago'
    END AS EditStatus
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 0 
ORDER BY 
    ps.Score DESC, ps.UserRank ASC;
