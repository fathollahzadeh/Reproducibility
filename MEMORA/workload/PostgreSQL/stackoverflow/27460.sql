
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        CONCAT(Users.DisplayName, ' (Reputation: ', Users.Reputation, ')') AS UserDisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName, Users.Reputation
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
ActiveUsers AS (
    SELECT 
        UserReputation.UserId,
        UserReputation.UserDisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT Posts.Id) AS QuestionCount
    FROM 
        UserReputation
    JOIN 
        Votes ON UserReputation.UserId = Votes.UserId
    JOIN 
        Posts ON Votes.PostId = Posts.Id
    GROUP BY 
        UserReputation.UserId, UserReputation.UserDisplayName
    HAVING 
        COUNT(DISTINCT Posts.Id) > 0
)
SELECT 
    t.Tag,
    t.PostCount,
    u.UserDisplayName,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.QuestionCount
FROM 
    TopTags t
JOIN 
    ActiveUsers u ON u.QuestionCount > 0
WHERE 
    t.TagRank <= 10  
ORDER BY 
    t.PostCount DESC, u.TotalUpVotes DESC;
