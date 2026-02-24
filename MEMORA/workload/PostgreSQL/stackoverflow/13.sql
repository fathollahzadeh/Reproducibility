WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = p.OwnerUserId) AS AvgOwnerPostScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    COALESCE(ur.UserRank, 0) AS OwnerRank,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.AvgOwnerPostScore,
    CASE 
        WHEN pa.UpVoteCount - pa.DownVoteCount > 0 THEN 'Positive'
        WHEN pa.UpVoteCount - pa.DownVoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostAnalytics pa
LEFT JOIN 
    UserReputation ur ON pa.OwnerUserId = ur.UserId
ORDER BY 
    pa.CreationDate DESC
LIMIT 100;