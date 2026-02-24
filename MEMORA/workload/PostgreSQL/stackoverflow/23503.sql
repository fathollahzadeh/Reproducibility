
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostsWithVotes AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        pd.AnswerStatus
    FROM PostDetails pd
    LEFT JOIN PostVoteCounts pvc ON pd.PostId = pvc.PostId
),
RankedPosts AS (
    SELECT 
        pwv.*,
        ROW_NUMBER() OVER (PARTITION BY pwv.AnswerStatus ORDER BY pwv.Score DESC, pwv.ViewCount DESC) AS Rank
    FROM PostsWithVotes pwv
)
SELECT 
    ur.DisplayName,
    ur.ReputationCategory,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.AnswerStatus,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5 Posts'
        ELSE 'Outside Top 5'
    END AS TopPostIndicator
FROM RankedPosts rp
JOIN UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE ur.Reputation IS NOT NULL
AND rp.AnswerStatus = 'Accepted'
ORDER BY ur.Reputation DESC, rp.Score DESC;
