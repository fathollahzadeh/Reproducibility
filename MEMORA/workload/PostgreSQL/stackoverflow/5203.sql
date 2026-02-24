
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS RankView
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    ub.BadgeCount,
    rp.RankScore,
    rp.RankView
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = (SELECT U.DisplayName FROM Users U WHERE U.Id = ub.UserId)
WHERE 
    rp.RankScore <= 10 AND rp.RankView <= 10
ORDER BY 
    rp.RankScore, rp.RankView;
