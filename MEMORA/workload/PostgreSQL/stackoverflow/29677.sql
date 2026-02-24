
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 100 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000 
),
QuestionStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        t.Tag AS PopularTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        TopTags t ON t.Tag = ANY(string_to_array(trim(both '<>' from p.Tags), '><'))
    WHERE 
        p.PostTypeId = 1 
),
FinalReport AS (
    SELECT 
        qs.PostId,
        qs.Title,
        qs.ViewCount,
        qs.CreationDate,
        qs.Owner,
        pu.DisplayName AS PopularOwner,
        pu.Reputation,
        pu.BadgeCount
    FROM 
        QuestionStats qs
    JOIN 
        PopularUsers pu ON qs.Owner = pu.DisplayName
    ORDER BY 
        qs.ViewCount DESC
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.ViewCount,
    FR.CreationDate,
    FR.Owner,
    FR.PopularOwner,
    FR.Reputation,
    FR.BadgeCount
FROM 
    FinalReport FR
WHERE 
    FR.Reputation > 5000 
LIMIT 50;
