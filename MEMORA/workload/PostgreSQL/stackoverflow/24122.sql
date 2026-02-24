WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
VoteDetails AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS NetVotes
    FROM Votes v
    WHERE v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY v.PostId
)

SELECT 
    ur.UserId, 
    ur.DisplayName, 
    ur.Reputation, 
    ur.ReputationCategory, 
    pd.PostId, 
    pd.Title, 
    pd.CreationDate, 
    pd.Score, 
    pd.ViewCount, 
    pd.AnswerCount, 
    COALESCE(vd.NetVotes, 0) AS NetVotes,
    pd.Tags,
    ph.Comment AS LastPostHistoryComment,
    CTE_RolledBackPosts.TotalRolledBackPosts AS RolledBackPostsCount
FROM UserReputation ur
JOIN PostDetails pd ON ur.UserId = pd.OwnerUserId
LEFT JOIN VoteDetails vd ON pd.PostId = vd.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS TotalRolledBackPosts 
    FROM PostHistory 
    WHERE PostHistoryTypeId IN (7, 8, 9)
    GROUP BY PostId
) CTE_RolledBackPosts ON pd.PostId = CTE_RolledBackPosts.PostId
LEFT JOIN PostHistory ph ON pd.PostId = ph.PostId AND ph.UserId IS NOT NULL
WHERE ur.ReputationRank <= 100 
AND pd.CreationDate < cast('2024-10-01' as date) - INTERVAL '30 days'
ORDER BY ur.Reputation DESC, pd.ViewCount DESC;