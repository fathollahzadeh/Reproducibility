WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(lp.LikeCount, 0) AS TotalLikes,
        (u.UpVotes - u.DownVotes) AS NetVotes
    FROM 
        Users u
    LEFT JOIN PostComments pc ON u.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            COUNT(v.Id) AS LikeCount
        FROM 
            Votes v
        INNER JOIN Posts p ON p.Id = v.PostId
        WHERE 
            v.VoteTypeId = 2 
        GROUP BY 
            p.OwnerUserId
    ) lp ON u.Id = lp.OwnerUserId
),
FinalScores AS (
    SELECT 
        rs.PostId,
        rs.Title,
        rs.CreationDate,
        us.Reputation,
        us.TotalComments,
        us.TotalLikes,
        us.NetVotes,
        (us.Reputation * 0.5 + us.TotalComments * 0.3 + us.TotalLikes * 0.2) AS WeightedScore
    FROM 
        RankedPosts rs
    JOIN UserScores us ON rs.PostId = us.UserId
    WHERE 
        us.Reputation > 100
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Reputation,
    TotalComments,
    TotalLikes,
    WeightedScore
FROM 
    FinalScores
WHERE 
    WeightedScore > 10
ORDER BY 
    WeightedScore DESC;