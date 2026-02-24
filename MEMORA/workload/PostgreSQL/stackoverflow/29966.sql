
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.AcceptedAnswerId IS NOT NULL 
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    rp.Body AS PostBody,
    rp.CreationDate AS PostCreationDate,
    pu.DisplayName AS AuthorDisplayName,
    pu.Reputation AS AuthorReputation,
    ts.Tag AS PopularTag,
    ts.TagCount AS TagUsageCount,
    tb.BadgeCount AS AuthorGoldBadgeCount,
    tb.BadgeNames AS AuthorGoldBadges
FROM 
    RankedPosts rp
JOIN 
    Users pu ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    TagStatistics ts ON ts.Tag IN (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
        FROM Posts p WHERE p.Id = rp.PostId
    )
LEFT JOIN 
    TopBadges tb ON tb.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
