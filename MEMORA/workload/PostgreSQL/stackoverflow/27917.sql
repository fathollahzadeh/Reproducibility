WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount >= 10  
),
UsersEngaged AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ue.QuestionCount,
        ue.UpVotes,
        ue.DownVotes
    FROM 
        Users u
    JOIN 
        UsersEngaged ue ON u.Id = ue.OwnerUserId
)
SELECT 
    upr.DisplayName,
    upr.Reputation,
    upr.QuestionCount,
    upr.UpVotes,
    upr.DownVotes,
    pt.Tag AS PopularTag
FROM 
    UserReputation upr
JOIN 
    PopularTags pt ON upr.QuestionCount >= 5  
ORDER BY 
    upr.Reputation DESC, upr.QuestionCount DESC;