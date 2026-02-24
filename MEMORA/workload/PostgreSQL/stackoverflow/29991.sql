
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TagPopularity AS (
    SELECT 
        pt.Tag,
        COUNT(pt.PostId) AS NumberOfPosts
    FROM 
        PostTags pt
    GROUP BY 
        pt.Tag
    ORDER BY 
        NumberOfPosts DESC
    LIMIT 10 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.QuestionsAsked,
    us.TotalUpVotes,
    us.TotalDownVotes,
    tp.Tag,
    tp.NumberOfPosts
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
JOIN 
    TagPopularity tp ON tp.Tag IN (
        SELECT UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1
    )
ORDER BY 
    us.TotalUpVotes DESC, 
    us.QuestionsAsked DESC;
