WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(CAST(COALESCE(v.BountyAmount, 0) AS FLOAT)) AS AverageBounty
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), EnhancedPostStats AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Owner,
        r.CommentCount,
        r.VoteCount,
        r.UpVotes,
        r.DownVotes,
        r.AverageBounty,
        COALESCE((SELECT MAX(Score) FROM Posts p WHERE p.OwnerUserId = u.Id), 0) AS HighestScoreByOwner
    FROM 
        RecentPostStats r
    JOIN Users u ON r.Owner = u.DisplayName
)
SELECT 
    eps.PostId,
    eps.Title,
    eps.CreationDate,
    eps.Owner,
    eps.CommentCount,
    eps.VoteCount,
    eps.UpVotes,
    eps.DownVotes,
    eps.AverageBounty,
    eps.HighestScoreByOwner,
    CASE 
        WHEN eps.UpVotes > eps.DownVotes THEN 'Positive'
        WHEN eps.DownVotes > eps.UpVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    EnhancedPostStats eps
ORDER BY 
    eps.CreationDate DESC, eps.VoteCount DESC;