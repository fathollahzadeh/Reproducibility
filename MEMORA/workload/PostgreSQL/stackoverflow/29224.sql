WITH 
    PostTags AS (
        SELECT 
            p.Id AS PostId,
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
        FROM Posts p
        WHERE p.PostTypeId = 1 
    ),
    UserReputation AS (
        SELECT 
            u.Id AS UserId,
            u.Reputation,
            COUNT(b.Id) AS BadgeCount
        FROM Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        GROUP BY u.Id, u.Reputation
    ),
    PopularTags AS (
        SELECT 
            Tag,
            COUNT(*) AS TagCount
        FROM PostTags
        GROUP BY Tag
        HAVING COUNT(*) > 5 
    ),
    UserContribution AS (
        SELECT 
            p.OwnerUserId,
            SUM(p.ViewCount) AS TotalViews,
            SUM(p.Score) AS TotalScore
        FROM Posts p
        WHERE p.PostTypeId IN (1, 2) 
        GROUP BY p.OwnerUserId
    )
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    uc.TotalViews,
    uc.TotalScore,
    bt.Tag AS PopularTag,
    ur.BadgeCount
FROM Users u
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN UserContribution uc ON u.Id = uc.OwnerUserId
JOIN PopularTags bt ON u.Id IS NOT NULL 
WHERE 
    u.Reputation > 100 
ORDER BY 
    u.Reputation DESC, 
    uc.TotalViews DESC
LIMIT 10;