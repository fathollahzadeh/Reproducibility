
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.ViewCount
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
        LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 
        LEFT JOIN Votes v ON a.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    u.DisplayName AS Owner,
    u.QuestionsAsked,
    u.AnswersGiven,
    u.TotalAnswerScore,
    u.TotalBounties,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM PopularTags tag) AS TopTags
FROM 
    RankedPosts p
JOIN 
    UserActivity u ON p.OwnerUserId = u.UserId
WHERE 
    p.rn = 1 
ORDER BY 
    p.ViewCount DESC
LIMIT 20;
