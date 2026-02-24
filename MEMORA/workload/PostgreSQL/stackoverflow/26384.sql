WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.AnswerCount IS NOT NULL THEN p.AnswerCount ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FinalBenchmark AS (
    SELECT 
        t.Tag,
        t.TagCount,
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.TotalViews,
        ur.TotalAnswers
    FROM 
        TopTags t
    JOIN 
        UserReputation ur ON ur.TotalViews > 10000 
)

SELECT 
    fb.Tag,
    fb.TagCount,
    COUNT(DISTINCT fb.UserId) AS UserCount,
    AVG(fb.Reputation) AS AvgReputation,
    SUM(fb.BadgeCount) AS TotalBadges,
    SUM(fb.TotalViews) AS TotalViews,
    SUM(fb.TotalAnswers) AS TotalAnswers
FROM 
    FinalBenchmark fb
GROUP BY 
    fb.Tag, fb.TagCount
ORDER BY 
    fb.TagCount DESC;