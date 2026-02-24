WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostAndUserStats AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        ur.Reputation,
        ur.ReputationCategory,
        rp.Score AS PostScore,
        rp.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    puas.PostId,
    puas.Reputation,
    puas.ReputationCategory,
    puas.PostScore,
    puas.CommentCount,
    puas.UpVotes,
    puas.DownVotes,
    CASE 
        WHEN puas.CommentCount > 10 THEN 'Highly Engaged'
        WHEN puas.CommentCount BETWEEN 1 AND 10 THEN 'Moderately Engaged'
        ELSE 'Not Engaged'
    END AS EngagementLevel
FROM 
    PostAndUserStats puas
WHERE 
    puas.PostScore > 5
    AND EXISTS (
        SELECT 1 
        FROM Posts p
        WHERE p.AcceptedAnswerId = puas.PostId 
          AND p.OwnerUserId IS NOT NULL
          AND p.PostTypeId = 2
    )
ORDER BY 
    puas.Reputation DESC,
    puas.CommentCount DESC
LIMIT 50;