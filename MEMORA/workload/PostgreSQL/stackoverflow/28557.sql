
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopReputedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        PositiveScorePosts,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        Reputation > 0
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
ProminentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.EditCount,
        ps.RelatedPostsCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS PopularityRank
    FROM 
        PostStats ps
    WHERE 
        ps.CommentCount > 5
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    pp.Title AS PopularPostTitle,
    pp.UpVotes,
    pp.DownVotes,
    pp.CommentCount AS Comments,
    pp.EditCount AS Edits,
    pp.RelatedPostsCount AS RelatedLinks
FROM 
    TopReputedUsers u
JOIN 
    ProminentPosts pp ON u.TotalPosts > 10
WHERE 
    pp.PopularityRank <= 10
ORDER BY 
    u.Reputation DESC, pp.UpVotes DESC;
