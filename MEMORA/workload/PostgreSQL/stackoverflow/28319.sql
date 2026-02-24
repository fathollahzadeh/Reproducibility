
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score, p.OwnerUserId, p.CreationDate
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveResponses
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
FrequentTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
)
SELECT 
    tc.UserId,
    tc.DisplayName,
    tc.TotalScore,
    tc.QuestionCount,
    tc.PositiveResponses,
    COUNT(rp.PostId) AS RecentPostsCount,
    STRING_AGG(ft.TagName, ', ') AS MostFrequentTags
FROM 
    TopContributors tc
LEFT JOIN 
    RankedPosts rp ON tc.UserId = rp.OwnerUserId AND rp.UserPostRank <= 5
LEFT JOIN 
    FrequentTags ft ON ft.TagName IN (
        SELECT 
            TagName
        FROM 
            FrequentTags
        ORDER BY 
            TagFrequency DESC
        LIMIT 5
    )
GROUP BY 
    tc.UserId, tc.DisplayName, tc.TotalScore, tc.QuestionCount, tc.PositiveResponses
ORDER BY 
    tc.TotalScore DESC;
