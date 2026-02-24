WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.QuestionsCount,
        us.AnswersCount,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
), 
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    tb.UserRank,
    ub.BadgeNames,
    rb.PostCount,
    rb.AvgScore
FROM 
    Users u
LEFT JOIN 
    TopUsers tb ON u.Id = tb.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2)
    GROUP BY 
        OwnerUserId
) rb ON u.Id = rb.OwnerUserId
WHERE 
    tb.UserRank <= 10 OR tb.UserRank IS NULL
ORDER BY 
    COALESCE(tb.UserRank, 999), 
    u.Reputation DESC;
