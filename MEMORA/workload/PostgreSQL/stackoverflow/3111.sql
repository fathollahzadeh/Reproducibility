WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM RankedPosts rp
    LEFT JOIN Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE rp.PostRank <= 10
),
PostDetails AS (
    SELECT 
        tp.*,
        CASE 
            WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
            WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        CASE 
            WHEN tp.CommentCount > 5 THEN 'Highly Discussed'
            WHEN tp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
            ELSE 'Not Discussed'
        END AS DiscussionLevel
    FROM TopPosts tp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.BadgeName,
    pd.VoteSentiment,
    pd.DiscussionLevel
FROM PostDetails pd
ORDER BY pd.CreationDate DESC
LIMIT 15;