WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(CAST(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) / 86400 AS INT), 0) AS DaysSincePosted
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND (p.Score >= 0 OR p.AcceptedAnswerId IS NOT NULL)
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation < 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM 
        Users u
),
PostRanking AS (
    SELECT 
        ps.*,
        ur.ReputationCategory,
        ROW_NUMBER() OVER (PARTITION BY ur.ReputationCategory ORDER BY ps.UpvoteCount DESC) AS RankWithinCategory
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    p.Title,
    p.CommentCount,
    p.UpvoteCount,
    p.DownvoteCount,
    p.DaysSincePosted,
    p.ReputationCategory,
    p.RankWithinCategory
FROM 
    PostRanking p
WHERE 
    (p.UpvoteCount > 10 OR p.CommentCount > 5)
    AND p.RankWithinCategory <= 10
ORDER BY 
    p.ReputationCategory, p.UpvoteCount DESC;