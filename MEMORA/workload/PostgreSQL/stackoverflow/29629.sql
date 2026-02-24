
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
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        ARRAY_AGG(DISTINCT p.Id) AS PostIds 
    FROM 
        ProcessedTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS AnsweredQuestions,
        SUM(CASE WHEN v.voteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.voteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ts.Tag,
    ts.TagCount,
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.AnsweredQuestions,
    ur.UpVotes,
    ur.DownVotes
FROM 
    TagStatistics ts
JOIN 
    Users u ON u.Location LIKE CONCAT('%', ts.Tag, '%') 
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    ts.TagCount DESC, ur.Reputation DESC
LIMIT 10;
