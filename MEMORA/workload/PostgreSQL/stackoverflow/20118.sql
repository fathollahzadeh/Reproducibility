
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS MostRecentEdit,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.Score,
        r.Id AS UserId,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
        phi.HistoryTypes,
        phi.MostRecentEdit
    FROM 
        RankedPosts rp
    JOIN 
        Users r ON rp.OwnerUserId = r.Id
    LEFT JOIN 
        UserBadges ub ON r.Id = ub.UserId
    LEFT JOIN 
        PostHistoryInfo phi ON rp.PostId = phi.PostId
)
SELECT 
    f.*,
    CASE 
        WHEN f.Score IS NULL THEN 'No votes yet'
        WHEN f.Score > 10 THEN 'Highly Rated'
        WHEN f.Score BETWEEN 1 AND 10 THEN 'Moderately Rated'
        ELSE 'Needs Improvement' 
    END AS Rating,
    CASE 
        WHEN f.BadgeCount = 0 THEN 'No badges'
        WHEN f.BadgeCount BETWEEN 1 AND 3 THEN 'Some badges'
        ELSE 'Many badges' 
    END AS BadgeStatus
FROM 
    FinalStats f
WHERE 
    f.CommentCount > 0 OR f.HistoryTypes IS NOT NULL
ORDER BY 
    f.CreationDate DESC;
