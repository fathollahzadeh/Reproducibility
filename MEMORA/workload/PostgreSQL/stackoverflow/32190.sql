
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(COUNT(c.Id) OVER (PARTITION BY p.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosters AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPostScore,
        TotalPosts,
        TotalComments,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY TotalPostScore DESC) AS rn
    FROM 
        UserStats
)
SELECT 
    t.DisplayName,
    t.TotalPostScore,
    t.TotalPosts,
    t.TotalComments,
    t.TotalBadges,
    rp.Title,
    rp.Score AS PostScore,
    rp.CreationDate,
    (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
    CASE 
        WHEN rp.CommentCount IS NULL THEN 'No Comments' 
        ELSE CONCAT(rp.CommentCount, ' Comments') 
    END AS CommentInfo
FROM 
    TopPosters t
LEFT JOIN 
    RankedPosts rp ON t.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    t.TotalPosts > 5
ORDER BY 
    t.TotalPostScore DESC, 
    rp.Score DESC
LIMIT 10;
