
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.TotalComments,
        ps.HasAcceptedAnswer,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.CommentCount,
    ur.UpVotes,
    ur.DownVotes,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostCreationDate,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.TotalComments AS TopPostTotalComments,
    tp.HasAcceptedAnswer AS TopPostHasAcceptedAnswer
FROM 
    UserReputation ur
JOIN 
    TopPosts tp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.Reputation DESC, tp.Score DESC
LIMIT 10;
