
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Questions only */
        AND p.ViewCount > 100
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        u.AccountId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location, u.AccountId
),

PopularTags AS (
    SELECT 
        Tag
    FROM (
        SELECT 
            UNNEST(string_to_array(LOWER(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2)), '><')) AS Tag
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1
    ) AS subquery
    GROUP BY 
        Tag
),

TagReputation AS (
    SELECT 
        t.Tag,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        PopularTags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.Tag, '%')
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.Tag
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.Location,
    ur.QuestionCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    (SELECT COUNT(DISTINCT ph.Id) FROM PostHistory ph 
     WHERE ph.UserId = ur.UserId AND ph.PostHistoryTypeId IN (10, 11)) AS ClosedReopenedPosts,
    tt.Tag,
    tt.TotalReputation
FROM 
    UserReputation ur
JOIN 
    TagReputation tt ON ur.QuestionCount > 5 
WHERE 
    ur.Reputation > 500 
ORDER BY 
    ur.Reputation DESC, 
    tt.TotalReputation DESC
LIMIT 10;
