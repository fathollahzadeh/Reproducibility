
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
), 
PostScores AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
), 
UserRanking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        ps.TotalScore,
        ps.PostCount,
        RANK() OVER (ORDER BY us.Reputation DESC, ps.TotalScore DESC) AS UserRank
    FROM 
        UserStatistics us
    JOIN 
        PostScores ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.Views,
    ur.TotalScore,
    ur.PostCount,
    ur.UserRank,
    COALESCE(t.TagName, 'No Tags') AS MostFrequentTag
FROM 
    UserRanking ur
LEFT JOIN 
    (
        SELECT 
            p.OwnerUserId, 
            t.TagName,
            COUNT(*) AS TagCount
        FROM 
            Posts p,
            UNNEST(string_to_array(p.Tags, '><')) AS t(TagName)
        GROUP BY 
            p.OwnerUserId, t.TagName
        ORDER BY 
            TagCount DESC
    ) t ON ur.UserId = t.OwnerUserId
WHERE 
    ur.UserRank <= 100
ORDER BY 
    ur.UserRank;
