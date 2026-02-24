
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        CASE 
            WHEN COUNT(DISTINCT p.Id) > 10 THEN 'Active'
            ELSE 'Novice'
        END AS UserExperience
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        pt.Name AS PostHistoryType,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name LIKE '%Closed%'
    GROUP BY 
        ph.PostId, pt.Name
)
SELECT 
    up.DisplayName AS UserName,
    rp.Title AS QuestionTitle,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViews,
    us.QuestionsAnswered,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.UserExperience,
    cp.CloseCount AS TotalClosures,
    cp.LastClosed
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserStats us ON us.UserId = up.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.Id
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
