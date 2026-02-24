
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           p.AnswerCount, 
           p.CommentCount, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount 
    FROM RankedPosts
    WHERE Rank <= 5
),
UserEngagement AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT v.Id) AS VoteCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT tp.PostId, 
           tp.Title, 
           tp.Score, 
           tp.ViewCount, 
           tp.AnswerCount, 
           ue.UserId, 
           ue.DisplayName, 
           ue.VoteCount, 
           ue.UpVotes, 
           ue.DownVotes
    FROM TopPosts tp
    JOIN UserEngagement ue ON tp.PostId = ue.UserId
)
SELECT pd.Title, 
       pd.Score, 
       pd.ViewCount, 
       pd.AnswerCount, 
       pd.DisplayName AS EngagingUser, 
       pd.VoteCount, 
       pd.UpVotes, 
       pd.DownVotes
FROM PostDetails pd
ORDER BY pd.Score DESC, pd.ViewCount DESC;
