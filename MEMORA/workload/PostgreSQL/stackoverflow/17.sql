WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS TotalComments
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1' year
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM PostDetail pd
    WHERE pd.ViewCount > 50
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes
FROM UserReputation ur
LEFT JOIN TopPosts tp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE ur.ReputationRank <= 10
ORDER BY ur.Reputation DESC, tp.Score DESC;