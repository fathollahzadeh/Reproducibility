WITH TagCounts AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(CommentsCount, 0)) AS TotalComments,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentsCount 
         FROM Comments 
         GROUP BY PostId) c ON c.PostId = p.Id
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagId, 
        TagName, 
        PostCount
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC 
    LIMIT 10
)
SELECT 
    u.DisplayName AS ActiveUser,
    u.PostsCount,
    u.TotalComments,
    u.TotalUpVotes,
    u.TotalDownVotes,
    t.TagName,
    t.PostCount
FROM 
    MostActiveUsers u
JOIN 
    TopTags t ON u.PostsCount > 5
ORDER BY 
    u.TotalUpVotes DESC, 
    t.PostCount DESC;
