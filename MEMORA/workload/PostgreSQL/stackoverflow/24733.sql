WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1
        AND p.Score > 0
),
MostUpvotedPost AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
    ORDER BY 
        Upvotes DESC
    LIMIT 1
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.TotalBounty,
    COALESCE(rp.Title, 'No Top Post Found') AS TopPostTitle,
    COALESCE(rp.ViewCount, 0) AS TopPostViewCount,
    COALESCE(rp.AnswerCount, 0) AS TopPostAnswerCount,
    COALESCE(mpp.Upvotes, 0) AS MostUpvotedPostUpvotes,
    COALESCE(mpp.CommentCount, 0) AS MostUpvotedPostComments
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.PostsCreated = rp.Rank
LEFT JOIN 
    MostUpvotedPost mpp ON ua.UserId = mpp.OwnerUserId
ORDER BY 
    ua.Reputation DESC, ua.PostsCreated DESC
LIMIT 10;