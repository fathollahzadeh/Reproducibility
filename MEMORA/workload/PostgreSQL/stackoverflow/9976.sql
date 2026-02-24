WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        AVG(u.Reputation) AS AvgReputation,
        MAX(p.CreationDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ph.Comment, 'No comment') AS LastEditComment,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
    GROUP BY 
        p.Id, p.Title, ph.Comment
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.Questions,
        ua.Answers,
        ua.Wikis,
        ua.TagWikis,
        ua.AvgReputation,
        ua.LastActiveDate,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes
    FROM 
        UserActivity ua
    JOIN 
        PostStatistics ps ON ua.UserId = ps.PostId
    ORDER BY 
        ua.PostCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.Questions,
    tu.Answers,
    tu.Wikis,
    tu.TagWikis,
    tu.AvgReputation,
    tu.LastActiveDate,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes
FROM 
    TopUsers tu
JOIN 
    PostStatistics ps ON tu.PostCount = ps.PostId
ORDER BY 
    tu.AvgReputation DESC;