WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation BETWEEN 100 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM Votes
    GROUP BY PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        pv.UpVotes,
        pv.DownVotes,
        CASE 
            WHEN pv.UpVotes > pv.DownVotes THEN 'Positive'
            WHEN pv.DownVotes > pv.UpVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM Posts p
    LEFT JOIN PostVoteCounts pv ON p.Id = pv.PostId
)
SELECT 
    ud.UserId,
    ud.Reputation,
    ud.ReputationCategory,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.VoteSentiment,
    COUNT(c.Id) AS CommentCount,
    STRING_AGG(DISTINCT REPLACE(c.Text, ' ', '_'), ', ') AS CommentsSnippet,
    NTILE(5) OVER (PARTITION BY ud.ReputationCategory ORDER BY pd.CreationDate DESC) AS RecentPostRank
FROM UserReputation ud
JOIN PostDetails pd ON ud.UserId = pd.OwnerUserId
LEFT JOIN Comments c ON pd.PostId = c.PostId
WHERE pd.VoteSentiment = 'Positive' 
    AND (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = pd.PostId 
           AND ph.PostHistoryTypeId IN (10, 11, 12) 
           AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') > 0  
GROUP BY 
    ud.UserId, 
    ud.Reputation, 
    ud.ReputationCategory, 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.VoteSentiment
HAVING COUNT(c.Id) >= 5  
ORDER BY 
    ud.Reputation DESC, 
    pd.CreationDate DESC;