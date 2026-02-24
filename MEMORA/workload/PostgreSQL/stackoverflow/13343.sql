WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        UpVotes,
        DownVotes,
        Views
    FROM 
        Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        p.LastActivityDate,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.CreationDate, p.LastActivityDate, p.Title
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    u.UserId,
    u.Reputation,
    ps.PostId,
    ps.ViewCount,
    ps.Score,
    ps.TotalComments,
    tu.TagName,
    tu.PostCount AS TagsUsed,
    COALESCE(ps.AverageBounty, 0) AS AverageBounty
FROM 
    UserReputation u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
JOIN 
    PostStatistics ps ON p.Id = ps.PostId
JOIN 
    TagUsage tu ON p.Tags LIKE CONCAT('%', tu.TagName, '%')
ORDER BY 
    u.Reputation DESC, ps.ViewCount DESC
LIMIT 100;