
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

PostTags AS (
    SELECT 
        rp.PostId,
        unnest(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><')) AS Tag
    FROM 
        RankedPosts rp
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

TagPopularity AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        pt.Tag
    ORDER BY 
        PostCount DESC
)

SELECT 
    up.DisplayName AS TopUser,
    up.Reputation,
    ub.BadgeCount,
    tp.Tag,
    tp.PostCount,
    tp.AverageScore
FROM 
    Users up
JOIN 
    UserBadges ub ON up.Id = ub.UserId
JOIN 
    PostTags pta ON pta.Tag IN (
        SELECT Tag 
        FROM TagPopularity 
        WHERE PostCount > 5 
        ORDER BY AverageScore DESC 
        LIMIT 3 
    )
JOIN 
    TagPopularity tp ON pta.Tag = tp.Tag
ORDER BY 
    up.Reputation DESC 
LIMIT 10;
