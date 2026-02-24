
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostRankings AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.RowNum,
        rp.CommentCount,
        COALESCE(pa.OwnerUserId, -1) AS AcceptedAnswerOwner
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts pa ON rp.AcceptedAnswerId = pa.Id
    WHERE 
        rp.RowNum = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ScoreAndBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        ub.BadgeCount,
        ub.Badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, ub.BadgeCount, ub.Badges
)
SELECT 
    ur.UserId,
    ur.TotalScore,
    ur.BadgeCount,
    ur.Badges,
    COALESCE(rp.Title, 'No Posts') AS LastPostTitle,
    rp.CreationDate AS LastPostDate,
    CASE 
        WHEN rp.AcceptedAnswerOwner IS NOT NULL THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    CASE 
        WHEN ur.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    ScoreAndBadges ur
LEFT JOIN 
    PostRankings rp ON ur.UserId = rp.AcceptedAnswerOwner
WHERE 
    ur.TotalScore > 0 OR ur.BadgeCount > 0
ORDER BY 
    ur.TotalScore DESC, ur.BadgeCount DESC
LIMIT 10;
