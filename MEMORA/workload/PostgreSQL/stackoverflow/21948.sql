WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.CreationDate < (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '30 days') 
    GROUP BY 
        p.Id, p.OwnerUserId
), 
UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(p.ViewCount) AS TotalViews,
        AVG(ps.CommentCount) AS AverageComments,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, ',')) AS TagName) t ON TRUE
    GROUP BY 
        u.Id
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UserRank,
    p.PostId,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.TotalBountyAmount,
    a.PostsCreated,
    a.TotalViews,
    a.AverageComments,
    a.TagsUsed
FROM 
    RankedUsers u
LEFT JOIN 
    PostStatistics p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    UserPostActivity a ON u.UserId = a.UserId
WHERE 
    p.CommentRank <= 5 
    OR (p.UpVoteCount > p.DownVoteCount AND p.TotalBountyAmount > 0)
ORDER BY 
    u.Reputation DESC, p.CommentCount DESC;