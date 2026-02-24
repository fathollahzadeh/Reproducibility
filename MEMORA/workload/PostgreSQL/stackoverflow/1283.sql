
WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        CreationDate, 
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        CASE 
            WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive'
            ELSE 'Negative or Neutral'
        END AS PostSentiment
    FROM PostStats ps
    JOIN Users u ON ps.OwnerUserId = u.Id
)
SELECT 
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ur.ReputationCategory, 
    pd.PostId, 
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.PostSentiment,
    COALESCE(p.Title, 'No Title') AS PostTitle,
    COALESCE(ARRAY_AGG(DISTINCT t.TagName), '{}') AS Tags
FROM UserReputation ur
LEFT JOIN PostDetails pd ON ur.Id = pd.OwnerUserId
LEFT JOIN Posts p ON pd.PostId = p.Id
LEFT JOIN LATERAL (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName
) AS t ON true
GROUP BY 
    ur.DisplayName, 
    ur.Reputation, 
    ur.ReputationCategory, 
    pd.PostId, 
    pd.CommentCount, 
    pd.UpVoteCount, 
    pd.DownVoteCount, 
    pd.PostSentiment,
    p.Title 
ORDER BY ur.Reputation DESC, pd.UpVoteCount DESC;
