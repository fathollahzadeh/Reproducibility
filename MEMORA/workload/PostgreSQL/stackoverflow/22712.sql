
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE
            WHEN Reputation >= 10000 THEN 'Elite'
            WHEN Reputation >= 1000 THEN 'Experienced'
            WHEN Reputation >= 100 THEN 'Novice'
            ELSE 'Beginner'
        END AS ReputationLevel
    FROM 
        Users
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.Upvotes, 0) - COALESCE(v.Downvotes, 0) AS NetVotes,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
CommentAggregates AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MIN(CreationDate) AS FirstCommentDate,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
TagsExploded AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS TagPosition
    FROM 
        Posts p
    JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    ) AS t ON true
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.ReputationLevel,
    ps.Title,
    ps.Score,
    ps.NetVotes,
    ca.CommentCount,
    ca.FirstCommentDate,
    ca.LastCommentDate,
    te.TagName,
    te.TagPosition
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    PostScores ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    CommentAggregates ca ON ps.PostId = ca.PostId
LEFT JOIN 
    TagsExploded te ON ps.PostId = te.PostId AND te.TagPosition <= 3
WHERE 
    (ca.CommentCount > 5 OR ps.Score > 10)
    AND ur.ReputationLevel IN ('Experienced', 'Elite')
ORDER BY 
    ur.Reputation DESC, ps.NetVotes DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
