WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldCount,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverCount,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.PostCount, 0) AS RecentPosts,
        COALESCE(ub.GoldCount, 0) AS GoldCount,
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            Posts
        WHERE 
            CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        GROUP BY 
            OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.RecentPosts,
    ua.GoldCount,
    ua.SilverCount,
    ua.BronzeCount,
    pp.PostId,
    pp.Title,
    pp.Score,
    phd.HistoryTypes,
    phd.HistoryCount
FROM 
    UserActivity ua
LEFT JOIN RankedPosts pp ON ua.UserId = pp.OwnerUserId AND pp.rn <= 5
LEFT JOIN PostHistoryDetails phd ON pp.PostId = phd.PostId
WHERE 
    (ua.RecentPosts > 0 OR ua.GoldCount > 0)
AND 
    (pp.Score > (SELECT AVG(Score) FROM Posts) OR pp.Score IS NULL)
ORDER BY 
    ua.GoldCount DESC, 
    pp.Score DESC
LIMIT 50;