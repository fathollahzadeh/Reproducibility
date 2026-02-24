
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (1, 6) THEN 1 ELSE 0 END), 0) AS AcceptedCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.PostCreationDate,
        pd.Upvotes,
        pd.Downvotes,
        pd.AcceptedCount,
        RANK() OVER (ORDER BY pd.Upvotes - pd.Downvotes DESC) AS PostRank
    FROM 
        PostDetails pd
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    rp.Title,
    rp.Upvotes,
    rp.Downvotes,
    rp.AcceptedCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Posts p
            WHERE p.OwnerUserId = ur.UserId AND p.CreationDate < CURRENT_DATE - INTERVAL '6 MONTH'
        ) THEN 'Has Older Posts'
        ELSE 'No Older Posts'
    END AS OldPostsFlag
FROM 
    UserReputation ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.PostId 
WHERE 
    ur.Reputation > 100
ORDER BY 
    ur.Reputation DESC,
    rp.Upvotes DESC;
