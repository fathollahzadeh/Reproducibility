
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY (SELECT COUNT(*) FROM UNNEST(string_to_array(p.Tags, ','))) ORDER BY p.CreationDate DESC) AS RankByTagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts p,
        UNNEST(string_to_array(p.Tags, ',')) AS tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TRIM(tag)
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostId,
    p.Title,
    rt.TagName,
    u.DisplayName AS Author,
    u.QuestionCount,
    u.TotalBadges,
    u.TotalBounty
FROM 
    RankedPosts p
JOIN 
    PopularTags rt ON rt.TagName = ANY(string_to_array(p.Tags, ','))
JOIN 
    UserActivities u ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
WHERE 
    p.RankByTagCount <= 5 
ORDER BY 
    rt.PostCount DESC, 
    p.CreationDate DESC;
