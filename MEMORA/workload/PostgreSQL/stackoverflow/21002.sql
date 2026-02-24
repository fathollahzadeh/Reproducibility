
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserPostRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Questions */
        AND p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank,
        rp.CommentCount,
        COALESCE(NULLIF((SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 8), 0), 0) AS AverageBountyAmount
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
        AND rp.CommentCount > 5
),
PostInteraction AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.AverageBountyAmount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         JOIN LATERAL (
             SELECT UNNEST(string_to_array(fp.Title, ' ')) AS Tag 
         ) AS split_tags ON t.TagName = split_tags.Tag) AS TagsList
    FROM 
        FilteredPosts fp
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)
SELECT 
    ua.DisplayName AS UserName,
    ua.Reputation,
    pa.PostId,
    pa.Title AS PostTitle,
    pa.CreationDate AS PostDate,
    pa.Score AS PostScore,
    pa.ViewCount,
    pa.AverageBountyAmount,
    pa.TagsList
FROM 
    UserActivity ua
INNER JOIN 
    PostInteraction pa ON ua.PostsCreated > 10
ORDER BY 
    ua.Reputation DESC,
    pa.Score DESC
LIMIT 100
OFFSET 0;
