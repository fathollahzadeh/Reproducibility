
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) >= 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
FinalRanking AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.PostCount,
        tu.TotalScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        DENSE_RANK() OVER (ORDER BY tu.TotalScore DESC, tu.Reputation DESC) AS UserRank
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.Reputation,
    fr.PostCount,
    fr.TotalScore,
    fr.BadgeCount,
    fr.UserRank,
    rp.Title AS BestPostTitle,
    rp.CreationDate AS BestPostDate,
    rp.Score AS BestPostScore
FROM 
    FinalRanking fr
LEFT JOIN 
    RankedPosts rp ON fr.UserId = rp.OwnerUserId AND rp.Rank = 1
ORDER BY 
    fr.UserRank;
