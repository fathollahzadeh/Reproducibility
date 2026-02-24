
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.Reputation
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS QuestionCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),

UserTags AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS UserTags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        LATERAL unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ur.Reputation,
    ur.TotalQuestions,
    ur.PositiveScoredQuestions,
    ut.UserTags,
    ts.QuestionCount AS TagQuestionCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
JOIN 
    UserTags ut ON rp.OwnerUserId = ut.UserId
JOIN 
    TagStatistics ts ON ts.TagName = ANY(string_to_array(rp.Tags, '>'))
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC;
